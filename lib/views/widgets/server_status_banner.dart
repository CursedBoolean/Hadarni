import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/whisper_server_manager.dart';

/// A slim banner shown at the top of exercise screens when the Whisper ASR
/// server is not reachable.
///
/// Automatically hides once [WhisperServerManager.isServerUp] becomes true.
/// Shows a retry button so the user can re-check without restarting the app.
class ServerStatusBanner extends StatelessWidget {
  const ServerStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WhisperServerManager>(
      builder: (context, manager, _) {
        if (manager.isServerUp) return const SizedBox.shrink();

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          color: Colors.orange.shade900.withValues(alpha: 0.95),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  manager.isChecking
                      ? 'جاري الاتصال بخادم التعرّف على الصوت…'
                      : 'خادم الصوت غير متاح — تأكد من تشغيل Whisper',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!manager.isChecking)
                TextButton(
                  onPressed: manager.retry,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(60, 28),
                  ),
                  child: const Text(
                    'إعادة المحاولة',
                    style: TextStyle(fontSize: 11),
                  ),
                )
              else
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
