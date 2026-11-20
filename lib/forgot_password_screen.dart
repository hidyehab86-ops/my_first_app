import 'package:flutter/material.dart';
import 'app_lang.dart';
import 'auth_service.dart';

// ---------- Colors ----------
const Color forgotBackground = Color(0xFFF0F4F8);
const Color forgotNavy = Color(0xFF0F2942);
const Color forgotPrimary = Color(0xFF001428);
const Color forgotSecondary = Color(0xFF475569);
const Color forgotLight = Color(0xFFEBF1F6);
const Color forgotTint = Color(0xFFE0EAF4);

String _tr(bool isAr, String ar, String en) => isAr ? ar : en;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController identityController = TextEditingController();
  bool showSuccess = false;

  @override
  void dispose() {
    identityController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> sendRecoveryCode(bool isAr) async {
    final identity = identityController.text.trim();

    if (identity.isEmpty) {
      _showSnack(_tr(
        isAr,
        'من فضلك أدخل البريد الإلكتروني',
        'Please enter your email address.',
      ));
      return;
    }

    if (!identity.contains('@')) {
      _showSnack(_tr(
        isAr,
        'أدخل بريداً إلكترونياً صحيحاً (الاستعادة بالموبايل غير متاحة حالياً)',
        'Enter a valid email address (mobile recovery is not available yet).',
      ));
      return;
    }

    try {
      await AuthService.sendPasswordReset(identity);
      if (!mounted) return;
      setState(() => showSuccess = true);
    } on AuthException catch (e) {
      if (!mounted) return;
      _showSnack(e.message);
    } catch (_) {
      if (!mounted) return;
      _showSnack(_tr(isAr, 'حصلت مشكلة. جرّب تاني', 'Something went wrong. Try again'));
    }
  }

  void toggleLanguage(String currentLang) {
    toggleAppLanguage();
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
            backgroundColor: forgotBackground,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    // Top Navigation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 1,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              isAr ? Icons.arrow_forward : Icons.arrow_back,
                              color: forgotNavy,
                              size: 23,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => toggleLanguage(lang),
                          icon: const Icon(Icons.language, size: 18),
                          label: Text(isAr ? 'English' : 'العربية'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: forgotNavy,
                            side: BorderSide.none,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Recovery Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: forgotTint,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 19,
                            color: forgotNavy,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _tr(isAr, 'استعادة الحساب', 'Account Recovery'),
                            style: const TextStyle(
                              color: forgotNavy,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Recovery Icon
                    SizedBox(
                      width: 112,
                      height: 112,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 112,
                            height: 112,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEAF0F6),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: forgotTint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lock_reset,
                              color: forgotNavy,
                              size: 38,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 2,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFF193B5C),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.key,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Title
                    Text(
                      _tr(isAr, 'نسيت كلمة السر', 'Forgot Password'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: forgotNavy,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    Text(
                      _tr(
                        isAr,
                        'اكتب بريدك الإلكتروني وهنبعتلك رابط آمن لاستعادة كلمة السر',
                        'Enter your email and we will send you a secure link to reset your password.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.7,
                        color: forgotSecondary,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Form Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x18000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _tr(
                                    isAr,
                                    'البريد الإلكتروني',
                                    'Email address',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                '*',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Input
                          TextField(
                            controller: identityController,
                            textDirection:
                                isAr ? TextDirection.rtl : TextDirection.ltr,
                            textAlign: isAr ? TextAlign.right : TextAlign.left,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) {
                              if (showSuccess) {
                                setState(() => showSuccess = false);
                              }
                            },
                            decoration: InputDecoration(
                              hintText: _tr(
                                isAr,
                                'مثال: name@email.com',
                                'e.g. name@email.com',
                              ),
                              hintStyle: const TextStyle(
                                color: Color(0xFF858B93),
                                fontSize: 14,
                              ),
                              prefixIcon: IconButton(
                                onPressed: () {
                                  identityController.clear();
                                  setState(() => showSuccess = false);
                                },
                                icon: const Icon(
                                  Icons.contact_mail_outlined,
                                  color: forgotSecondary,
                                  size: 24,
                                ),
                              ),
                              filled: true,
                              fillColor: forgotLight,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 20,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: Color(0xFF64748B),
                                  width: 1.3,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                  color: forgotNavy,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Information
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: forgotSecondary,
                                size: 17,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _tr(
                                    isAr,
                                    'سنرسل رابط الاستعادة إلى بريدك الإلكتروني. راجع صندوق الوارد والرسائل غير المرغوبة',
                                    'A reset link will be sent to your email. Check your inbox and spam folder.',
                                  ),
                                  style: const TextStyle(
                                    color: forgotSecondary,
                                    fontSize: 12,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 26),

                          // Send Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () => sendRecoveryCode(isAr),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: forgotPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    showSuccess
                                        ? _tr(isAr, 'تم الإرسال', 'Sent')
                                        : _tr(
                                            isAr,
                                            'إرسال رابط الاستعادة',
                                            'Send reset link',
                                          ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    showSuccess
                                        ? Icons.check_circle_outline
                                        : (isAr
                                            ? Icons.arrow_back
                                            : Icons.arrow_forward),
                                    size: 21,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (showSuccess) ...[
                            const SizedBox(height: 18),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: forgotTint,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: forgotNavy,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _tr(
                                        isAr,
                                        'تم إرسال رابط استعادة كلمة السر إلى بريدك الإلكتروني.',
                                        'A password reset link has been sent to your email.',
                                      ),
                                      style: const TextStyle(
                                        color: forgotNavy,
                                        fontSize: 12,
                                        height: 1.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 34),

                    // Back to Login
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        isAr ? Icons.arrow_forward : Icons.arrow_back,
                        color: forgotNavy,
                        size: 21,
                      ),
                      label: Text(
                        _tr(isAr, 'رجوع لتسجيل الدخول', 'Back to Login'),
                        style: const TextStyle(
                          color: forgotNavy,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Security Footer
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: forgotLight,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: forgotSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _tr(
                                isAr,
                                'بياناتك محمية ومشفّرة وفق معايير الحماية البلدية الآمنة',
                                'Your data is protected and encrypted according to secure municipal standards.',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: forgotSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
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