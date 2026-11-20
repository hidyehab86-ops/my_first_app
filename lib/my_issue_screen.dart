
import 'package:flutter/material.dart';

import 'app_lang.dart';
import 'issues_store.dart';
import 'report_issue_screen.dart';
import 'issue_details_screen.dart';
import 'main.dart';

class MyIssuesScreen extends StatefulWidget {
  const MyIssuesScreen({super.key});

  @override
  State<MyIssuesScreen> createState() => _MyIssuesScreenState();
}

class _MyIssuesScreenState extends State<MyIssuesScreen> {
  IssueStatus? selectedStatus;

  bool get isAr => appLang.value == 'ar';

  String tr(String ar, String en) => isAr ? ar : en;

  Color statusColor(IssueStatus status) {
    switch (status) {
      case IssueStatus.newIssue:
        return const Color(0xFF2563EB);
      case IssueStatus.inProgress:
        return const Color(0xFFD97706);
      case IssueStatus.resolved:
        return const Color(0xFF16A34A);
      case IssueStatus.closed:
        return const Color(0xFF64748B);
    }
  }

  String statusLabel(IssueStatus status) {
    switch (status) {
      case IssueStatus.newIssue:
        return tr('جديد', 'New');
      case IssueStatus.inProgress:
        return tr('قيد المعالجة', 'In Progress');
      case IssueStatus.resolved:
        return tr('تم الحل', 'Resolved');
      case IssueStatus.closed:
        return tr('مغلق', 'Closed');
    }
  }

  IconData typeIcon(IssueType type) {
    switch (type) {
      case IssueType.roads:
        return Icons.add_road;
      case IssueType.sanitation:
        return Icons.delete_outline;
      case IssueType.lighting:
        return Icons.lightbulb_outline;
      case IssueType.water:
        return Icons.water_drop_outlined;
      case IssueType.gardens:
        return Icons.park_outlined;
      case IssueType.other:
        return Icons.more_horiz;
    }
  }

  List<Issue> getSortedIssues(List<Issue> issues) {
    final result = selectedStatus == null
        ? List<Issue>.from(issues)
        : issues
            .where((i) => i.status == selectedStatus)
            .toList();

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  Future<void> _openNewReport() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const ReportIssueScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      setState(() {
        selectedStatus = IssueStatus.newIssue;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'تم إرسال البلاغ بنجاح',
                'Report submitted successfully',
              ),
            ),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
    }
  }

  void _openIssueDetails(Issue issue) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IssueDetailsScreen(issue: issue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, lang, _) {
        final arabic = lang == 'ar';

        return Directionality(
          textDirection:
              arabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: AppColors.surface,
            body: SafeArea(
              child: ValueListenableBuilder<List<Issue>>(
                valueListenable: issuesNotifier,
                builder: (context, issues, _) {
                  final filteredIssues = getSortedIssues(issues);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 22),

                        _buildStatistics(issues),

                        const SizedBox(height: 25),

                        _buildFilters(),

                        const SizedBox(height: 18),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              tr('قائمة البلاغات', 'My Reports'),
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${filteredIssues.length} ${tr('بلاغ', 'Reports')}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        if (filteredIssues.isEmpty)
                          _buildEmptyState()
                        else
                          ...filteredIssues.map(
                            (issue) => _buildIssueCard(issue),
                          ),

                        const SizedBox(height: 20),

                        _buildAddButton(),

                        const SizedBox(height: 25),
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

  // ---------- Header ----------

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('بلاغاتي', 'My Issues'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F2942),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                tr(
                  'تابع حالة بلاغاتك وتحديثاتها',
                  'Track your reports and their updates',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFE0EAF4),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.assignment_outlined,
            color: Color(0xFF0F2942),
            size: 27,
          ),
        ),
      ],
    );
  }

  // ---------- Statistics ----------

  Widget _buildStatistics(List<Issue> issues) {
    final newCount = issues
        .where((i) => i.status == IssueStatus.newIssue)
        .length;

    final progressCount = issues
        .where((i) => i.status == IssueStatus.inProgress)
        .length;

    final resolvedCount = issues
        .where((i) =>
            i.status == IssueStatus.resolved ||
            i.status == IssueStatus.closed)
        .length;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            tr('الإجمالي', 'Total'),
            issues.length,
            Icons.folder_outlined,
            const Color(0xFF0F2942),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _statCard(
            tr('جديد', 'New'),
            newCount,
            Icons.fiber_new,
            const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _statCard(
            tr('قيد التنفيذ', 'In Progress'),
            progressCount,
            Icons.pending_actions,
            const Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _statCard(
            tr('تم الحل', 'Resolved'),
            resolvedCount,
            Icons.check_circle_outline,
            const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    String title,
    int count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Filters ----------

  Widget _buildFilters() {
    final filters = <IssueStatus?>[
      null,
      IssueStatus.newIssue,
      IssueStatus.inProgress,
      IssueStatus.resolved,
      IssueStatus.closed,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((status) {
          final selected = selectedStatus == status;

          final label = status == null
              ? tr('الكل', 'All')
              : statusLabel(status);

          return Padding(
            padding:
                const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  selectedStatus = status;
                });
              },
              selectedColor: const Color(0xFF0F2942),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected
                    ? Colors.white
                    : const Color(0xFF475569),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------- Issue Card ----------

  Widget _buildIssueCard(Issue issue) {
    final color = issue.pending
        ? const Color(0xFF64748B)
        : statusColor(issue.status);

    final label = issue.pending
        ? tr('لم يُرسل بعد', 'Not submitted')
        : statusLabel(issue.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openIssueDetails(issue),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEBF1F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      typeIcon(issue.type),
                      color: const Color(0xFF0F2942),
                      size: 23,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAr ? issue.titleAr : issue.titleEn,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '#${issue.shortId}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      isAr
                          ? issue.locationAr
                          : issue.locationEn,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${issue.date.day}/${issue.date.month}/${issue.date.year}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),

                  const Spacer(),

                  Text(
                    tr('التفاصيل', 'Details'),
                    style: const TextStyle(
                      color: Color(0xFF0F2942),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Color(0xFF0F2942),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Empty State ----------

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 55,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 15),
          Text(
            tr('لا توجد بلاغات هنا', 'No reports found'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2942),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            tr(
              'يمكنك إنشاء بلاغ جديد من الزر بالأسفل',
              'You can create a new report using the button below',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Add Report ----------

  Widget _buildAddButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _openNewReport,
        icon: const Icon(Icons.add),
        label: Text(
          tr('إنشاء بلاغ جديد', 'Create New Report'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F2942),
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
