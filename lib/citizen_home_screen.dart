
import 'package:flutter/material.dart';

import 'app_lang.dart';
import 'issues_store.dart';
import 'main.dart';
import 'app_navigation.dart';
import 'report_issue_screen.dart';
import 'issue_details_screen.dart';
import 'services_screen.dart';
import 'notifications_screen.dart';
import 'my_issue_screen.dart';

// ---------- ألوان إضافية للشاشة دي ----------
const Color _textPrimary = Color(0xFF0F172A);
const Color _blue = Color(0xFF0051D5);
const Color _outline = Color(0xFF74777E);
const Color _avatarBg = Color(0xFFDAE2EB);

enum _Filter { all, inProgress, newIssue, resolved }

String _tr(bool isAr, String ar, String en) => isAr ? ar : en;

String _formatDate(DateTime d, bool isAr) {
  const ar = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
  ];
  const en = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  final month = isAr ? ar[d.month - 1] : en[d.month - 1];
  return '${d.day} $month ${d.year}';
}

String _activeText(int n, bool isAr) {
  if (!isAr) return n == 1 ? '1 active report' : '$n active reports';
  if (n == 0) return 'لا توجد بلاغات نشطة';
  if (n == 1) return 'بلاغ واحد نشط';
  if (n == 2) return 'بلاغان نشطان';
  if (n <= 10) return '$n بلاغات نشطة';
  return '$n بلاغًا نشطًا';
}

IconData _typeIcon(IssueType t) {
  switch (t) {
    case IssueType.roads:
      return Icons.add_road;
    case IssueType.sanitation:
      return Icons.delete_outline;
    case IssueType.lighting:
      return Icons.lightbulb_outline;
    case IssueType.water:
      return Icons.opacity;
    case IssueType.gardens:
      return Icons.park_outlined;
    case IssueType.other:
      return Icons.more_horiz;
  }
}

class CitizenHomeScreen extends StatefulWidget {
  const CitizenHomeScreen({super.key, this.userName});

  final String? userName;

  @override
  State<CitizenHomeScreen> createState() => _CitizenHomeScreenState();
}

class _CitizenHomeScreenState extends State<CitizenHomeScreen> {
  _Filter _filter = _Filter.all;
  final bool _hasUnreadNotifications = true;

  List<Issue> get _issues => issuesNotifier.value;

  @override
  void initState() {
    super.initState();
    issuesNotifier.addListener(_onIssuesChanged);
  }

  @override
  void dispose() {
    issuesNotifier.removeListener(_onIssuesChanged);
    super.dispose();
  }

  void _onIssuesChanged() {
    if (mounted) setState(() {});
  }

  int get _nNew =>
      _issues.where((i) => i.status == IssueStatus.newIssue).length;

  int get _nProgress =>
      _issues.where((i) => i.status == IssueStatus.inProgress).length;

  int get _nDone => _issues
      .where((i) =>
          i.status == IssueStatus.resolved ||
          i.status == IssueStatus.closed)
      .length;

