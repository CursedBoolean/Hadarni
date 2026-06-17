import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../services/audio_service.dart';
import '../../services/elevenlabs_tts_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/start_button.dart';

/// Word game screen — 3x3 grid of image cards with word label.
class WordGameScreen extends StatefulWidget {
  const WordGameScreen({super.key});

  @override
  State<WordGameScreen> createState() => _WordGameScreenState();
}

class _WordGameScreenState extends State<WordGameScreen> {
  List<Map<String, dynamic>> allObjects = [];
  List<Map<String, dynamic>> currentOptions = [];
  Map<String, dynamic>? targetObject;

  bool isLoading = true;
  int? selectedIndex;
  bool isAnswerCorrect = false;

  final AudioService _audioService = AudioService();
  final ElevenLabsTtsService _tts = ElevenLabsTtsService();

  // Words that have bundled local mp3s in assets/audio/words/
  static const Set<String> _localAudioWords = {
    'باب', 'بيت', 'شمس', 'قلم', 'قمر', 'كأس', 'كتاب', 'ماء',
  };

  /// Strips Arabic diacritics for audio filename matching.
  String _stripDiacritics(String text) =>
      text.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '');

  /// Speaks the target word via local asset or ElevenLabs.
  void _playWordPrompt() {
    if (targetObject == null) return;
    final word = targetObject!['arabic'] as String? ?? '';
    if (word.isEmpty) return;
    final normalised = _stripDiacritics(word);
    if (_localAudioWords.contains(normalised)) {
      _audioService.playAsset('audio/words/$normalised.mp3');
    } else {
      _tts.speak(word);
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    _tts.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final String jsonString = await rootBundle.loadString('lib/models/objects.json');
      final List<dynamic> jsonResponse = json.decode(jsonString);
      
      allObjects = jsonResponse
          .map((item) => item as Map<String, dynamic>)
          .where((item) => (item['picture'] as String).isNotEmpty)
          .toList();
          
      _startNewRound();
    } catch (e) {
      debugPrint('Error loading objects: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _startNewRound() {
    if (allObjects.isEmpty) return;

    final random = Random();
    
    // Pick a random target
    targetObject = allObjects[random.nextInt(allObjects.length)];
    
    // Pick 8 distractors
    final distractors = allObjects.where((item) => item['arabic'] != targetObject!['arabic']).toList();
    distractors.shuffle();
    final selectedDistractors = distractors.take(8).toList();
    
    // Combine and shuffle
    currentOptions = [targetObject!, ...selectedDistractors];
    currentOptions.shuffle();
    
    if (mounted) {
      setState(() {
        selectedIndex = null;
        isAnswerCorrect = false;
        isLoading = false;
      });
    }
    // Speak the new target word after the frame settles
    WidgetsBinding.instance.addPostFrameCallback((_) => _playWordPrompt());
  }

  void _onCardTap(int index) {
    if (isAnswerCorrect || selectedIndex != null) return; // Prevent clicking after guessing or while delaying
    
    setState(() {
      selectedIndex = index;
    });

    final selectedObject = currentOptions[index];
    if (selectedObject['arabic'] == targetObject!['arabic']) {
      // Correct Answer
      setState(() {
        isAnswerCorrect = true;
      });
      
      // Delay and start next round
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _startNewRound();
        }
      });
    } else {
      // Incorrect Answer - reset after a short delay to let them try again
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted && !isAnswerCorrect) {
          setState(() {
            selectedIndex = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const AppTopBar(title: 'العب بالكلمات'),
          const SizedBox(height: 16),
          // 3x3 Grid
          Expanded(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.warmOrange))
              : currentOptions.isEmpty
                  ? const Center(child: Text("Error loading data", style: TextStyle(color: Colors.white)))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          final isSelected = selectedIndex == index;
                          final object = currentOptions[index];
                          
                          Color borderColor = AppColors.softBlue.withValues(alpha: 0.4);
                          double borderWidth = 1.5;
                          
                          if (isSelected) {
                            borderWidth = 3;
                            if (isAnswerCorrect) {
                              borderColor = Colors.green; // Correct
                            } else {
                              borderColor = Colors.red; // Incorrect
                            }
                          } else if (isAnswerCorrect && object['arabic'] == targetObject!['arabic']) {
                            // Highlight the correct answer if they got it right
                            borderColor = Colors.green;
                            borderWidth = 3;
                          }

                          return GestureDetector(
                            onTap: () => _onCardTap(index),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.lightLavender,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: borderColor,
                                  width: borderWidth,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  object['picture'],
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.softBlue,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 40,
                                        color: AppColors.softBlue,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
          ),
          // Word label — centered
          if (!isLoading && targetObject != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _playWordPrompt,
                    child: const Icon(
                      Icons.volume_up,
                      color: AppColors.warmOrange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    targetObject!['arabic'],
                    style: AppTextStyles.wordLabel.copyWith(
                      color: AppColors.warmOrange,
                      fontSize: 32,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          // Finish button — centered
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
}
