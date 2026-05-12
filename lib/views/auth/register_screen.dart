import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'additional_info_screen.dart';
import 'login_screen.dart';

/// Registration screen with email, password, and confirm password.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate fields
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError('يرجى ملء جميع الحقول.');
      return;
    }

    if (password != confirmPassword) {
      _showError('كلمتا المرور غير متطابقتين.');
      return;
    }

    if (password.length < 6) {
      _showError('كلمة المرور يجب أن تكون 6 أحرف على الأقل.');
      return;
    }

    final auth = Provider.of<AuthController>(context, listen: false);
    final success = await auth.signUp(email, password);

    if (!mounted) return;

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdditionalInfoScreen()),
      );
    } else if (auth.errorMessage != null) {
      _showError(auth.errorMessage!);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontSize: 14),
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: GradientBackground(
        child: Center(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  // Title
                  const Text(
                    'إنشاء حساب',
                    style: AppTextStyles.screenTitle,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 80),
                  // Email field
                  CustomTextField(
                    label: 'البريد الإلكتروني',
                    hint: 'البريد الإلكتروني',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  // Password field
                  CustomTextField(
                    label: 'كلمة المرور',
                    hint: 'كلمة المرور',
                    obscureText: true,
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 24),
                  // Confirm password field
                  CustomTextField(
                    label: 'تأكيد كلمة المرور',
                    hint: 'تأكيد كلمة المرور',
                    obscureText: true,
                    controller: _confirmPasswordController,
                  ),
                  const SizedBox(height: 48),
                  // Register button with loading state
                  Consumer<AuthController>(
                    builder: (context, auth, _) {
                      if (auth.isLoading) {
                        return const SizedBox(
                          width: 260,
                          height: 52,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                            ),
                          ),
                        );
                      }
                      return PrimaryButton(
                        text: 'سجل للمتابعة',
                        onPressed: _handleRegister,
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Login link
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      'تسجيل الدخول',
                      style: AppTextStyles.linkText.copyWith(
                        color: AppColors.white.withValues(alpha: 0.85),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