  List<Issue> get _shown {
    final list = _issues.where((i) {
      switch (_filter) {
        case _Filter.all:
          return true;
        case _Filter.inProgress:
          return i.status == IssueStatus.inProgress;
        case _Filter.newIssue:
          return i.status == IssueStatus.newIssue;
        case _Filter.resolved:
          return i.status == IssueStatus.resolved ||
              i.status == IssueStatus.closed;
      }
    }).toList();

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // ---------- الانتقال بين الشاشات ----------

  void _soon(bool isAr, String ar, String en) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(_tr(isAr, ar, en))));
  }

  Future<void> _openReport(bool isAr) async {
    final sent = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
    );

    if (sent == true && mounted) {
      _soon(isAr, 'تم إرسال بلاغك بنجاح',
          'Your report was sent successfully');
    }
  }

  // ربط صفحة المواطن بصفحة بلاغاتي
  void _openMyIssues() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MyIssuesScreen(),
      ),
    );
  }

  void _openServices() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ServicesScreen(),
      ),
    );
  }

  void _openNotifications(bool isAr) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  void _openDetails(bool isAr, Issue issue) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IssueDetailsScreen(issue: issue),
      ),
    );
  }

  void _logout() {
    logoutToRoleSelection(context);
  }

  void _toggleLang() {
    toggleAppLanguage();
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
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(isAr),
                    _buildSummaryCard(isAr),
                    const SizedBox(height: 10),
                    _buildMyIssuesButton(isAr),
                    const SizedBox(height: 16),
                    _buildReportButton(isAr),
                    const SizedBox(height: 12),
                    _buildServicesButton(isAr),
                    const SizedBox(height: 20),
                    _buildSectionHeader(isAr),
                    const SizedBox(height: 12),
                    _buildList(isAr),
                    const SizedBox(height: 24),
                    _buildSecureFooter(isAr),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- الشريط العلوي ----------
  Widget _buildHeader(bool isAr) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            _circleButton(
              icon: Icons.logout,
              iconSize: 19,
              color: AppColors.slateSecondary,
              tooltip: _tr(isAr, 'تسجيل الخروج', 'Log out'),
              onTap: _logout,
            ),
            const SizedBox(width: 8),
            _buildLangPill(isAr),
            const SizedBox(width: 8),
            _buildBell(isAr),
            const SizedBox(width: 8),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: _avatarBg,
                        child: Icon(
                          Icons.person,
                          color: AppColors.navy,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _tr(isAr, 'أهلاً بك،', 'Welcome,'),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slateSecondary,
                              ),
                            ),
                            Text(
                              widget.userName ??
                                  _tr(isAr, 'مواطن', 'Citizen'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required double iconSize,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 1,
        shadowColor: const Color(0x1A0F2942),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: iconSize, color: color),
          ),
        ),
      ),
    );
  }

  Widget _buildLangPill(bool isAr) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(
        side: BorderSide(color: AppColors.navy, width: 1),
      ),
      elevation: 0.5,
      shadowColor: const Color(0x140F2942),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: _toggleLang,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language,
                size: 16,
                color: AppColors.navy,
              ),
              const SizedBox(width: 6),
              Text(
                isAr ? 'EN' : 'AR',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBell(bool isAr) {
    return Stack(
      children: [
        _circleButton(
          icon: Icons.notifications_none,
          iconSize: 20,
          color: AppColors.navy,
          tooltip: _tr(isAr, 'الإشعارات', 'Notifications'),
          onTap: () => _openNotifications(isAr),
        ),
        if (_hasUnreadNotifications)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  // ---------- كارت العنوان والأرقام ----------
  Widget _buildSummaryCard(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F2942),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr(isAr, 'مشاكلي', 'My issues'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _tr(
                        isAr,
                        'متابعة البلاغات المدنية والخدمات الميدانية',
                        'Track your city reports and field services',
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.slateSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tintSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _activeText(_nNew + _nProgress, isAr),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _statTile(
                  '$_nNew',
                  _tr(isAr, 'جديدة', 'New'),
                  AppColors.navy,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  '$_nProgress',
                  _tr(isAr, 'قيد المتابعة', 'In progress'),
                  _blue,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statTile(
                  '$_nDone',
                  _tr(isAr, 'مكتملة', 'Done'),
                  _textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statTile(String number, String label, Color numberColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.containerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: numberColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.slateSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- زر الانتقال إلى كل بلاغات المواطن ----------
  Widget _buildMyIssuesButton(bool isAr) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _openMyIssues,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.assignment_outlined,
                color: AppColors.navy,
                size: 21,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _tr(isAr, 'عرض كل بلاغاتي', 'View all my reports'),
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                isAr ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                color: AppColors.slateSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- زرار تسجيل مشكلة جديدة ----------
  Widget _buildReportButton(bool isAr) {
    return Material(
      color: AppColors.navy,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: const Color(0x4D0F2942),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openReport(isAr),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr(isAr, 'سجّل مشكلة جديدة', 'Report a new issue'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _tr(
                        isAr,
                        'إرسال تقرير فوري للبلدية بالصور والموقع',
                        'Send a report to the city with photos and location',
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.tintSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isAr ? Icons.arrow_back : Icons.arrow_forward,
                color: AppColors.tintSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- زر خدمات المدينة ----------
  Widget _buildServicesButton(bool isAr) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _openServices,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 15,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.tintSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_city,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _tr(
                    isAr,
                    'استكشف خدمات المدينة',
                    'Explore City Services',
                  ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
              ),
              Icon(
                isAr ? Icons.arrow_back : Icons.arrow_forward,
                color: AppColors.navy,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- عنوان القسم + أزرار الفلترة ----------
  Widget _buildSectionHeader(bool isAr) {
    final chips = <_Filter, String>{
      _Filter.all: '${_tr(isAr, 'الكل', 'All')} (${_issues.length})',
      _Filter.inProgress:
          '${_tr(isAr, 'قيد المعالجة', 'In progress')} ($_nProgress)',
      _Filter.newIssue: '${_tr(isAr, 'جديدة', 'New')} ($_nNew)',
      _Filter.resolved: '${_tr(isAr, 'تم الحل', 'Resolved')} ($_nDone)',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _tr(isAr, 'سجل التقارير', 'Report history'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            Text(
              _tr(isAr, 'مرتبة حسب الأحدث', 'Newest first'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.slateSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final entry in chips.entries) ...[
                _chip(
                  entry.value,
                  entry.key == _filter,
                  () => setState(() => _filter = entry.key),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Material(
      color: selected ? AppColors.navy : Colors.white,
      borderRadius: BorderRadius.circular(999),
      elevation: 1,
      shadowColor: const Color(0x1A0F2942),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 7,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: selected
                  ? Colors.white
                  : AppColors.slateSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ---------- قائمة المشاكل ----------
  Widget _buildList(bool isAr) {
    final shown = _shown;

    if (shown.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          _tr(
            isAr,
            'لا توجد بلاغات في هذا القسم',
            'No reports in this section',
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.slateSecondary,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final issue in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildIssueCard(isAr, issue),
          ),
      ],
    );
  }

  Widget _buildIssueCard(bool isAr, Issue issue) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: const Color(0x1A0F2942),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetails(isAr, issue),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.tintSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _typeIcon(issue.type),
                          color: AppColors.navy,
                          size: 32,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xB3001428),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '#${issue.shortId}',
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _tr(isAr, issue.titleAr, issue.titleEn),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            isAr
                                ? Icons.chevron_left
                                : Icons.chevron_right,
                            size: 20,
                            color: _outline,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 15,
                            color: _blue,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _tr(
                                isAr,
                                issue.locationAr,
                                issue.locationEn,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.slateSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.slateSecondary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _formatDate(issue.date, isAr),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.slateSecondary,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _statusBadge(isAr, issue),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(bool isAr, Issue issue) {
    Color bg;
    Color fg;
    String label;
    Widget leading;

    if (issue.pending) {
      bg = const Color(0xFFF1F5F9);
      fg = AppColors.slateSecondary;
      label = _tr(isAr, 'لم تُرسل بعد', 'Not sent yet');
      leading = Icon(Icons.cloud_off, size: 14, color: fg);
    } else {
      switch (issue.status) {
        case IssueStatus.inProgress:
          bg = const Color(0xFFFFFBEB);
          fg = const Color(0xFF92400E);
          label = _tr(isAr, 'قيد المعالجة', 'In progress');
          leading = _dot(const Color(0xFFF59E0B));
          break;

        case IssueStatus.newIssue:
          bg = AppColors.tintSoft;
          fg = AppColors.navy;
          label = _tr(isAr, 'جديدة', 'New');
          leading = _dot(_blue);
          break;

        case IssueStatus.resolved:
          bg = const Color(0xFFECFDF5);
          fg = const Color(0xFF065F46);
          label = _tr(isAr, 'تم الحل', 'Resolved');
          leading = const Icon(
            Icons.check_circle,
            size: 14,
            color: Color(0xFF059669),
          );
          break;

        case IssueStatus.closed:
          bg = const Color(0xFFF1F5F9);
          fg = AppColors.slateSecondary;
          label = _tr(isAr, 'مغلقة', 'Closed');
          leading = Icon(Icons.lock_outline, size: 14, color: fg);
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      );

  // ---------- شريط الأمان ----------
  Widget _buildSecureFooter(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.containerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 18,
            color: _blue,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _tr(
                isAr,
                'بياناتك محمية وموثقة عبر البوابة البلدية الذكية',
                'Your data is protected and verified by the Smart City Portal',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.slateSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
