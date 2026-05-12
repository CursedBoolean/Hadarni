import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Circular microphone button.
class MicButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final double size;
  final bool isRecording;

  const MicButton({
    super.key,
    this.onPressed,
    this.size = 90,
    this.isRecording = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isRecording ? Colors.white : AppColors.warmOrange;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 3),
          color: Colors.transparent,
        ),
        child: Icon(
          Icons.mic,
          color: color,
          size: size * 0.45,
        ),
      ),
    );
  }
}
