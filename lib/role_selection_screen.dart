
import 'package:flutter/material.dart';

import 'app_lang.dart';
import 'app_navigation.dart';
import 'login_screen.dart';

const Color _navy = Color(0xFF0F2942);
const Color _page = Color(0xFFF0F4F8);
const Color _textDark = Color(0xFF001428);
const Color _textGrey = Color(0xFF475569);
const Color _softBlue = Color(0xFFE0EAF4);
const Color _border = Color(0xFFCBD5E1);

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  void _open(BuildContext context, UserRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, lang, _) {
        final arabic = lang == 'ar';

        String t(String ar, String en) =>
            arabic ? ar : en;

        return Directionality(
          textDirection:
              arabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: _page,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            arabic
                                ? Icons.arrow_forward
                                : Icons.arrow_back,
                            color: _navy,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: toggleAppLanguage,
                          icon: const Icon(
                            Icons.language,
                            size: 18,
                          ),
                          label: Text(
                            arabic ? 'EN' : 'العربية',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _navy,
                            side: const BorderSide(color: _border),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const _LogoBadge(),

                    const SizedBox(height: 28),

                    Text(
                      t(
                        'اختر طريقة الدخول',
                        'Choose Your Role',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      t(
                        'اختر نوع الحساب للمتابعة',
                        'Select your account type to continue',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _textGrey,
                      ),
                    ),

                    const SizedBox(height: 32),

                    _RoleCard(
                      icon: Icons.person_outline,
                      title: t('مواطن', 'Citizen'),
                      subtitle: t(
                        'سجّل مشاكلك وتابع حالتها',
                        'Report issues and track their status',
                      ),
                      onTap: () => _open(context, UserRole.citizen),
                    ),

                    const SizedBox(height: 16),

                    _RoleCard(
                      icon: Icons.badge_outlined,
                      title: t('موظف', 'Employee'),
                      subtitle: t(
                        'تابع المشاكل المسندة إليك',
                        'Manage issues assigned to you',
                      ),
                      onTap: () => _open(context, UserRole.employee),
                    ),

                    const SizedBox(height: 16),

                    _RoleCard(
                      icon: Icons.shield_outlined,
                      title: t('أدمن', 'Admin'),
                      subtitle: t(
                        'إدارة النظام بالكامل',
                        'Manage the entire system',
                      ),
                      onTap: () => _open(context, UserRole.admin),
                    ),

                    const SizedBox(height: 30),

                    Text(
                      t(
                        'مدينتي للإدارة المتكاملة للمدن',
                        'Madinty Integrated City Management',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _textGrey,
                      ),
                    ),
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

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: const Color(0x330F2942),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: _softBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: _navy,
                  size: 28,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _textGrey,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                isArabic
                    ? Icons.chevron_left
                    : Icons.chevron_right,
                color: _textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _softBlue,
        border: Border.all(
          color: const Color(0x4DE0EAF4),
          width: 8,
        ),
      ),
      child: Container(
        width: 70,
        height: 70,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: const Icon(
          Icons.location_on_outlined,
          size: 38,
          color: _navy,
        ),
      ),
    );
  }
}
