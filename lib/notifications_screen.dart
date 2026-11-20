
import 'package:flutter/material.dart';

import 'app_lang.dart';
import 'issues_store.dart';
import 'issue_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color navy = Color(0xFF0F2942);
  static const Color background = Color(0xFFF0F4F8);
  static const Color secondary = Color(0xFF64748B);

  bool showUnreadOnly = false;

  String tr(String ar, String en, bool isAr) =>
      isAr ? ar : en;

  int get unreadCount => getUnreadNotificationsCount();

  Issue? findIssue(String id) {
    try {
      return issuesNotifier.value.firstWhere(
        (issue) => issue.id == id,
      );
    } catch (_) {
      return null;
    }
  }

  Color notificationColor(AppNotification notification) {
    if (notification.type == AppNotificationType.newReport) {
      return const Color(0xFF2563EB);
    }

    switch (notification.newStatus) {
      case IssueStatus.newIssue:
        return const Color(0xFF2563EB);
      case IssueStatus.inProgress:
        return const Color(0xFFD97706);
      case IssueStatus.resolved:
        return const Color(0xFF16A34A);
      case IssueStatus.closed:
        return const Color(0xFF64748B);
      case null:
        return navy;
    }
  }

  IconData notificationIcon(AppNotification notification) {
    if (notification.type == AppNotificationType.newReport) {
      return Icons.assignment_turned_in_outlined;
    }

    switch (notification.newStatus) {
      case IssueStatus.newIssue:
        return Icons.fiber_new_outlined;
      case IssueStatus.inProgress:
        return Icons.pending_actions;
      case IssueStatus.resolved:
        return Icons.check_circle_outline;
      case IssueStatus.closed:
        return Icons.lock_outline;
      case null:
        return Icons.notifications_outlined;
    }
  }

  String statusName(IssueStatus? status, bool isAr) {
    switch (status) {
      case IssueStatus.newIssue:
        return tr('جديد', 'New', isAr);
      case IssueStatus.inProgress:
        return tr('قيد المعالجة', 'In Progress', isAr);
      case IssueStatus.resolved:
        return tr('تم الحل', 'Resolved', isAr);
      case IssueStatus.closed:
        return tr('مغلق', 'Closed', isAr);
      case null:
        return tr('غير محدد', 'Not specified', isAr);
    }
  }

  String notificationTitle(
    AppNotification notification,
    bool isAr,
  ) {
    if (notification.type == AppNotificationType.newReport) {
      return tr(
        'تم استلام بلاغك بنجاح',
        'Your report was received',
        isAr,
      );
    }

    if (notification.newStatus == IssueStatus.resolved) {
      return tr(
        'تم حل المشكلة',
        'Issue resolved',
        isAr,
      );
    }

    if (notification.newStatus == IssueStatus.closed) {
      return tr(
        'تم إغلاق البلاغ',
        'Report closed',
        isAr,
      );
    }

    return tr(
      'تحديث حالة البلاغ',
      'Report status updated',
      isAr,
    );
  }

  String notificationBody(
    AppNotification notification,
    Issue? issue,
    bool isAr,
  ) {
    final id = notification.issueId;

    if (notification.type == AppNotificationType.newReport) {
      return tr(
        'تم تسجيل بلاغك رقم #$id بنجاح وسيتم مراجعته.',
        'Your report #$id has been registered successfully and will be reviewed.',
        isAr,
      );
    }

    final oldStatus = statusName(notification.oldStatus, isAr);
    final newStatus = statusName(notification.newStatus, isAr);

    return tr(
      'تم تحديث حالة البلاغ رقم #$id من "$oldStatus" إلى "$newStatus".',
      'Report #$id status changed from "$oldStatus" to "$newStatus".',
      isAr,
    );
  }

  String relativeDate(DateTime date, bool isAr) {
    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) {
      return tr('الآن', 'Just now', isAr);
    }

    if (difference.inMinutes < 60) {
      return isAr
          ? 'منذ ${difference.inMinutes} دقيقة'
          : '${difference.inMinutes} minutes ago';
    }

    if (difference.inHours < 24) {
      return isAr
          ? 'منذ ${difference.inHours} ساعة'
          : '${difference.inHours} hours ago';
    }

    if (difference.inDays == 1) {
      return tr('أمس', 'Yesterday', isAr);
    }

    if (difference.inDays < 7) {
      return isAr
          ? 'منذ ${difference.inDays} أيام'
          : '${difference.inDays} days ago';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  List<AppNotification> displayedNotifications(
    List<AppNotification> notifications,
  ) {
    final result = notifications.where((notification) {
      if (showUnreadOnly) return !notification.read;
      return true;
    }).toList();

    result.sort((a, b) => b.date.compareTo(a.date));

    return result;
  }

  void markAsRead(String id) {
    markNotificationAsRead(id);
  }

  void markAllAsRead() {
    markAllNotificationsAsRead();
  }

  Future<void> deleteAllConfirmation(bool isAr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection:
              isAr ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(
              tr('حذف الإشعارات', 'Clear Notifications', isAr),
            ),
            content: Text(
              tr(
                'هل تريد حذف جميع الإشعارات؟',
                'Do you want to delete all notifications?',
                isAr,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, false),
                child: Text(tr('إلغاء', 'Cancel', isAr)),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, true),
                child: Text(
                  tr('حذف', 'Delete', isAr),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true) {
      clearAllNotifications();
    }
  }

  void showNotificationDetails(
    AppNotification notification,
    bool isAr,
  ) {
    markAsRead(notification.id);

    final issue = findIssue(notification.issueId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Directionality(
          textDirection:
              isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 45,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Text(
                    notificationTitle(notification, isAr),
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    notificationBody(
                      notification,
                      issue,
                      isAr,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: secondary,
                      height: 1.8,
                    ),
                  ),

                  const SizedBox(height: 15),

                  if (issue != null) ...[
                    Text(
                      '${tr('اسم البلاغ:', 'Report:', isAr)} ${isAr ? issue.titleAr : issue.titleEn}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${tr('الموقع:', 'Location:', isAr)} ${isAr ? issue.locationAr : issue.locationEn}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${tr('الحالة الحالية:', 'Current status:', isAr)} ${statusName(issue.status, isAr)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: secondary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 15),

                  Text(
                    relativeDate(notification.date, isAr),
                    style: const TextStyle(
                      color: secondary,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 25),

                  if (issue != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  IssueDetailsScreen(issue: issue),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: navy,
                          padding: const EdgeInsets.all(14),
                        ),
                        child: Text(
                          tr('عرض تفاصيل البلاغ', 'View issue details', isAr),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(14),
                      ),
                      child: Text(
                        tr('إغلاق', 'Close', isAr),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
            backgroundColor: background,
            body: SafeArea(
              child: ValueListenableBuilder<List<AppNotification>>(
                valueListenable: notificationsNotifier,
                builder: (context, notifications, _) {
                  final unread = notifications
                      .where((n) => !n.read)
                      .length;

                  final displayed =
                      displayedNotifications(notifications);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isAr),

                        const SizedBox(height: 25),

                        _buildSummary(unread, isAr),

                        const SizedBox(height: 22),

                        _buildFilters(
                          notifications.isNotEmpty,
                          isAr,
                        ),

                        const SizedBox(height: 18),

                        if (displayed.isEmpty)
                          _buildEmptyState(isAr)
                        else
                          ...displayed.map(
                            (notification) =>
                                _notificationCard(
                              notification,
                              isAr,
                            ),
                          ),

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

  // ======================================================
  // HEADER
  // ======================================================

  Widget _buildHeader(bool isAr) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                tr('الإشعارات', 'Notifications', isAr),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: navy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr(
                  'تابع آخر التحديثات والتنبيهات الخاصة بك',
                  'Stay updated with your latest alerts',
                  isAr,
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: secondary,
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
            Icons.notifications_none,
            color: navy,
            size: 27,
          ),
        ),
      ],
    );
  }

  // ======================================================
  // SUMMARY
  // ======================================================

  Widget _buildSummary(int unread, bool isAr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  tr(
                    'الإشعارات غير المقروءة',
                    'Unread Notifications',
                    isAr,
                  ),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          if (unread > 0)
            TextButton(
              onPressed: markAllAsRead,
              child: Text(
                tr('قراءة الكل', 'Read All', isAr),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ======================================================
  // FILTERS
  // ======================================================

  Widget _buildFilters(
    bool hasNotifications,
    bool isAr,
  ) {
    return Row(
      children: [
        Expanded(
          child: _filterButton(
            tr('الكل', 'All', isAr),
            !showUnreadOnly,
            () {
              setState(() => showUnreadOnly = false);
            },
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _filterButton(
            tr('غير المقروء', 'Unread', isAr),
            showUnreadOnly,
            () {
              setState(() => showUnreadOnly = true);
            },
          ),
        ),

        const SizedBox(width: 5),

        IconButton(
          tooltip: tr('حذف الكل', 'Clear All', isAr),
          onPressed: hasNotifications
              ? () => deleteAllConfirmation(isAr)
              : null,
          icon: const Icon(
            Icons.delete_outline,
            color: Color(0xFFDC2626),
          ),
        ),
      ],
    );
  }

  Widget _filterButton(
    String title,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? navy : Colors.white,
          borderRadius: BorderRadius.circular(13),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : secondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ======================================================
  // NOTIFICATION CARD
  // ======================================================

  Widget _notificationCard(
    AppNotification notification,
    bool isAr,
  ) {
    final read = notification.read;
    final color = notificationColor(notification);
    final issue = findIssue(notification.issueId);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: read ? Colors.white : const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: read
              ? const Color(0xFFE2E8F0)
              : const Color(0xFFCBDCEC),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: () =>
            showNotificationDetails(notification, isAr),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  notificationIcon(notification),
                  color: color,
                  size: 25,
                ),
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notificationTitle(
                              notification,
                              isAr,
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: navy,
                            ),
                          ),
                        ),

                        if (!read)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 7),

                    Text(
                      notificationBody(
                        notification,
                        issue,
                        isAr,
                      ),
                      style: const TextStyle(
                        color: secondary,
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 13,
                          color: secondary,
                        ),

                        const SizedBox(width: 5),

                        Expanded(
                          child: Text(
                            relativeDate(
                              notification.date,
                              isAr,
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              color: secondary,
                            ),
                          ),
                        ),

                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.more_horiz,
                            color: secondary,
                          ),
                          onSelected: (value) {
                            if (value == 'read') {
                              markAsRead(notification.id);
                            } else if (value == 'delete') {
                              deleteNotification(
                                notification.id,
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            if (!read)
                              PopupMenuItem(
                                value: 'read',
                                child: Text(
                                  tr(
                                    'تحديد كمقروء',
                                    'Mark as read',
                                    isAr,
                                  ),
                                ),
                              ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                tr('حذف', 'Delete', isAr),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================================
  // EMPTY STATE
  // ======================================================

  Widget _buildEmptyState(bool isAr) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_off_outlined,
            size: 55,
            color: Color(0xFF94A3B8),
          ),

          const SizedBox(height: 15),

          Text(
            tr('لا توجد إشعارات', 'No Notifications', isAr),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: navy,
            ),
          ),

          const SizedBox(height: 7),

          Text(
            tr(
              showUnreadOnly
                  ? 'لا توجد إشعارات غير مقروءة.'
                  : 'ستظهر هنا الإشعارات والتحديثات الجديدة.',
              showUnreadOnly
                  ? 'There are no unread notifications.'
                  : 'New notifications and updates will appear here.',
              isAr,
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: secondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
