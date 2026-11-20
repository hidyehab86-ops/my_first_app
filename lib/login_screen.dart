import 'package:flutter/material.dart';

import 'app_lang.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'app_navigation.dart';
import 'auth_service.dart';

const Color navy = Color(0xFF0F2942);
const Color background = Color(0xFFF0F4F8);
const Color lightBlue = Color(0xFFEBF1F6);
const Color secondaryText = Color(0xFF475569);

String _loginText(bool isAr, String ar, String en) =>
    isAr ? ar : en;

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.role = UserRole.citizen,
  });

  // نوع المستخدم اللي اختاره في صفحة الاختيار
  final UserRole role;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  final FocusNode passwordFocusNode = FocusNode();

  bool obscurePassword = true;
  bool rememberMe = false;
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> submit(bool isAr) async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      showMessage(
        _loginText(
          isAr,
          'من فضلك أدخل بيانات تسجيل الدخول',
          'Please enter your login details',
        ),
      );
      return;
    }

    if (!email.contains('@')) {
      showMessage(
        _loginText(
          isAr,
          'أدخل البريد الإلكتروني (الدخول بالموبايل غير متاح حالياً)',
          'Enter your email (mobile login is not available yet)',
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await AuthService.signIn(
        email: email,
        password: password,
        expectedRole: widget.role,
      );

      if (!mounted) return;
      openHomeForRole(context, widget.role);
    } on AuthException catch (e) {
      if (!mounted) return;
      showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      showMessage(
        _loginText(isAr, 'حصلت مشكلة. جرّب تاني', 'Something went wrong. Try again'),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void toggleLanguage() {
    toggleAppLanguage();
  }

  // نص الشارة حسب الدور اللي اتختار
  String roleBadge(bool isAr) {
    switch (widget.role) {
      case UserRole.citizen:
        return _loginText(isAr, 'الدخول كمواطن', 'Citizen Login');
      case UserRole.employee:
        return _loginText(isAr, 'الدخول كموظف', 'Employee Login');
      case UserRole.admin:
        return _loginText(isAr, 'الدخول كأدمن', 'Admin Login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, lang, _) {
        final bool isAr = lang == 'ar';

        return Directionality(
          textDirection:
              isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: background,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Navigation
                    Row(
                      textDirection: TextDirection.ltr,
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: toggleLanguage,
                          icon: const Icon(
                            Icons.language,
                            size: 19,
                          ),
                          label: Text(isAr ? 'EN' : 'العربية'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: navy,
                            side: const BorderSide(color: navy),
                            shape: const StadiumBorder(),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            isAr
                                ? Icons.arrow_forward
                                : Icons.arrow_back,
                            color: navy,
                            size: 27,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: lightBlue,
                            minimumSize: const Size(48, 48),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 38),

                    // Role Badge
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0EAF4),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person,
                              color: navy,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              roleBadge(isAr),
                              style: const TextStyle(
                                color: navy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      _loginText(
                        isAr,
                        'تسجيل الدخول',
                        'Log In',
                      ),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _loginText(
                        isAr,
                        'أدخل بيانات حسابك للوصول إلى الخدمات البلدية الذكية ومتابعة بلاغاتك ومعاملاتك بكل يسر.',
                        'Enter your account details to access smart municipal services and easily track your reports and transactions.',
                      ),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.8,
                        color: secondaryText,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Login Form Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: navy.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          // Email
                          Text(
                            _loginText(
                              isAr,
                              'البريد الإلكتروني',
                              'Email address',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),

                          const SizedBox(height: 10),

                          TextField(
                            controller: emailController,
                            keyboardType:
                                TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            decoration: InputDecoration(
                              hintText: _loginText(
                                isAr,
                                'مثال: user@domain.com',
                                'e.g. user@domain.com',
                              ),
                              hintStyle: const TextStyle(
                                fontSize: 14,
                                color: secondaryText,
                              ),
                              prefixIcon: const Icon(
                                Icons.badge_outlined,
                                color: secondaryText,
                              ),
                              filled: true,
                              fillColor: lightBlue,
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                vertical: 17,
                                horizontal: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Password Label
                          Text(
                            _loginText(
                              isAr,
                              'كلمة السر',
                              'Password',
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Password Field - Fixed
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: TextField(
                              key: const ValueKey(
                                'login_password_field',
                              ),
                              controller: passwordController,
                              focusNode: passwordFocusNode,
                              enabled: true,
                              readOnly: false,
                              obscureText: obscurePassword,
                              keyboardType: TextInputType.text,
                              textInputAction:
                                  TextInputAction.done,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.left,
                              autocorrect: false,
                              enableSuggestions: false,
                              onTap: () {
                                if (!passwordFocusNode.hasFocus) {
                                  passwordFocusNode.requestFocus();
                                }
                              },
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                filled: true,
                                fillColor: lightBlue,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                  vertical: 17,
                                  horizontal: 12,
                                ),
                                prefixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword =
                                          !obscurePassword;
                                    });

                                    passwordFocusNode
                                        .requestFocus();
                                  },
                                  icon: Icon(
                                    obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: secondaryText,
                                  ),
                                ),
                                suffixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: secondaryText,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: navy,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Remember Me & Forgot Password
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: rememberMe,
                                      activeColor: navy,
                                      onChanged: (value) {
                                        setState(() {
                                          rememberMe =
                                              value ?? false;
                                        });
                                      },
                                    ),
                                    Flexible(
                                      child: Text(
                                        _loginText(
                                          isAr,
                                          'تذكرني',
                                          'Remember me',
                                        ),
                                        style: const TextStyle(
                                          color: secondaryText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  _loginText(
                                    isAr,
                                    'نسيت كلمة السر؟',
                                    'Forgot password?',
                                  ),
                                  style: const TextStyle(
                                    color: navy,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 64,
                            child: ElevatedButton(
                              onPressed: loading ? null : () => submit(isAr),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: navy,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                              child: loading
                                  ? const SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _loginText(
                                      isAr,
                                      'دخول',
                                      'Log In',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    isAr
                                        ? Icons.arrow_back
                                        : Icons.arrow_forward,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Create Account (للمواطن فقط)
                    if (widget.role == UserRole.citizen) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          Text(
                            _loginText(
                              isAr,
                              'ليس لديك حساب بعد؟ ',
                              "Don't have an account yet? ",
                            ),
                            style: const TextStyle(
                              color: secondaryText,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SignUpScreen(),
                                ),
                              );
                            },
                            child: Text(
                              _loginText(
                                isAr,
                                'إنشاء حساب جديد',
                                'Create an account',
                              ),
                              style: const TextStyle(
                                color: navy,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ],

                    const SizedBox(height: 28),

                    // Divider
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                          ),
                          child: Text(
                            _loginText(
                              isAr,
                              'أو عبر النفاذ الموحد',
                              'Or use unified access',
                            ),
                            style: const TextStyle(
                              color: secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Nafath Button
                    SizedBox(
                      width: double.infinity,
                      height: 65,
                      child: ElevatedButton(
                        onPressed: () {
                          showMessage(
                            _loginText(
                              isAr,
                              'سيتم ربط النفاذ الوطني لاحقاً',
                              'National access will be connected later',
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: navy,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.fingerprint,
                              size: 27,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                _loginText(
                                  isAr,
                                  'الدخول بواسطة النفاذ الوطني',
                                  'Log in with National Access',
                                ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 45),

                    // Security Footer
                    Center(
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.verified_user,
                            color: navy,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _loginText(
                                isAr,
                                'بياناتك محمية وفق المعايير البلدية الآمنة',
                                'Your data is protected according to secure municipal standards',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: secondaryText,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),
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