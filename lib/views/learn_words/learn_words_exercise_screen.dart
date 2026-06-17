import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/progress_controller.dart';
import '../../services/audio_service.dart';
import '../../services/elevenlabs_tts_service.dart';
import '../../services/feedback_service.dart';
import '../../services/whisper_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/mic_button.dart';
import '../widgets/server_status_banner.dart';
import '../widgets/start_button.dart';

/// Learn words exercise — shows an image circle + word label, records speech
/// via mic, sends it to the Whisper ASR server, and shows pass / fail feedback.
class LearnWordsExerciseScreen extends StatefulWidget {
  /// Optional word to start with. If null, defaults to 'كاس'.
  final String? initialWord;

  const LearnWordsExerciseScreen({super.key, this.initialWord});

  @override
  State<LearnWordsExerciseScreen> createState() =>
      _LearnWordsExerciseScreenState();
}

class _LearnWordsExerciseScreenState extends State<LearnWordsExerciseScreen>
    with SingleTickerProviderStateMixin {
  late String currentWord;

  // Image URL loaded from objects.json for the current word
  String? _imageUrl;
  bool _imageLoaded = false;

  bool isRecording = false;
  bool isProcessing = false;
  WhisperResult? lastResult;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioService _audioService = AudioService();
  final ElevenLabsTtsService _tts = ElevenLabsTtsService();
  late final AnimationController _feedbackCtrl;
  late final Animation<double> _feedbackAnim;

  // Set of words that have local mp3 files in assets/audio/words
  static const Set<String> _localAudioWords = {
    'باب',
    'بيت',
    'شمس',
    'قلم',
    'قمر',
    'كأس',
    'كتاب',
    'ماء',
  };

  @override
  void initState() {
    super.initState();
    currentWord = widget.initialWord ?? '';
    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _feedbackAnim = CurvedAnimation(
      parent: _feedbackCtrl,
      curve: Curves.easeOutBack,
    );

    _initExercise();
  }

  Future<void> _initExercise() async {
    await _loadObjectImage();
    _playPrompt();
  }

  /// Loads objects.json and finds the image URL matching [currentWord].
  Future<void> _loadObjectImage() async {
    try {
      final String jsonString =
          await rootBundle.loadString('lib/models/objects.json');
      final List<dynamic> objects = json.decode(jsonString);

      if (currentWord.isEmpty && objects.isNotEmpty) {
        if (mounted) {
          setState(() {
            currentWord = objects[0]['arabic'] as String? ?? 'قَلَم';
          });
        }
      }

      // Normalise comparison: strip diacritics for matching
      final String normalised = _stripDiacritics(currentWord);

      for (final obj in objects) {
        final String arabic = obj['arabic'] as String? ?? '';
        if (_stripDiacritics(arabic) == normalised || arabic == currentWord) {
          final String pic = obj['picture'] as String? ?? '';
          if (mounted) {
            setState(() {
              _imageUrl = pic.isNotEmpty ? pic : null;
              _imageLoaded = true;
            });
          }
          return;
        }
      }
      // No match found
      if (mounted) setState(() => _imageLoaded = true);
    } catch (e) {
      debugPrint('Error loading object image: $e');
      if (mounted) setState(() => _imageLoaded = true);
    }
  }

  /// Strips Arabic diacritics (harakat) for fuzzy matching.
  String _stripDiacritics(String text) {
    return text.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');
  }

  void _playPrompt() {
    if (currentWord.isEmpty) return;
    final normalised = _stripDiacritics(currentWord);
    if (_localAudioWords.contains(normalised)) {
      _audioService.playAsset('audio/words/$normalised.mp3');
    } else {
      debugPrint('[ElevenLabs] Speaking word prompt: $currentWord');
      _tts.speak(currentWord);
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioService.dispose();
    _tts.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleMicPress() async {
    if (isRecording || isProcessing) return;

    try {
      await _audioService.stop(); // Stop any prompt before recording

      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/recording_words.wav';

        setState(() {
          isRecording = true;
          lastResult = null;
        });
        _feedbackCtrl.reverse();

        // Record as 16 kHz mono WAV — exactly what Whisper expects
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: path,
        );

        // Auto-stop after 2 seconds
        Future.delayed(const Duration(seconds: 2), () async {
          if (isRecording && mounted) {
            await _stopAndTranscribe(path);
          }
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      setState(() => isRecording = false);
    }
  }

  Future<void> _stopAndTranscribe(String path) async {
    await _audioRecorder.stop();
    if (!mounted) return;

    // ── Capture context-dependent values before any await ─────────────────
    // Reading from context across async gaps triggers use_build_context_synchronously.
    final progressCtrl = context.read<ProgressController>();
    final authCtrl = context.read<AuthController>();

    setState(() {
      isRecording = false;
      isProcessing = true;
    });

    try {
      final result = await WhisperService.transcribe(
        audioPath: path,
        target: currentWord,
      );
      if (!mounted) return;
      setState(() {
        lastResult = result;
        isProcessing = false;
      });
      _feedbackCtrl.forward(from: 0);

      // Record the attempt for streak tracking
      progressCtrl.recordWordAttempt(currentWord, result.isCorrect);

      // ── Send attempt to RAG feedback server & speak the response ─────────
      final streakData = progressCtrl.streakData;
      final wordStreak = streakData.words[currentWord]?.currentStreak ?? 0;
      final previousMistakes = result.isCorrect
          ? 0
          : (streakData.words[currentWord]?.bestStreak ?? 0);
      final childName = authCtrl.userProfile?.childName ?? 'الطفل';

      final response = await FeedbackService.sendFeedback(
        targetText: currentWord,
        isCorrect: result.isCorrect,
        childName: childName,
        spokenText: result.transcript,
        streak: wordStreak,
        previousMistakes: previousMistakes,
      );

      if (!mounted) return;

      // Use the actual key the server returns: 'personalized_text'
      final feedbackText =
          response?['personalized_text'] as String? ??
          response?['feedback'] as String? ??
          response?['message'] as String?;

      // Always speak feedback — use RAG response when available, fallback otherwise
      final toSpeak = (feedbackText != null && feedbackText.isNotEmpty)
          ? feedbackText
          : (result.isCorrect ? 'ممتاز! أحسنت' : 'حاول مرة أخرى');

      debugPrint('[ElevenLabs] Speaking: $toSpeak');
      await _tts.speak(toSpeak);
    } catch (e) {
      debugPrint('Transcription error: $e');
      if (!mounted) return;
      setState(() => isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذّر الاتصال بالخادم: $e'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handlePlayAudio() {
    _playPrompt();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const AppTopBar(title: 'تعلم كلمات جديدة'),
          // Server status warning banner (hidden when server is up)
          const ServerStatusBanner(),
          const Spacer(flex: 1),

          // Image circle — loads the real image from objects.json
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.warmOrange, width: 5),
                color: AppColors.white,
              ),
              child: ClipOval(
                child: _buildObjectImage(),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Word label + speaker icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _handlePlayAudio,
                child: const Icon(
                  Icons.volume_up,
                  color: AppColors.warmOrange,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                currentWord,
                style: AppTextStyles.wordLabel,
                textDirection: TextDirection.rtl,
              ),
            ],
          ),

          const Spacer(flex: 2),

          // Feedback card (animates in after transcription)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: (lastResult != null || isProcessing)
                ? ScaleTransition(
                    scale: isProcessing
                        ? const AlwaysStoppedAnimation(1.0)
                        : _feedbackAnim,
                    child: _FeedbackCard(
                      result: lastResult,
                      isProcessing: isProcessing,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          const SizedBox(height: 20),

          // Mic button with pulsing ring while recording
          Center(
            child: _RecordingRing(
              isRecording: isRecording,
              child: MicButton(
                onPressed: _handleMicPress,
                size: 100,
                isRecording: isRecording,
              ),
            ),
          ),

          const SizedBox(height: 48),

          Center(
            child: StartButton(
              text: 'إنهاء',
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Builds the image widget for the object circle.
  Widget _buildObjectImage() {
    if (!_imageLoaded) {
      // Still loading — show a subtle spinner
      return const Center(
        child: CircularProgressIndicator(color: AppColors.softBlue),
      );
    }

    if (_imageUrl == null || _imageUrl!.isEmpty) {
      // No image available — placeholder icon
      return const Center(
        child: Icon(
          Icons.image_outlined,
          size: 80,
          color: AppColors.softBlue,
        ),
      );
    }

    return Image.network(
      _imageUrl!,
      fit: BoxFit.cover,
      width: 240,
      height: 240,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            color: AppColors.softBlue,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 60,
            color: AppColors.softBlue,
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets (identical to those in learn_letters_exercise_screen)
// ─────────────────────────────────────────────────────────────────────────────

/// Animated pulsing ring that appears around the mic button while recording.
class _RecordingRing extends StatefulWidget {
  final bool isRecording;
  final Widget child;

  const _RecordingRing({required this.isRecording, required this.child});

  @override
  State<_RecordingRing> createState() => _RecordingRingState();
}

class _RecordingRingState extends State<_RecordingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _opacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isRecording) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: _scale.value,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withValues(alpha: _opacity.value),
              ),
            ),
          ),
          child!,
        ],
      ),
      child: widget.child,
    );
  }
}

/// Result card shown below the mic button.
class _FeedbackCard extends StatelessWidget {
  final WhisperResult? result;
  final bool isProcessing;

  const _FeedbackCard({required this.result, required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.lightLavender,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.warmOrange,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'جاري التحليل…',
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final r = result!;
    final correct = r.isCorrect;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: correct
            ? Colors.green.shade900.withValues(alpha: 0.9)
            : Colors.red.shade900.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: correct ? Colors.green.shade400 : Colors.red.shade400,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (correct ? Colors.green : Colors.red).withValues(alpha: 0.25),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                correct ? 'ممتاز! 🎉' : 'حاول مرة أخرى',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'سمعنا: ${r.transcript.isEmpty ? '—' : r.transcript}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }
}
