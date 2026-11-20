
import 'package:flutter/material.dart';

import 'app_lang.dart';
import 'main.dart';
import 'report_issue_screen.dart';

String _tr(bool isAr, String ar, String en) => isAr ? ar : en;

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  static const List<_CityService> services = [
    _CityService(
      icon: Icons.lightbulb_outline,
      ar: 'إنارة الشوارع',
      en: 'Street Lighting',
      descAr: 'الإبلاغ عن أعطال أعمدة الإنارة',
      descEn: 'Report street lighting problems',
      color: Color(0xFFFFF4D6),
    ),
    _CityService(
      icon: Icons.delete_outline,
      ar: 'إدارة المخلفات',
      en: 'Waste Management',
      descAr: 'الإبلاغ عن تراكم القمامة',
      descEn: 'Report waste collection problems',
      color: Color(0xFFE5F5EC),
    ),
    _CityService(
      icon: Icons.add_road,
      ar: 'صيانة الطرق',
      en: 'Road Maintenance',
      descAr: 'الإبلاغ عن تلف الطرق والحفر',
      descEn: 'Report damaged roads and potholes',
      color: Color(0xFFE8EEFF),
    ),
    _CityService(
      icon: Icons.park_outlined,
      ar: 'الحدائق والمتنزهات',
      en: 'Parks & Gardens',
      descAr: 'الإبلاغ عن مشكلات الحدائق',
      descEn: 'Report parks and garden problems',
      color: Color(0xFFE4F4E8),
    ),
    _CityService(
      icon: Icons.water_drop_outlined,
      ar: 'خدمات المياه',
      en: 'Water Services',
      descAr: 'الإبلاغ عن تسربات المياه',
      descEn: 'Report water leaks and problems',
      color: Color(0xFFE1F3FA),
    ),
    _CityService(
      icon: Icons.bolt_outlined,
      ar: 'الكهرباء',
      en: 'Electricity',
      descAr: 'الإبلاغ عن أعطال الكهرباء',
      descEn: 'Report electricity problems',
      color: Color(0xFFFFE9E5),
    ),
  ];

  void _openReport(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ReportIssueScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, lang, _) {
        final isAr = lang == 'ar';

        return Directionality(
          textDirection:
              isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              foregroundColor: AppColors.navy,
              title: Text(
                _tr(isAr, 'خدمات المدينة', 'City Services'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_city,
                            color: Colors.white,
                            size: 34,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _tr(
                              isAr,
                              'خدمات مدينتي',
                              'Madinty Services',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            _tr(
                              isAr,
                              'اختر الخدمة التي تحتاج إليها لتقديم بلاغك.',
                              'Choose the service you need to submit a request.',
                            ),
                            style: const TextStyle(
                              color: AppColors.tintSoft,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      _tr(isAr, 'الخدمات المتاحة', 'Available Services'),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 14),

                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: services.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, index) {
                        final service = services[index];

                        return _ServiceCard(
                          service: service,
                          isAr: isAr,
                          onTap: () => _openReport(context),
                        );
                      },
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: () => _openReport(context),
                        icon: const Icon(Icons.add),
                        label: Text(
                          _tr(
                            isAr,
                            'تقديم طلب خدمة',
                            'Submit a Request',
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
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

class _CityService {
  final IconData icon;
  final String ar;
  final String en;
  final String descAr;
  final String descEn;
  final Color color;

  const _CityService({
    required this.icon,
    required this.ar,
    required this.en,
    required this.descAr,
    required this.descEn,
    required this.color,
  });
}

class _ServiceCard extends StatelessWidget {
  final _CityService service;
  final bool isAr;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
    required this.isAr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: service.color,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  service.icon,
                  color: AppColors.navy,
                  size: 27,
                ),
              ),
              const Spacer(),
              Text(
                _tr(isAr, service.ar, service.en),
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _tr(isAr, service.descAr, service.descEn),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.slateSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment:
                    isAr ? Alignment.centerLeft : Alignment.centerRight,
                child: Icon(
                  isAr ? Icons.arrow_back : Icons.arrow_forward,
                  color: AppColors.navy,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
