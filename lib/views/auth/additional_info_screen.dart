import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user_model.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/gradient_background.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_dropdown_field.dart';
import '../home/home_screen.dart';

/// Additional info screen for child profile (name, birthday, speech disorder).
class AdditionalInfoScreen extends StatefulWidget {
  const AdditionalInfoScreen({super.key});

  @override
  State<AdditionalInfoScreen> createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> {
  final _childNameController = TextEditingController();
  final _birthdayController = TextEditingController();
  String? _disorderType1;
  String? _disorderType2;

  // Placeholder items — to be replaced with backend data
  final List<String> _disorderOptions = [
    'تأخر النطق',
    'التأتأة',
    'اضطراب النطق الصوتي',
    'عسر الكلام',
  ];

  @override
  void dispose() {
    _childNameController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2018),
      firstDate: DateTime(2010),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _handleSubmit() async {
    final childName = _childNameController.text.trim();
    final birthday = _birthdayController.text.trim();

    if (childName.isEmpty || birthday.isEmpty) {
      _showError('يرجى ملء اسم الطفل وتاريخ الميلاد.');
      return;
    }

    final auth = Provider.of<AuthController>(context, listen: false);
    final currentUser = auth.user;

    if (currentUser == null) {
      _showError('حدث خطأ. يرجى تسجيل الدخول مرة أخرى.');
      return;
    }

    final profile = UserModel(
      uid: currentUser.uid,
      email: currentUser.email ?? '',
      childName: childName,
      birthday: birthday,
      disorderType1: _disorderType1,
      disorderType2: _disorderType2,
      createdAt: DateTime.now(),
    );

    final success = await auth.saveUserProfile(profile);

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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const SizedBox(height: 48),
                // Title
                const Text(
                  'معلومات إضافية',
                  style: AppTextStyles.screenTitle,
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 60),
                // Child name
                CustomTextField(
                  label: 'اسم الطفل',
                  hint: 'اسم الطفل',
                  controller: _childNameController,
                ),
                const SizedBox(height: 24),
                // Birthday
                CustomTextField(
                  label: 'تاريخ الميلاد',
                  hint: 'اختر تاريخ الميلاد',
                  controller: _birthdayController,
                  readOnly: true,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 24),
                // Disorder type 1
                CustomDropdownField(
                  label: 'نوع اضطراب النطق',
                  hint: 'نوع اضطراب النطق',
                  value: _disorderType1,
                  items: _disorderOptions,
                  onChanged: (val) => setState(() => _disorderType1 = val),
                ),
                const SizedBox(height: 24),
                // Submit button with loading state
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
                    return SizedBox(
                      width: 260,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepNavy.withValues(
                            alpha: 0.6,
                          ),
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chevron_right, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'تسجيل الدخول',
                              style: AppTextStyles.buttonText,
                            ),
                          ],
                        ),
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
    );
  }
}
