
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_lang.dart';
import 'issues_store.dart';
import 'issue_details_screen.dart';
import 'main.dart';

const Color _blue = Color(0xFF0051D5);
const Color _textDark = Color(0xFF0F172A);

String _tr(bool isAr, String ar, String en) => isAr ? ar : en;

// نتيجة نافذة "تأكيد الحل": ملاحظة + صورة بعد الإصلاح (الاتنين اختياري)
class _ResolutionInput {
  const _ResolutionInput(this.note, this.photo);
  final String note;
  final String? photo; // base64
}

enum _RequestFilter {
  all,
  newIssue,
  inProgress,
  resolved,
  stale,
  needsAssignment,
}

class ManageRequestsScreen extends StatefulWidget {
  const ManageRequestsScreen({super.key});

  @override
  State<ManageRequestsScreen> createState() =>
      _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends State<ManageRequestsScreen> {
  _RequestFilter _filter = _RequestFilter.all;

  // بنغيّره لما المستخدم يلغي عشان القايمة ترجع للحالة الصح
  int _dropdownEpoch = 0;

  List<Issue> _filterIssues(List<Issue> issues) {
    final result = issues.where((issue) {
      switch (_filter) {
        case _RequestFilter.all:
          return true;
        case _RequestFilter.newIssue:
          return issue.status == IssueStatus.newIssue;
        case _RequestFilter.inProgress:
          return issue.status == IssueStatus.inProgress;
        case _RequestFilter.resolved:
          return issue.status == IssueStatus.resolved ||
              issue.status == IssueStatus.closed;
        case _RequestFilter.stale:
          return issue.isStale;
        case _RequestFilter.needsAssignment:
          return issue.needsAdminAssignment;
      }
    }).toList();

    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  Future<void> _changeStatus(
    Issue issue,
    IssueStatus status,
    bool isAr,
  ) async {
    String? note;
    String? photo;

    // عند الحل نطلب ملاحظة (اختيارية) من الموظف
    if (status == IssueStatus.resolved) {
      final input = await _askResolutionNote(isAr);
      note = input?.note;
      photo = input?.photo;

      if (input == null) {
        // المستخدم لغى: نرجّع القايمة للحالة القديمة
        if (mounted) setState(() => _dropdownEpoch++);
        return;
      }
    }

    updateIssueStatus(issue.id, status, note: note, photo: photo);

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _tr(isAr, 'تم تحديث حالة البلاغ', 'Request status updated'),
          ),
        ),
      );
  }

  Future<_ResolutionInput?> _askResolutionNote(bool isAr) {
    final controller = TextEditingController();
    final picker = ImagePicker();
    Uint8List? photoBytes;

    return showDialog<_ResolutionInput>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pick(ImageSource source) async {
              try {
                final file = await picker.pickImage(
                  source: source,
                  maxWidth: 800,
                  maxHeight: 800,
                  imageQuality: 45,
                );
                if (file == null) return;
                final bytes = await file.readAsBytes();
                setDialogState(() => photoBytes = bytes);
              } catch (_) {
                // لو الكاميرا أو المعرض مفتحوش نكمل من غير صورة
              }
            }

            return Directionality(
              textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
              child: AlertDialog(
                title: Text(_tr(isAr, 'ملاحظة بعد الحل', 'Resolution note')),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: controller,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: InputDecoration(
                          hintText: _tr(
                            isAr,
                            'اكتب ملاحظة عن اللي اتعمل (اختياري)',
                            'Describe what was done (optional)',
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (photoBytes != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                photoBytes!,
                                height: 140,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            PositionedDirectional(
                              top: 6,
                              end: 6,
                              child: GestureDetector(
                                onTap: () =>
                                    setDialogState(() => photoBytes = null),
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFBA1A1A),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => pick(ImageSource.camera),
                                icon: const Icon(Icons.photo_camera_outlined),
                                label: Text(_tr(isAr, 'كاميرا', 'Camera')),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => pick(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: Text(_tr(isAr, 'معرض', 'Gallery')),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),
                      Text(
                        _tr(isAr, 'صورة بعد الإصلاح (اختياري)',
                            'After-fix photo (optional)'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(_tr(isAr, 'إلغاء', 'Cancel')),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(
                      dialogContext,
                      _ResolutionInput(
                        controller.text.trim(),
                        photoBytes == null ? null : base64Encode(photoBytes!),
                      ),
                    ),
                    child: Text(_tr(isAr, 'تأكيد الحل', 'Confirm')),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(controller.dispose);
  }

  String _statusText(IssueStatus status, bool isAr) {
    switch (status) {
      case IssueStatus.newIssue:
        return _tr(isAr, 'جديد', 'New');
      case IssueStatus.inProgress:
        return _tr(isAr, 'قيد المعالجة', 'In progress');
      case IssueStatus.resolved:
        return _tr(isAr, 'تم الحل', 'Resolved');
      case IssueStatus.closed:
        return _tr(isAr, 'مغلق', 'Closed');
    }
  }

  Color _statusColor(IssueStatus status) {
    switch (status) {
      case IssueStatus.newIssue:
        return _blue;
      case IssueStatus.inProgress:
        return const Color(0xFFD97706);
      case IssueStatus.resolved:
        return const Color(0xFF059669);
      case IssueStatus.closed:
        return const Color(0xFF64748B);
    }
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
                _tr(isAr, 'إدارة البلاغات', 'Manage Requests'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
            ),
            body: SafeArea(
              child: ValueListenableBuilder<List<Issue>>(
                valueListenable: issuesNotifier,
                builder: (context, issues, _) {
                  final shown = _filterIssues(issues);

                  final newCount = issues
                      .where((i) =>
                          i.status == IssueStatus.newIssue)
                      .length;

                  final progressCount = issues
                      .where((i) =>
                          i.status == IssueStatus.inProgress)
                      .length;

                  final resolvedCount = issues
                      .where((i) =>
                          i.status == IssueStatus.resolved ||
                          i.status == IssueStatus.closed)
                      .length;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        _buildSummary(
                          isAr,
                          issues.length,
                          newCount,
                          progressCount,
                          resolvedCount,
                        ),
                        const SizedBox(height: 22),
                        Text(
                          _tr(
                            isAr,
                            'طلبات المواطنين',
                            'Citizen Requests',
                          ),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildFilters(
                          isAr,
                          issues.length,
                          newCount,
                          progressCount,
                          resolvedCount,
                        ),
                        const SizedBox(height: 16),
                        if (shown.isEmpty)
                          _buildEmptyState(isAr)
                        else
                          ...shown.map(
                            (issue) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 12),
                              child: _buildRequestCard(
                                issue,
                                isAr,
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

  Widget _buildSummary(
    bool isAr,
    int total,
    int newCount,
    int progressCount,
    int resolvedCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _tr(isAr, 'ملخص البلاغات', 'Requests Overview'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryItem(
                total.toString(),
                _tr(isAr, 'الإجمالي', 'Total'),
              ),
              _summaryItem(
                newCount.toString(),
                _tr(isAr, 'جديدة', 'New'),
              ),
              _summaryItem(
                progressCount.toString(),
                _tr(isAr, 'قيد العمل', 'In progress'),
              ),
              _summaryItem(
                resolvedCount.toString(),
                _tr(isAr, 'مكتملة', 'Done'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String number, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(
    bool isAr,
    int total,
    int newCount,
    int progressCount,
    int resolvedCount,
  ) {
    final filters = [
      _RequestFilter.all,
      _RequestFilter.newIssue,
      _RequestFilter.inProgress,
      _RequestFilter.resolved,
      _RequestFilter.stale,
      _RequestFilter.needsAssignment,
    ];

    final staleCount = issuesNotifier.value.where((i) => i.isStale).length;
    final needsAssignmentCount =
        issuesNotifier.value.where((i) => i.needsAdminAssignment).length;

    final labels = [
      '${_tr(isAr, 'الكل', 'All')} ($total)',
      '${_tr(isAr, 'جديدة', 'New')} ($newCount)',
      '${_tr(isAr, 'قيد المعالجة', 'In progress')} ($progressCount)',
      '${_tr(isAr, 'تم الحل', 'Resolved')} ($resolvedCount)',
      '${_tr(isAr, 'واقفة', 'Stalled')} ($staleCount)',
      '${_tr(isAr, 'محتاجة إسناد', 'Needs assignment')} ($needsAssignmentCount)',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          final selected = _filter == filters[index];

          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(labels[index]),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _filter = filters[index];
                });
              },
              selectedColor: AppColors.navy,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: selected ? Colors.white : _textDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(
                color: selected
                    ? AppColors.navy
                    : const Color(0xFFE2E8F0),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRequestCard(Issue issue, bool isAr) {
    final color = _statusColor(issue.status);

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.tintSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _typeIcon(issue.type),
                  color: AppColors.navy,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tr(isAr, issue.titleAr, issue.titleEn),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_tr(isAr, 'بلاغ', 'Request')} #${issue.shortId}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusText(issue.status, isAr),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            issue.description.isEmpty
                ? _tr(isAr, 'لا يوجد وصف', 'No description')
                : issue.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _tr(isAr, issue.locationAr, issue.locationEn),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 5),
              Text(
                '${issue.date.day}/${issue.date.month}/${issue.date.year}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if (issue.isStale) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_bottom,
                      size: 16, color: Color(0xFFB45309)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _tr(
                        isAr,
                        'واقف من ${issue.staleDays} أيام من غير حركة',
                        'No activity for ${issue.staleDays} days',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (issue.needsAdminAssignment) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_off_outlined,
                      size: 16, color: Color(0xFFB91C1C)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _tr(
                        isAr,
                        'محتاج إسناد: حوّله لقسم أو لموظف',
                        'Needs assignment: move it to a department or employee',
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 22),
          Text(
            _tr(isAr, 'تحديث حالة البلاغ', 'Update request status'),
            style: const TextStyle(
              color: _textDark,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<IssueStatus>(
            key: ValueKey('${issue.id}_${issue.status.name}_$_dropdownEpoch'),
            value: issue.status,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0),
                ),
              ),
            ),
            items: IssueStatus.values.map((status) {
              return DropdownMenuItem<IssueStatus>(
                value: status,
                child: Text(
                  _statusText(status, isAr),
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (status) {
              if (status != null && status != issue.status) {
                _changeStatus(issue, status, isAr);
              }
            },
          ),
          if (currentUserRole == 'admin') ...[
            const SizedBox(height: 12),
            Text(
              _tr(isAr, 'القسم المسؤول', 'Responsible department'),
              style: const TextStyle(
                color: _textDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey('${issue.id}_dept_${issue.department}'),
              value: [...employeeDepartments, 'admin']
                      .contains(issue.department)
                  ? issue.department
                  : 'admin',
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              items: [
                for (final key in [...employeeDepartments, 'admin'])
                  DropdownMenuItem<String>(
                    value: key,
                    child: Text(
                      departmentLabel(key, isAr),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value == null || value == issue.department) return;

                updateIssueDepartment(issue.id, value);

                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        _tr(isAr, 'تم تحويل البلاغ للقسم', 'Request moved'),
                      ),
                    ),
                  );
              },
            ),
            if (issue.department != 'admin') ...[
              const SizedBox(height: 12),
              Text(
                _tr(isAr, 'الموظف المكلّف', 'Assigned employee'),
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _AssigneePicker(issue: issue, isAr: isAr),
            ],
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IssueDetailsScreen(issue: issue),
                ),
              );
            },
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: Text(
              _tr(isAr, 'عرض تفاصيل البلاغ', 'View Request Details'),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: const BorderSide(color: AppColors.navy),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _typeIcon(IssueType type) {
    switch (type) {
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

  Widget _buildEmptyState(bool isAr) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 45,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 12),
          Text(
            _tr(isAr, 'لا توجد بلاغات', 'No requests found'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _tr(
              isAr,
              'لا توجد بلاغات في هذا التصنيف حالياً',
              'There are no requests in this category',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}


// ======================================================================
// قايمة اختيار الموظف المكلّف بالبلاغ (للأدمن): موظفو قسم البلاغ النشطين
// ======================================================================
class _AssigneePicker extends StatefulWidget {
  const _AssigneePicker({required this.issue, required this.isAr});

  final Issue issue;
  final bool isAr;

  @override
  State<_AssigneePicker> createState() => _AssigneePickerState();
}

class _AssigneePickerState extends State<_AssigneePicker> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;

  Stream<QuerySnapshot<Map<String, dynamic>>> _buildStream() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'employee')
        .where('department', isEqualTo: widget.issue.department)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _stream = _buildStream();
  }

  @override
  void didUpdateWidget(covariant _AssigneePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.issue.department != widget.issue.department) {
      _stream = _buildStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    final issue = widget.issue;
    final isAr = widget.isAr;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        // uid -> اسم، للموظفين النشطين في القسم
        final employees = <String, String>{};

        for (final doc in snapshot.data?.docs ?? const []) {
          final data = doc.data();
          if (data['active'] == false) continue;
          employees[doc.id] = (data['name'] ?? '') as String;
        }

        // لو المكلّف الحالي مش في القايمة (موقوف مثلاً) نعرضه برضه
        if (issue.assignedTo.isNotEmpty &&
            !employees.containsKey(issue.assignedTo)) {
          employees[issue.assignedTo] = issue.assignedToName;
        }

        return DropdownButtonFormField<String>(
          key: ValueKey(
            '${issue.id}_assignee_${issue.assignedTo}_${employees.length}',
          ),
          value: issue.assignedTo,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: '',
              child: Text(
                _tr(isAr, 'غير مسند (كل موظفي القسم)',
                    'Unassigned (whole department)'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            for (final entry in employees.entries)
              DropdownMenuItem<String>(
                value: entry.key,
                child: Text(
                  entry.value.isEmpty ? entry.key : entry.value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
          onChanged: (value) {
            if (value == null || value == issue.assignedTo) return;

            updateIssueAssignment(
              issue.id,
              employeeUid: value,
              employeeName: value.isEmpty ? '' : (employees[value] ?? ''),
            );

            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    _tr(isAr, 'تم تحديث الموظف المكلّف',
                        'Assignee updated'),
                  ),
                ),
              );
          },
        );
      },
    );
  }
}
