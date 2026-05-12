import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import '../widgets/outline_button.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

/// Login screen with email and password fields.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('يرجى ملء جميع الحقول.');
      return;
    }

    final auth = Provider.of<AuthController>(context, listen: false);
    final success = await auth.logIn(email, password);

    if (!mounted) return;

    if (success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
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
                    'تسجيل الدخول',
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
                  const SizedBox(height: 12),
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navigate to forgot password
                      },
                      child: const Text(
                        'نسيت كلمة السر ؟',
                        style: AppTextStyles.linkText,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Login button with loading state
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
                        text: 'تسجيل الدخول',
                        onPressed: _handleLogin,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Register button
                  OutlineAppButton(
                    text: 'إنشاء حساب',
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
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
