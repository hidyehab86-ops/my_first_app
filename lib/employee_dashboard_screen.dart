
import 'package:flutter/material.dart';

import 'app_lang.dart';
import 'issues_store.dart';
import 'manage_requests_screen.dart';
import 'issue_details_screen.dart';
import 'app_navigation.dart';

const Color _navy = Color(0xFF0F2942);
const Color _blue = Color(0xFF0051D5);
const Color _background = Color(0xFFF5F7FA);
const Color _secondary = Color(0xFF64748B);

class EmployeeDashboardScreen extends StatelessWidget {
  const EmployeeDashboardScreen({super.key});

  String tr(bool isAr, String ar, String en) => isAr ? ar : en;

  void _openRequests(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ManageRequestsScreen(),
      ),
    );
  }

  void _openDetails(BuildContext context, Issue issue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IssueDetailsScreen(issue: issue),
      ),
    );
  }

  Color _statusColor(IssueStatus status) {
    switch (status) {
      case IssueStatus.newIssue:
        return const Color(0xFFD97706);
      case IssueStatus.inProgress:
        return const Color(0xFF0284C7);
      case IssueStatus.resolved:
        return const Color(0xFF059669);
      case IssueStatus.closed:
        return const Color(0xFF64748B);
    }
  }

  String _statusText(IssueStatus status, bool isAr) {
    switch (status) {
      case IssueStatus.newIssue:
        return tr(isAr, 'جديد', 'New');
      case IssueStatus.inProgress:
        return tr(isAr, 'قيد التنفيذ', 'In Progress');
      case IssueStatus.resolved:
        return tr(isAr, 'تم الحل', 'Resolved');
      case IssueStatus.closed:
        return tr(isAr, 'مغلق', 'Closed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, lang, child) {
        final isAr = lang == 'ar';

        return Directionality(
          textDirection:
              isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: _background,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              foregroundColor: _navy,
              title: Text(
                tr(isAr, 'لوحة تحكم الموظف', 'Employee Dashboard'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
              centerTitle: true,
              actions: [
                TextButton(
                  onPressed: toggleAppLanguage,
                  child: Text(isAr ? 'EN' : 'AR'),
                ),
                IconButton(
                  tooltip: tr(isAr, 'تسجيل الخروج', 'Log out'),
                  icon: const Icon(Icons.logout),
                  onPressed: () => logoutToRoleSelection(context),
                ),
              ],
            ),
            body: SafeArea(
              child: ValueListenableBuilder<List<Issue>>(
                valueListenable: issuesNotifier,
                builder: (context, issues, child) {
                  final sortedIssues = List<Issue>.from(issues)
                    ..sort((a, b) => b.date.compareTo(a.date));

                  final totalCount = issues.length;

                  final newCount = issues
                      .where((issue) =>
                          issue.status == IssueStatus.newIssue)
                      .length;

                  final progressCount = issues
                      .where((issue) =>
                          issue.status == IssueStatus.inProgress)
                      .length;

                  final resolvedCount = issues
                      .where((issue) =>
                          issue.status == IssueStatus.resolved ||
                          issue.status == IssueStatus.closed)
                      .length;

                  final recentIssues = sortedIssues.take(3).toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _welcomeCard(isAr),
                        const SizedBox(height: 22),

                        Text(
                          tr(isAr, 'إحصائيات الطلبات', 'Requests Overview'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(height: 14),

                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.45,
                          children: [
                            _statCard(
                              tr(isAr, 'إجمالي البلاغات', 'Total Requests'),
                              totalCount.toString(),
                              Icons.assignment_outlined,
                              _blue,
                            ),
                            _statCard(
                              tr(isAr, 'بلاغات جديدة', 'New Requests'),
                              newCount.toString(),
                              Icons.pending_actions,
                              const Color(0xFFD97706),
                            ),
                            _statCard(
                              tr(isAr, 'قيد التنفيذ', 'In Progress'),
                              progressCount.toString(),
                              Icons.autorenew,
                              const Color(0xFF0284C7),
                            ),
                            _statCard(
                              tr(isAr, 'تم حلها', 'Resolved'),
                              resolvedCount.toString(),
                              Icons.check_circle_outline,
                              const Color(0xFF059669),
                            ),
                          ],
                        ),

                        const SizedBox(height: 26),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr(isAr, 'أحدث البلاغات', 'Recent Requests'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _navy,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _openRequests(context),
                              child: Text(tr(isAr, 'عرض الكل', 'View All')),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        if (recentIssues.isEmpty)
                          _emptyRequests(isAr)
                        else
                          ...recentIssues.map(
                            (issue) => InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _openDetails(context, issue),
                              child: _requestCard(issue, isAr),
                            ),
                          ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => _openRequests(context),
                            icon: const Icon(Icons.manage_search),
                            label: Text(
                              tr(isAr, 'إدارة البلاغات', 'Manage Requests'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _navy,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _welcomeCard(bool isAr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.badge_outlined,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(isAr, 'مرحباً بك 👋', 'Welcome 👋'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  tr(
                    isAr,
                    'تابع بلاغات المواطنين وقم بإدارتها',
                    'Monitor and manage citizen requests',
                  ),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
    String title,
    String number,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 25),
          Text(
            number,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: _secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestCard(Issue issue, bool isAr) {
    final statusColor = _statusColor(issue.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${issue.shortId}',
                style: const TextStyle(
                  color: _blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText(issue.status, isAr),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isAr ? issue.titleAr : issue.titleEn,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: _secondary,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  isAr ? issue.locationAr : issue.locationEn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${issue.date.day}/${issue.date.month}/${issue.date.year}',
            style: const TextStyle(
              fontSize: 11,
              color: _secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyRequests(bool isAr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 35,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 45,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 10),
          Text(
            tr(isAr, 'لا توجد بلاغات حتى الآن', 'No requests yet'),
            style: const TextStyle(
              color: _navy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
