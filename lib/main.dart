import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app_lang.dart';
import 'firebase_options.dart';
import 'role_selection_screen.dart';

// ---------- Colors ----------
class AppColors {
  static const surface = Color(0xFFF0F4F8);
  static const primary = Color(0xFF001428);
  static const navy = Color(0xFF0F2942);
  static const slateSecondary = Color(0xFF475569);
  static const borderSubtle = Color(0xFFCBD5E1);
  static const tintSoft = Color(0xFFE0EAF4);
  static const containerLow = Color(0xFFEBF1F6);
  static const accentDot = Color(0xFFDBE1FF);
  static const greyDot = Color(0xFFDFE3E7);
}

Future<void> main() async {
  // لازم السطرين دول قبل تشغيل التطبيق عشان Firebase يشتغل
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MadintyApp());
}

// ---------- Main App ----------
class MadintyApp extends StatelessWidget {
  const MadintyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, lang, _) {
        final arabic = lang == 'ar';

        return MaterialApp(
          title: 'Madinty',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.surface,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.navy,
            ),
          ),
          builder: (context, child) {
            return Directionality(
              textDirection: arabic
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: child!,
            );
          },
          home: const WelcomeScreen(),
        );
      },
    );
  }
}

// ---------- Language Button ----------
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, lang, _) {
        final arabic = lang == 'ar';

        return OutlinedButton.icon(
          onPressed: () {
            toggleAppLanguage();
          },
          icon: const Icon(
            Icons.language,
            size: 18,
          ),
          label: Text(
            arabic ? 'English' : 'العربية',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navy,
            backgroundColor: Colors.white,
            side: const BorderSide(
              color: AppColors.borderSubtle,
            ),
            shape: const StadiumBorder(),
          ),
        );
      },
    );
  }
}

// ---------- Logo ----------
class LogoBadge extends StatelessWidget {
  const LogoBadge({
    super.key,
    this.size = 128,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 16,
      height: size + 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.tintSoft,
              border: Border.all(
                color: const Color(0x4DE0EAF4),
                width: 8,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: size * 0.69,
                height: size * 0.69,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  size: size * 0.45,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
          const Positioned(
            top: 0,
            right: 4,
            child: CircleAvatar(
              radius: 7,
              backgroundColor: AppColors.accentDot,
            ),
          ),
          const Positioned(
            bottom: 4,
            left: 4,
            child: CircleAvatar(
              radius: 6,
              backgroundColor: AppColors.greyDot,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Skyline ----------
class SkylinePainter extends CustomPainter {
  const SkylinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 400;
    final sy = size.height / 120;

    final paint = Paint()
      ..color = const Color(0x260F2942);

    const buildings = <List<double>>[
      [10, 60, 25, 60],
      [40, 35, 30, 85],
      [75, 75, 20, 45],
      [100, 45, 35, 75],
      [140, 20, 40, 100],
      [185, 50, 28, 70],
      [218, 30, 38, 90],
      [260, 65, 25, 55],
      [290, 40, 36, 80],
      [332, 55, 28, 65],
      [365, 70, 25, 50],
    ];

    for (final b in buildings) {
      canvas.drawRect(
        Rect.fromLTWH(
          b[0] * sx,
          b[1] * sy,
          b[2] * sx,
          b[3] * sy,
        ),
        paint,
      );
    }

    final roof1 = Path()
      ..moveTo(40 * sx, 35 * sy)
      ..lineTo(55 * sx, 20 * sy)
      ..lineTo(70 * sx, 35 * sy);

    final roof2 = Path()
      ..moveTo(140 * sx, 20 * sy)
      ..lineTo(160 * sx, 5 * sy)
      ..lineTo(180 * sx, 20 * sy);

    canvas.drawPath(roof1, paint);
    canvas.drawPath(roof2, paint);
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) => false;
}

// ---------- Welcome Screen ----------
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, lang, _) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: const LanguageButton(),
                  ),
                  const SizedBox(height: 10),
                  const LogoBadge(),
                  const Spacer(),
                  _buildMiddle(),
                  const Spacer(),
                  _buildBottom(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiddle() {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 0,
            right: 0,
            bottom: -8,
            child: SizedBox(
              height: 96,
              child: CustomPaint(
                painter: SkylinePainter(),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                translate(
                  'مرحباً بك في\nخدمات مدينتي!',
                  'Welcome to\nMadinty Services!',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 56,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                translate(
                  'بوابتك الذكية للخدمات البلدية وطلبات المجتمع والوصول إلى خدمات المدينة بسهولة.',
                  'Your seamless municipal gateway for community living, requests, and smart city access.',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.7,
                  color: AppColors.slateSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.containerLow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  translate(
                    'البوابة الرسمية للخدمات البلدية',
                    'OFFICIAL CIVIC PORTAL',
                  ),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottom(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RoleSelectionScreen(),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  translate('ابدأ الآن', 'START'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          translate(
            'مدينتي للإدارة المتكاملة للمدن',
            'Madinty Integrated City Management',
          ),
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xB3475569),
          ),
        ),
      ],
    );
  }
}