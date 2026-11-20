import 'package:flutter/material.dart';
import 'app_lang.dart';
import 'app_navigation.dart';
import 'auth_service.dart';
import 'login_screen.dart';

const Color _navy = Color(0xFF0F2942);
const Color _background = Color(0xFFF0F4F8);
const Color _lightBlue = Color(0xFFEBF1F6);
const Color _secondaryText = Color(0xFF475569);

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool loading = false;

  String t(String ar, String en) => translate(ar, en);

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: _secondaryText),
      suffixIcon: suffix,
      filled: true,
      fillColor: _lightBlue,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _navy),
      ),
    );
  }

  Widget buildField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool password = false,
    bool confirmPassword = false,
  }) {
    final isPassword = password || confirmPassword;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: password
              ? obscurePassword
              : confirmPassword
                  ? obscureConfirmPassword
                  : false,
          textDirection: isPassword
              ? TextDirection.ltr
              : (isArabic ? TextDirection.rtl : TextDirection.ltr),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return t('هذا الحقل مطلوب', 'This field is required');
            }

            if (controller == emailController &&
                !value.contains('@')) {
              return t(
                'أدخل بريد إلكتروني صحيح',
                'Enter a valid email address',
              );
            }

            if (password && value.length < 6) {
              return t(
                'كلمة السر يجب ألا تقل عن 6 أحرف',
                'Password must be at least 6 characters',
              );
            }

            if (confirmPassword &&
                value != passwordController.text) {
              return t(
                'كلمتا المرور غير متطابقتين',
                'Passwords do not match',
              );
            }

            return null;
          },
          decoration: fieldDecoration(
            hint: hint,
            icon: icon,
            suffix: password || confirmPassword
                ? IconButton(
                    onPressed: () {
                      setState(() {
                        if (password) {
                          obscurePassword = !obscurePassword;
                        } else {
                          obscureConfirmPassword =
                              !obscureConfirmPassword;
                        }
                      });
                    },
                    icon: Icon(
                      (password
                              ? obscurePassword
                              : obscureConfirmPassword)
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: _secondaryText,
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      await AuthService.signUpCitizen(
        name: nameController.text,
        email: emailController.text,
        phone: phoneController.text,
        password: passwordController.text,
      );

      if (!mounted) return;

      showMessage(t('تم إنشاء حسابك بنجاح', 'Your account was created'));

      // Firebase بيسجّل دخول المواطن تلقائي بعد إنشاء الحساب
      openHomeForRole(context, UserRole.citizen);
    } on AuthException catch (e) {
      if (!mounted) return;
      showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      showMessage(t('حصلت مشكلة. جرّب تاني', 'Something went wrong. Try again'));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, lang, _) {
        final isAr = lang == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: _background,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: toggleAppLanguage,
                          icon: const Icon(Icons.language, size: 19),
                          label: Text(isAr ? 'EN' : 'العربية'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _navy,
                            side: const BorderSide(color: _navy),
                            shape: const StadiumBorder(),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            isAr
                                ? Icons.arrow_forward
                                : Icons.arrow_back,
                            color: _navy,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE0EAF4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_outlined,
                          size: 40,
                          color: _navy,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        t('إنشاء حساب جديد', 'Create Account'),
                        style: const TextStyle(
                          fontSize: 29,
                          fontWeight: FontWeight.bold,
                          color: _navy,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Center(
                      child: Text(
                        t(
                          'أنشئ حسابك للاستفادة من خدمات مدينتي',
                          'Create your account to access Madinty services',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _secondaryText,
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: _navy.withValues(alpha: 0.07),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildField(
                              label: t('الاسم بالكامل', 'Full Name'),
                              hint: t(
                                'أدخل اسمك بالكامل',
                                'Enter your full name',
                              ),
                              icon: Icons.person_outline,
                              controller: nameController,
                            ),

                            const SizedBox(height: 20),

                            buildField(
                              label: t('البريد الإلكتروني', 'Email Address'),
                              hint: 'example@email.com',
                              icon: Icons.email_outlined,
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                            ),

                            const SizedBox(height: 20),

                            buildField(
                              label: t('رقم الهاتف', 'Phone Number'),
                              hint: '01xxxxxxxxx',
                              icon: Icons.phone_outlined,
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                            ),

                            const SizedBox(height: 20),

                            buildField(
                              label: t('كلمة المرور', 'Password'),
                              hint: t(
                                'أدخل كلمة المرور',
                                'Enter your password',
                              ),
                              icon: Icons.lock_outline,
                              controller: passwordController,
                              password: true,
                            ),

                            const SizedBox(height: 20),

                            buildField(
                              label: t(
                                'تأكيد كلمة المرور',
                                'Confirm Password',
                              ),
                              hint: t(
                                'أعد إدخال كلمة المرور',
                                'Re-enter your password',
                              ),
                              icon: Icons.lock_outline,
                              controller: confirmPasswordController,
                              confirmPassword: true,
                            ),

                            const SizedBox(height: 28),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: loading ? null : createAccount,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _navy,
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  t('إنشاء الحساب', 'Create Account'),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            t(
                              'لديك حساب بالفعل؟ ',
                              'Already have an account? ',
                            ),
                            style: const TextStyle(
                              color: _secondaryText,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(role: UserRole.citizen),
                                ),
                              );
                            },
                            child: Text(
                              t('تسجيل الدخول', 'Log In'),
                              style: const TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}