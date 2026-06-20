import 'dart:async';
import 'package:flutter/material.dart';
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
import '../widgets/cloud_shape.dart';
import '../widgets/mic_button.dart';
import '../widgets/server_status_banner.dart';
import '../widgets/start_button.dart';

/// Learn letters exercise — displays a letter in a cloud, records speech via
/// mic, sends it to the Whisper ASR server, and shows pass / fail feedback.
class LearnLettersExerciseScreen extends StatefulWidget {
  /// Optional letter to start with. If null, defaults to 'أ'.
  final String? initialLetter;

  const LearnLettersExerciseScreen({super.key, this.initialLetter});

  @override
  State<LearnLettersExerciseScreen> createState() =>
      _LearnLettersExerciseScreenState();
}

class _LearnLettersExerciseScreenState extends State<LearnLettersExerciseScreen>
    with SingleTickerProviderStateMixin {
  late String currentLetter = widget.initialLetter ?? 'أ';

  bool isRecording = false;
  bool isProcessing = false;
  WhisperResult? lastResult;

  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioService _audioService = AudioService();
  final ElevenLabsTtsService _tts = ElevenLabsTtsService();
  late final AnimationController _feedbackCtrl;
  late final Animation<double> _feedbackAnim;

  @override
  void initState() {
    super.initState();
    _feedbackCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _feedbackAnim = CurvedAnimation(
      parent: _feedbackCtrl,
      curve: Curves.easeOutBack,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playPrompt();
    });
  }

  void _playPrompt() {
    _audioService.playAsset('audio/letters/$currentLetter.mp3');
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
        final path = '${directory.path}/recording_letters.wav';

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
    _audioService.playAsset('audio/feedback/drums.mp3');

    try {
      final result = await WhisperService.transcribe(
        audioPath: path,
        target: currentLetter,
      );
      if (!mounted) return;
      setState(() {
        lastResult = result;
        isProcessing = false;
      });
      _feedbackCtrl.forward(from: 0);

      // Record the attempt for streak tracking
      progressCtrl.recordLetterAttempt(currentLetter, result.isCorrect);

      // ── Send attempt to RAG feedback server & speak the response ─────────
      final streakData = progressCtrl.streakData;
      final letterStreak =
          streakData.letters[currentLetter]?.currentStreak ?? 0;
      final previousMistakes = result.isCorrect
          ? 0
          : (streakData.letters[currentLetter]?.bestStreak ?? 0);
      final childName = authCtrl.userProfile?.childName ?? 'الطفل';

      final response = await FeedbackService.sendFeedback(
        targetText: currentLetter,
        isCorrect: result.isCorrect,
        childName: childName,
        // Only send the first character of the transcription — Whisper may
        // return a full word when the child pronounces a single letter.
        spokenText: result.transcript.trim().isEmpty
            ? ''
            : result.transcript.trim().characters.first,
        streak: letterStreak,
        previousMistakes: previousMistakes,
      );

      if (!mounted) return;

      // Use the actual key the server returns: 'personalized_text'
      final feedbackText =
          response?['personalized_text'] as String? ??
          response?['feedback'] as String? ??
          response?['message'] as String?;

      if (result.isCorrect) {
        await _audioService.playAsset('audio/feedback/cheering.mp3', wait: true);
      } else {
        await _audioService.playAsset('audio/feedback/wrong.mp3', wait: true);
      }

      if (feedbackText != null && feedbackText.isNotEmpty) {
        debugPrint('[ElevenLabs] Speaking: $feedbackText');
        await _tts.speak(feedbackText);
      } else {
        debugPrint('[ElevenLabs] No feedback text received — skipping TTS.');
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const AppTopBar(title: 'تعلم الحروف'),
          // Server status warning banner (hidden when server is up)
          const ServerStatusBanner(),
          const Spacer(flex: 1),

          // Cloud with letter and speaker icon
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CloudShape(
                      width: 300,
                      height: 220,
                      child: Text(
                        currentLetter,
                        style: AppTextStyles.arabicLetter,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _playPrompt,
                      child: const Icon(
                        Icons.volume_up,
                        color: AppColors.warmOrange,
                        size: 36,
                      ),
                    ),
                  ],
                ),
                if (lastResult != null && !isProcessing)
                  ScaleTransition(
                    scale: _feedbackAnim,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        lastResult!.isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: lastResult!.isCorrect
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                        size: 130,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Spacer(flex: 1),

          // Decorative lines
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                _buildLine(),
                const SizedBox(height: 16),
                _buildLine(),
              ],
            ),
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

          const SizedBox(height: 24),

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

  Widget _buildLine() {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
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
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacity = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
              style: TextStyle(color: AppColors.deepNavy, fontSize: 15),
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
            color: (correct ? Colors.green : Colors.red).withValues(
              alpha: 0.25,
            ),
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
            'سمعنا: ${r.transcript.isEmpty ? '—' : r.transcript.characters.first}',
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
