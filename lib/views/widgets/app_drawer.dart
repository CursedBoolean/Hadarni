import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/progress_controller.dart';
import '../constants/app_colors.dart';
import '../home/home_screen.dart';
import '../learn_letters/learn_letters_intro_screen.dart';
import '../learn_words/learn_words_intro_screen.dart';
import '../word_game/word_game_intro_screen.dart';
import '../auth/welcome_screen.dart';

/// Side navigation drawer accessible from all main screens.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthController>(context);
    final userEmail = auth.user?.email ?? '';

    return Drawer(
      backgroundColor: AppColors.deepNavy,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.softBlue.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.softBlue.withValues(alpha: 0.2),
                      border: Border.all(
                        color: AppColors.softBlue.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'هدّرني',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail.isNotEmpty ? userEmail : 'تعلّم العربية بسهولة',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.white.withValues(alpha: 0.6),
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Nav items
            _DrawerItem(
              icon: Icons.home_rounded,
              label: 'الصفحة الرئيسية',
              onTap: () => _navigateTo(context, const HomeScreen()),
            ),
            _DrawerItem(
              icon: Icons.abc_rounded,
              label: 'تعلم الحروف',
              onTap: () =>
                  _navigateTo(context, const LearnLettersIntroScreen()),
            ),
            _DrawerItem(
              icon: Icons.menu_book_rounded,
              label: 'تعلم كلمات جديدة',
              onTap: () => _navigateTo(context, const LearnWordsIntroScreen()),
            ),
            _DrawerItem(
              icon: Icons.sports_esports_rounded,
              label: 'العب بالكلمات',
              onTap: () => _navigateTo(context, const WordGameIntroScreen()),
            ),
            const Spacer(),
            // Logout item
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                color: AppColors.softBlue.withValues(alpha: 0.2),
                height: 1,
              ),
            ),
            _DrawerItem(
              icon: Icons.logout_rounded,
              label: 'تسجيل الخروج',
              onTap: () => _handleLogout(context),
              isDestructive: true,
            ),
            // Bottom version
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                'الإصدار 1.0',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.white.withValues(alpha: 0.4),
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).pop(); // close drawer
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }

  void _handleLogout(BuildContext context) async {
    Navigator.of(context).pop(); // close drawer
    final auth = Provider.of<AuthController>(context, listen: false);
    await auth.logOut();
    if (context.mounted) {
      context.read<ProgressController>().reset();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: AppColors.softBlue.withValues(alpha: 0.15),
      highlightColor: AppColors.softBlue.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDestructive
                    ? Colors.red.withValues(alpha: 0.12)
                    : AppColors.softBlue.withValues(alpha: 0.12),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red.shade300 : AppColors.warmOrange,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDestructive ? Colors.red.shade300 : AppColors.white,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
      ),
    );
  }
}
