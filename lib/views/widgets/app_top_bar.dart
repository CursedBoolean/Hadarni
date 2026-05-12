import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Top bar with centered title, optional hamburger (drawer) on the left,
/// and profile avatar on the right.
/// Used on home, learn, and game screens.
class AppTopBar extends StatelessWidget {
  final String title;
  final String? avatarUrl;

  /// Set to true on main screens to show a drawer menu button.
  final bool showMenuButton;

  const AppTopBar({
    super.key,
    required this.title,
    this.avatarUrl,
    this.showMenuButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Centered title
            // Left side: hamburger menu (for RTL layouts this is the "end" side)
            if (showMenuButton)
              GestureDetector(
                onTap: () => Scaffold.of(context).openDrawer(),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.softBlue.withValues(alpha: 0.15),
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: AppColors.white,
                    size: 26,
                  ),
                ),
              ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
              textAlign: TextAlign.center,
            ),
            // Right side: avatar
            CircleAvatar(
              radius: 21,
              backgroundColor: AppColors.softBlue.withValues(alpha: 0.3),
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null
                  ? const Icon(Icons.person, color: AppColors.white, size: 24)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
