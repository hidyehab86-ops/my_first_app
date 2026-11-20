
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'app_lang.dart';
import 'issues_store.dart';
import 'location_picker_screen.dart';
import 'main.dart';

class IssueDetailsScreen extends StatelessWidget {
  final Issue issue;

  const IssueDetailsScreen({
    super.key,
    required this.issue,
  });

  // صور البلاغ: مصغّرة، والضغط على الصورة يكبّرها
  Widget _photosGrid(BuildContext context, List<String> photos) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: photos.map((p) {
          final bytes = base64Decode(p);
          return GestureDetector(
            onTap: () => showDialog<void>(
              context: context,
              builder: (_) => Dialog(
                backgroundColor: Colors.black,
                insetPadding: const EdgeInsets.all(12),
                child: InteractiveViewer(
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                bytes,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // خريطة صغيرة بمكان البلاغ، والضغط عليها يفتحها كاملة
  Widget _locationMap(BuildContext context, Issue issue, bool isAr) {
    final point = LatLng(issue.lat!, issue.lng!);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 180,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: 16,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                  onTap: (tapPosition, latLng) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LocationPickerScreen(
                          initial: point,
                          readOnly: true,
                        ),
                      ),
                    );
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: mapTileUrl,
                    userAgentPackageName: mapUserAgent,
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFBA1A1A),
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(
                    text: '${issue.lat!.toStringAsFixed(6)}, '
                        '${issue.lng!.toStringAsFixed(6)}',
                  ),
                );
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        tr(isAr, 'تم نسخ الإحداثيات', 'Coordinates copied'),
                      ),
                    ),
                  );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: Text(tr(isAr, 'نسخ الإحداثيات', 'Copy coordinates')),
            ),
          ),
        ],
      ),
    );
  }

  String tr(bool isAr, String ar, String en) {
    return isAr ? ar : en;
  }

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

  String statusText(IssueStatus status, bool isAr) {
    switch (status) {
      case IssueStatus.newIssue:
        return tr(isAr, 'جديد', 'New');
      case IssueStatus.inProgress:
        return tr(isAr, 'قيد المعالجة', 'In Progress');
      case IssueStatus.resolved:
        return tr(isAr, 'تم الحل', 'Resolved');
      case IssueStatus.closed:
        return tr(isAr, 'مغلق', 'Closed');
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

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, lang, _) {
        final isAr = lang == 'ar';

        return Directionality(
          textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
          child: ValueListenableBuilder<List<Issue>>(
            valueListenable: issuesNotifier,
            builder: (context, issues, _) {
              final currentIssue = issues.firstWhere(
                (item) => item.id == issue.id,
                orElse: () => issue,
              );

              return Scaffold(
                backgroundColor: AppColors.surface,
                appBar: AppBar(
                  backgroundColor: AppColors.surface,
                  elevation: 0,
                  foregroundColor: const Color(0xFF0F2942),
                  title: Text(
                    tr(isAr, 'تفاصيل البلاغ', 'Issue Details'),
                  ),
                ),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 75,
                              height: 75,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEBF1F6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                typeIcon(currentIssue.type),
                                size: 38,
                                color: const Color(0xFF0F2942),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              isAr
                                  ? currentIssue.titleAr
                                  : currentIssue.titleEn,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F2942),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '#${currentIssue.shortId}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor(currentIssue.status)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Text(
                                statusText(currentIssue.status, isAr),
                                style: TextStyle(
                                  color: statusColor(currentIssue.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _infoCard(
                        isAr,
                        tr(isAr, 'معلومات البلاغ', 'Report Information'),
                        [
                          _infoRow(
                            Icons.location_on_outlined,
                            tr(isAr, 'الموقع', 'Location'),
                            isAr
                                ? currentIssue.locationAr
                                : currentIssue.locationEn,
                          ),
                          _infoRow(
                            Icons.calendar_today_outlined,
                            tr(isAr, 'تاريخ البلاغ', 'Report Date'),
                            '${currentIssue.date.day}/${currentIssue.date.month}/${currentIssue.date.year}',
                          ),
                          _infoRow(
                            Icons.category_outlined,
                            tr(isAr, 'نوع المشكلة', 'Issue Type'),
                            issueTypeLabel(currentIssue.type, isAr),
                          ),
                          if (currentUserRole != 'citizen')
                            _infoRow(
                              Icons.person_outline,
                              tr(isAr, 'الموظف المكلّف', 'Assigned to'),
                              currentIssue.assignedToName.isEmpty
                                  ? tr(isAr, 'لم يُسند بعد', 'Not assigned yet')
                                  : currentIssue.assignedToName,
                            ),
                        ],
                      ),

                      if (currentIssue.hasCoordinates) ...[
                        const SizedBox(height: 20),
                        _infoCard(
                          isAr,
                          tr(isAr, 'الموقع على الخريطة', 'Map location'),
                          [_locationMap(context, currentIssue, isAr)],
                        ),
                      ],

                      const SizedBox(height: 20),

                      _infoCard(
                        isAr,
                        tr(isAr, 'وصف المشكلة', 'Issue Description'),
                        [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              currentIssue.description.isEmpty
                                  ? tr(
                                      isAr,
                                      'لا يوجد وصف إضافي',
                                      'No additional description',
                                    )
                                  : currentIssue.description,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.7,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (currentIssue.photos.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _infoCard(
                          isAr,
                          tr(isAr, 'صور البلاغ', 'Report Photos'),
                          [_photosGrid(context, currentIssue.photos)],
                        ),
                      ],

                      if (currentIssue.resolutionPhoto.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _infoCard(
                          isAr,
                          tr(isAr, 'صورة بعد الإصلاح', 'After-fix photo'),
                          [_photosGrid(context, [currentIssue.resolutionPhoto])],
                        ),
                      ],

                      if (currentIssue.resolutionNote.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _infoCard(
                          isAr,
                          tr(isAr, 'ملاحظة الموظف', 'Employee note'),
                          [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                currentIssue.resolutionNote,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.7,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 25),

                      SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(
                            tr(
                              isAr,
                              'العودة إلى بلاغاتي',
                              'Back to My Issues',
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F2942),
                            side: const BorderSide(
                              color: Color(0xFF0F2942),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _infoCard(
    bool isAr,
    String title,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F2942),
            ),
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF64748B),
            size: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
