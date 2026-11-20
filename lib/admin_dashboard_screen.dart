
import 'package:flutter/material.dart';

import 'app_lang.dart';
import 'issues_store.dart';
import 'main.dart';
import 'app_navigation.dart';
import 'manage_users_screen.dart';
import 'manage_employees_screen.dart';
import 'manage_requests_screen.dart';

// ---------- Colors ----------
const Color _adminText = Color(0xFF0F172A);
const Color _adminBlue = Color(0xFF0051D5);
const Color _adminMuted = Color(0xFF64748B);

// ---------- Translation ----------
String _trAdmin(bool isAr, String ar, String en) {
  return isAr ? ar : en;
}

// ======================================================
// ADMIN DASHBOARD
// ======================================================

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {

  @override
  void initState() {
    super.initState();
    issuesNotifier.addListener(_refresh);
  }

  @override
  void dispose() {
    issuesNotifier.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  int get _totalRequests => issuesNotifier.value.length;

  int get _resolvedRequests => issuesNotifier.value
      .where((issue) =>
          issue.status == IssueStatus.resolved ||
          issue.status == IssueStatus.closed)
      .length;

  int get _staleRequests =>
      issuesNotifier.value.where((issue) => issue.isStale).length;

  int get _needsAssignmentRequests => issuesNotifier.value
      .where((issue) => issue.needsAdminAssignment)
      .length;

  void _toggleLanguage() {
    toggleAppLanguage();
  }

  void _logout() {
    logoutToRoleSelection(context);
  }

  // ---------- MANAGEMENT NAVIGATION ----------
  void _openManagement(_ManagementItem item) {
    Widget page;

    switch (item.id) {
      case 'users':
        page = const ManageUsersScreen();
        break;

      case 'employees':
        page = const ManageEmployeesScreen();
        break;

      case 'requests':
        page = const ManageRequestsScreen();
        break;

      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
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
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    _buildHeader(isAr),

                    const SizedBox(height: 20),

                    _buildWelcome(isAr),

                    const SizedBox(height: 20),

                    _buildStatistics(isAr),

                    const SizedBox(height: 26),

                    _buildManagementTitle(isAr),

                    const SizedBox(height: 14),

                    _buildManagementCards(isAr),

                    const SizedBox(height: 24),

                    _buildFooter(isAr),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------- HEADER ----------

  Widget _buildHeader(bool isAr) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        children: [

          _circleButton(
            Icons.logout,
            _trAdmin(isAr, 'تسجيل الخروج', 'Log out'),
            _logout,
          ),

          const SizedBox(width: 8),

          _languageButton(isAr),

          const Spacer(),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: AppColors.navy,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 1,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              icon,
              size: 19,
              color: AppColors.navy,
            ),
          ),
        ),
      ),
    );
  }

  Widget _languageButton(bool isAr) {
    return Material(
      color: Colors.white,
      shape: const StadiumBorder(
        side: BorderSide(color: AppColors.navy),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: _toggleLanguage,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          child: Row(
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- WELCOME SECTION ----------

  Widget _buildWelcome(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180F2942),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              const Icon(
                Icons.verified_user_outlined,
                color: Color(0xFFBFD7F0),
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                _trAdmin(
                  isAr,
                  'لوحة تحكم المسؤول',
                  'ADMIN CONTROL PANEL',
                ),
                style: const TextStyle(
                  color: Color(0xFFBFD7F0),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            _trAdmin(
              isAr,
              'مرحباً بك، المسؤول 👋',
              'Welcome, Administrator 👋',
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            _trAdmin(
              isAr,
              'إدارة ومتابعة جميع خدمات المدينة من مكان واحد.',
              'Manage and monitor all city services in one place.',
            ),
            style: const TextStyle(
              color: Color(0xFFDCE8F5),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- STATISTICS ----------

  Widget _buildStatistics(bool isAr) {
    final stats = [
      _AdminStat(
        _trAdmin(isAr, 'إجمالي المستخدمين', 'Total Users'),
        '--',
        Icons.people_outline,
        const Color(0xFFE8F0FE),
        _adminBlue,
      ),
      _AdminStat(
        _trAdmin(isAr, 'إجمالي الموظفين', 'Total Employees'),
        '--',
        Icons.badge_outlined,
        const Color(0xFFEDE9FE),
        const Color(0xFF6D4CC3),
      ),
      _AdminStat(
        _trAdmin(isAr, 'طلبات تم حلها', 'Resolved Requests'),
        '$_resolvedRequests',
        Icons.task_alt_outlined,
        const Color(0xFFE0F2FE),
        const Color(0xFF0284C7),
      ),
      _AdminStat(
        _trAdmin(isAr, 'إجمالي الطلبات', 'Total Requests'),
        '$_totalRequests',
        Icons.assignment_outlined,
        const Color(0xFFDCFCE7),
        const Color(0xFF15803D),
      ),
      _AdminStat(
        _trAdmin(isAr, 'بلاغات واقفة', 'Stalled Requests'),
        '$_staleRequests',
        Icons.hourglass_bottom,
        const Color(0xFFFEF3C7),
        const Color(0xFFB45309),
      ),
      _AdminStat(
        _trAdmin(isAr, 'محتاجة إسناد', 'Needs Assignment'),
        '$_needsAssignmentRequests',
        Icons.person_off_outlined,
        const Color(0xFFFEE2E2),
        const Color(0xFFB91C1C),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          _trAdmin(isAr, 'نظرة عامة', 'Overview'),
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: _adminText,
          ),
        ),

        const SizedBox(height: 14),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            return _statCard(stats[index]);
          },
        ),
      ],
    );
  }

  Widget _statCard(_AdminStat stat) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: stat.background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              stat.icon,
              color: stat.color,
              size: 21,
            ),
          ),

          Text(
            stat.value,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: _adminText,
            ),
          ),

          Text(
            stat.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _adminMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- MANAGEMENT SECTION ----------

  Widget _buildManagementTitle(bool isAr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          _trAdmin(
            isAr,
            'إدارة النظام',
            'System Management',
          ),
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: _adminText,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          _trAdmin(
            isAr,
            'اختر القسم الذي تريد إدارته',
            'Select a section to manage',
          ),
          style: const TextStyle(
            fontSize: 12,
            color: _adminMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildManagementCards(bool isAr) {
    final items = [
      _ManagementItem(
        _trAdmin(isAr, 'إدارة المستخدمين', 'Manage Users'),
        _trAdmin(
          isAr,
          'عرض وإدارة حسابات المواطنين',
          'View and manage citizen accounts',
        ),
        Icons.people_outline,
        const Color(0xFFE8F0FE),
        _adminBlue,
        'users',
      ),
      _ManagementItem(
        _trAdmin(isAr, 'إدارة الموظفين', 'Manage Employees'),
        _trAdmin(
          isAr,
          'إدارة بيانات الموظفين',
          'Manage employee information',
        ),
        Icons.badge_outlined,
        const Color(0xFFEDE9FE),
        const Color(0xFF6D4CC3),
        'employees',
      ),
      _ManagementItem(
        _trAdmin(isAr, 'إدارة الطلبات', 'Manage Requests'),
        _trAdmin(
          isAr,
          'متابعة جميع طلبات المواطنين',
          'Monitor all citizen requests',
        ),
        Icons.assignment_outlined,
        const Color(0xFFDCFCE7),
        const Color(0xFF15803D),
        'requests',
      ),
    ];

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _managementCard(item, isAr),
          ),
      ],
    );
  }

  Widget _managementCard(
    _ManagementItem item,
    bool isAr,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _openManagement(item);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [

              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.background,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  item.icon,
                  color: item.color,
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _adminText,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _adminMuted,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                isAr
                    ? Icons.arrow_back_ios_new
                    : Icons.arrow_forward_ios,
                size: 15,
                color: _adminMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- FOOTER ----------

  Widget _buildFooter(bool isAr) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.containerLow,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          const Icon(
            Icons.admin_panel_settings_outlined,
            size: 19,
            color: AppColors.navy,
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Text(
              _trAdmin(
                isAr,
                'Madinty - نظام إدارة المدينة الذكية',
                'Madinty - Smart City Management System',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.slateSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- STAT MODEL ----------

class _AdminStat {
  final String title;
  final String value;
  final IconData icon;
  final Color background;
  final Color color;

  const _AdminStat(
    this.title,
    this.value,
    this.icon,
    this.background,
    this.color,
  );
}

// ---------- MANAGEMENT MODEL ----------

class _ManagementItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color background;
  final Color color;
  final String id;

  const _ManagementItem(
    this.title,
    this.subtitle,
    this.icon,
    this.background,
    this.color,
    this.id,
  );
}
