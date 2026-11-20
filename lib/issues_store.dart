
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ======================================================
// ISSUE MODELS
// ======================================================

enum IssueStatus {
  newIssue,
  inProgress,
  resolved,
  closed,
}

enum IssueType {
  roads,
  sanitation,
  lighting,
  water,
  gardens,
  other,
}

String issueTypeLabel(IssueType t, bool isAr) {
  switch (t) {
    case IssueType.roads:
      return isAr ? 'طرق وشوارع وأرصفة' : 'Roads, streets & sidewalks';

    case IssueType.sanitation:
      return isAr ? 'نظافة' : 'Cleanliness';

    case IssueType.lighting:
      return isAr ? 'إنارة الشوارع' : 'Street lighting';

    case IssueType.water:
      return isAr ? 'مياه وصرف' : 'Water & sewage';

    case IssueType.gardens:
      return isAr ? 'حدائق ومساحات خضراء' : 'Gardens & green areas';

    case IssueType.other:
      return isAr ? 'أخرى' : 'Other';
  }
}

// القسم المسؤول عن كل نوع (للإسناد التلقائي بعدين)
String issueTypeDepartment(IssueType t) {
  switch (t) {
    case IssueType.roads:
      return 'roads';
    case IssueType.sanitation:
      return 'sanitation';
    case IssueType.lighting:
      return 'electricity';
    case IssueType.water:
      return 'water';
    case IssueType.gardens:
      return 'gardens';
    case IssueType.other:
      return 'admin'; // الأدمن يحوّلها بإيده
  }
}

// الأقسام اللي الموظف ممكن يتبعها
const List<String> employeeDepartments = [
  'roads',
  'sanitation',
  'electricity',
  'water',
  'gardens',
];

String departmentLabel(String key, bool isAr) {
  switch (key) {
    case 'roads':
      return isAr ? 'قسم الطرق والصيانة' : 'Roads & Maintenance';
    case 'sanitation':
      return isAr ? 'قسم النظافة' : 'Sanitation';
    case 'electricity':
      return isAr ? 'قسم الكهرباء والإنارة' : 'Electricity & Lighting';
    case 'water':
      return isAr ? 'قسم المياه والصرف' : 'Water & Sewage';
    case 'gardens':
      return isAr ? 'قسم الحدائق' : 'Gardens';
    case 'admin':
      return isAr ? 'الأدمن' : 'Admin';
    default:
      return key;
  }
}

// ======================================================
// حدود الاستخدام
// ======================================================

// أقصى عدد بلاغات للمواطن الواحد في اليوم
const int maxIssuesPerDay = 5;

// بعد كام يوم من غير حركة نعتبر البلاغ "واقف"
const int staleAfterDays = 3;

// ======================================================
// ISSUE MODEL
// ======================================================

class Issue {
  const Issue({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.locationAr,
    required this.locationEn,
    required this.date,
    required this.status,
    required this.type,
    this.description = '',
    this.pending = false,
    this.ownerUid = '',
    this.department = '',
    this.resolutionNote = '',
    this.photos = const [],
    this.resolutionPhoto = '',
    this.assignedTo = '',
    this.assignedToName = '',
    this.needsAssignment = false,
    this.updatedAt,
    this.lat,
    this.lng,
  });

  // رقم المستند في Firebase
  final String id;

  final String titleAr;
  final String titleEn;

  final String locationAr;
  final String locationEn;

  final DateTime date;

  final IssueStatus status;
  final IssueType type;

  final String description;

  // true = لسه ما اتبعتتش للسيرفر (مفيش نت)
  final bool pending;

  final String ownerUid;

  // القسم المسؤول عن البلاغ
  final String department;

  // ملاحظة الموظف بعد الحل
  final String resolutionNote;

  // صور البلاغ (كل صورة نص base64 مضغوط)
  final List<String> photos;

  // صورة الموظف بعد الإصلاح (base64)
  final String resolutionPhoto;

  // الموظف المكلّف بالبلاغ (فاضي = لسه ما اتسندش لحد بعينه)
  final String assignedTo;
  final String assignedToName;

  // true = الموظف المسؤول اتوقف، والبلاغ مستني الأدمن يسنده لحد تاني
  final bool needsAssignment;

  // آخر مرة حصل فيها تحديث على البلاغ (حالة، إسناد، تحويل...)
  final DateTime? updatedAt;

  // إحداثيات مكان المشكلة (لو المواطن حدّدها على الخريطة أو بالـ GPS)
  final double? lat;
  final double? lng;

  bool get hasCoordinates => lat != null && lng != null;

  // البلاغ "محتاج إسناد" من الأدمن: لسه مفتوح، وإما الموظف المسؤول اتوقف
  // أو النوع "أخرى" (قسمه admin) ومحدش حوّله لقسم لسه
  bool get needsAdminAssignment {
    if (status == IssueStatus.resolved || status == IssueStatus.closed) {
      return false;
    }
    return needsAssignment || department == 'admin';
  }

  // البلاغ "واقف": لسه مفتوح ومحدش اتحرك فيه من أيام
  bool get isStale {
    if (status == IssueStatus.resolved || status == IssueStatus.closed) {
      return false;
    }
    if (pending) return false;
    return staleDays >= staleAfterDays;
  }

  // بقاله كام يوم من غير حركة
  int get staleDays =>
      DateTime.now().difference(updatedAt ?? date).inDays;

  // رقم قصير يظهر للمستخدم
  String get shortId =>
      id.length <= 6 ? id.toUpperCase() : id.substring(0, 6).toUpperCase();

  factory Issue.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final type = IssueType.values.firstWhere(
      (t) => t.name == data['type'],
      orElse: () => IssueType.other,
    );

    final status = IssueStatus.values.firstWhere(
      (st) => st.name == data['status'],
      orElse: () => IssueStatus.newIssue,
    );

    final created = data['createdAt'];
    final location = (data['location'] ?? '') as String;

    return Issue(
      id: doc.id,
      titleAr: issueTypeLabel(type, true),
      titleEn: issueTypeLabel(type, false),
      locationAr: location,
      locationEn: location,
      date: created is Timestamp ? created.toDate() : DateTime.now(),
      status: status,
      type: type,
      description: (data['description'] ?? '') as String,
      pending: doc.metadata.hasPendingWrites,
      ownerUid: (data['ownerUid'] ?? '') as String,
      department:
          (data['department'] ?? issueTypeDepartment(type)) as String,
      resolutionNote: (data['resolutionNote'] ?? '') as String,
      photos: data['photos'] is List
          ? (data['photos'] as List).whereType<String>().toList()
          : const [],
      resolutionPhoto: (data['resolutionPhoto'] ?? '') as String,
      assignedTo: (data['assignedTo'] ?? '') as String,
      assignedToName: (data['assignedToName'] ?? '') as String,
      needsAssignment: data['needsAssignment'] == true,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
    );
  }
}

// ======================================================
// NOTIFICATION MODEL
// ======================================================

enum AppNotificationType {
  newReport,
  statusChanged,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.issueId,
    required this.type,
    required this.date,
    this.read = false,
    this.oldStatus,
    this.newStatus,
  });

  final String id;
  final String issueId;

  final AppNotificationType type;

  final DateTime date;

  final bool read;

  final IssueStatus? oldStatus;
  final IssueStatus? newStatus;

  AppNotification copyWith({
    bool? read,
  }) {
    return AppNotification(
      id: id,
      issueId: issueId,
      type: type,
      date: date,
      read: read ?? this.read,
      oldStatus: oldStatus,
      newStatus: newStatus,
    );
  }
}

// ======================================================
// CENTRAL ISSUE STORE (بيقرا من Firebase)
// ======================================================

final ValueNotifier<List<Issue>> issuesNotifier =
    ValueNotifier<List<Issue>>([]);

StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _issuesSub;

CollectionReference<Map<String, dynamic>> get _issuesCol =>
    FirebaseFirestore.instance.collection('issues');

// نبدأ نسمع للبلاغات بعد تسجيل الدخول
// المواطن: بلاغاته هو بس. الموظف: بلاغات قسمه بس. الأدمن: الكل
int _syncGeneration = 0;

// دور المستخدم الحالي (citizen / employee / admin)
String currentUserRole = '';

void _subscribeTo(
  Query<Map<String, dynamic>> query, {
  bool Function(Issue issue)? keep,
}) {
  _issuesSub = query.snapshots(includeMetadataChanges: true).listen(
    (snapshot) {
      var list = snapshot.docs.map(Issue.fromDoc).toList();
      if (keep != null) list = list.where(keep).toList();
      list.sort((x, y) => y.date.compareTo(x.date));
      issuesNotifier.value = list;
    },
    onError: (Object e) {
      debugPrint('issues sync error: $e');
    },
  );
}

Future<void> _startEmployeeSync(String uid, int generation) async {
  try {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    // لو المستخدم خرج أو دخل بحساب تاني وإحنا مستنيين، نلغي
    if (generation != _syncGeneration) return;

    final department = doc.data()?['department'];

    if (department is! String || department.isEmpty) return;

    // الموظف يشوف: البلاغات المسندة له + اللي لسه ما اتسندتش لحد في قسمه
    _subscribeTo(
      _issuesCol.where('department', isEqualTo: department),
      keep: (issue) =>
          !issue.needsAssignment &&
          (issue.assignedTo.isEmpty || issue.assignedTo == uid),
    );
  } catch (e) {
    debugPrint('employee sync error: $e');
  }
}

void startIssuesSync(String role) {
  stopIssuesSync();
  currentUserRole = role;

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final generation = _syncGeneration;

  if (role == 'employee') {
    _startEmployeeSync(uid, generation);
    return;
  }

  if (role == 'citizen') {
    _subscribeTo(_issuesCol.where('ownerUid', isEqualTo: uid));
    _subscribeToNotifications(uid);
    return;
  }

  // الأدمن
  _subscribeTo(_issuesCol);
}

// نوقف السماع ونمسح البيانات عند تسجيل الخروج
void stopIssuesSync() {
  _syncGeneration++;
  currentUserRole = '';
  _issuesSub?.cancel();
  _issuesSub = null;
  _notificationsSub?.cancel();
  _notificationsSub = null;
  issuesNotifier.value = [];
  notificationsNotifier.value = [];
}

// ======================================================
// CENTRAL NOTIFICATION STORE
// ======================================================

final ValueNotifier<List<AppNotification>> notificationsNotifier =
    ValueNotifier<List<AppNotification>>([]);

StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
    _notificationsSub;

CollectionReference<Map<String, dynamic>> get _notificationsCol =>
    FirebaseFirestore.instance.collection('notifications');

IssueStatus? _statusFromName(Object? name) {
  for (final status in IssueStatus.values) {
    if (status.name == name) return status;
  }
  return null;
}

// المواطن بيسمع لإشعاراته هو بس (بتتحفظ في Firebase)
void _subscribeToNotifications(String uid) {
  _notificationsSub =
      _notificationsCol.where('ownerUid', isEqualTo: uid).snapshots().listen(
    (snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        final createdAt = data['createdAt'];

        return AppNotification(
          id: doc.id,
          issueId: (data['issueId'] ?? '') as String,
          type: data['type'] == 'statusChanged'
              ? AppNotificationType.statusChanged
              : AppNotificationType.newReport,
          date: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
          read: data['read'] == true,
          oldStatus: _statusFromName(data['oldStatus']),
          newStatus: _statusFromName(data['newStatus']),
        );
      }).toList();

      list.sort((x, y) => y.date.compareTo(x.date));
      notificationsNotifier.value = list;
    },
    onError: (Object e) {
      debugPrint('notifications sync error: $e');
    },
  );
}

// الإشعار بيتكتب في Firebase باسم صاحب البلاغ، فيوصله على جهازه هو
void _addNotification({
  required String ownerUid,
  required String issueId,
  required AppNotificationType type,
  IssueStatus? oldStatus,
  IssueStatus? newStatus,
}) {
  if (ownerUid.isEmpty) return;

  _notificationsCol.doc().set({
    'ownerUid': ownerUid,
    'issueId': issueId,
    'type': type.name,
    'oldStatus': oldStatus?.name,
    'newStatus': newStatus?.name,
    'read': false,
    'createdAt': FieldValue.serverTimestamp(),
  }).catchError((Object e) {
    debugPrint('addNotification error: $e');
  });
}

// ======================================================
// ADD NEW ISSUE
// ======================================================

// كام بلاغ المواطن سجّله النهارده (بنعدّ من بلاغاته اللي على الجهاز)
int issuesCreatedToday() {
  final now = DateTime.now();

  return issuesNotifier.value.where((issue) {
    return issue.date.year == now.year &&
        issue.date.month == now.month &&
        issue.date.day == now.day;
  }).length;
}

bool get hasReachedDailyLimit => issuesCreatedToday() >= maxIssuesPerDay;

Issue addIssue({
  required IssueType type,
  required String description,
  required String location,
  List<String> photos = const [],
  double? lat,
  double? lng,
}) {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    throw StateError('Not signed in');
  }

  final ref = _issuesCol.doc();

  // مش بنستنى الرد: لو مفيش نت Firebase بيحفظها ويبعتها لوحده بعدين
  ref.set({
    'type': type.name,
    'department': issueTypeDepartment(type),
    'description': description,
    'location': location,
    'assignedTo': '',
    'assignedToName': '',
    if (lat != null && lng != null) ...{'lat': lat, 'lng': lng},
    if (photos.isNotEmpty) 'photos': photos,
    'status': IssueStatus.newIssue.name,
    'ownerUid': uid,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }).catchError((Object e) {
    debugPrint('addIssue error: $e');
  });

  // إشعار تلقائي عند تقديم بلاغ جديد
  _addNotification(
    ownerUid: uid,
    issueId: ref.id,
    type: AppNotificationType.newReport,
    newStatus: IssueStatus.newIssue,
  );

  return Issue(
    id: ref.id,
    titleAr: issueTypeLabel(type, true),
    titleEn: issueTypeLabel(type, false),
    locationAr: location,
    locationEn: location,
    date: DateTime.now(),
    status: IssueStatus.newIssue,
    type: type,
    description: description,
    pending: true,
    ownerUid: uid,
    photos: photos,
    lat: lat,
    lng: lng,
  );
}

// ======================================================
// UPDATE ISSUE STATUS
// ======================================================

void updateIssueStatus(
  String issueId,
  IssueStatus newStatus, {
  String? note,
  String? photo,
}) {
  final current = issuesNotifier.value;

  final index = current.indexWhere(
    (issue) => issue.id == issueId,
  );

  if (index == -1) return;

  final oldIssue = current[index];

  // عدم التحديث إذا لم تتغير الحالة
  if (oldIssue.status == newStatus) return;

  final trimmedNote = note?.trim() ?? '';

  _issuesCol.doc(issueId).update({
    'status': newStatus.name,
    'updatedAt': FieldValue.serverTimestamp(),
    if (trimmedNote.isNotEmpty) 'resolutionNote': trimmedNote,
    if (photo != null && photo.isNotEmpty) 'resolutionPhoto': photo,
  }).catchError((Object e) {
    debugPrint('updateIssueStatus error: $e');
  });

  // إشعار تلقائي عند تغيير حالة البلاغ
  _addNotification(
    ownerUid: oldIssue.ownerUid,
    issueId: issueId,
    type: AppNotificationType.statusChanged,
    oldStatus: oldIssue.status,
    newStatus: newStatus,
  );
}

// ======================================================
// MOVE ISSUE TO ANOTHER DEPARTMENT (الأدمن بس)
// ======================================================

void updateIssueDepartment(String issueId, String department) {
  _issuesCol.doc(issueId).update({
    'department': department,
    // لما البلاغ يتحول لقسم تاني، التكليف القديم بيتلغي
    'assignedTo': '',
    'assignedToName': '',
    'needsAssignment': false,
    'updatedAt': FieldValue.serverTimestamp(),
  }).catchError((Object e) {
    debugPrint('updateIssueDepartment error: $e');
  });
}

// ======================================================
// ASSIGN ISSUE TO A SPECIFIC EMPLOYEE (الأدمن بس)
// employeeUid فاضي = إلغاء التكليف
// ======================================================

void updateIssueAssignment(
  String issueId, {
  required String employeeUid,
  required String employeeName,
}) {
  _issuesCol.doc(issueId).update({
    'assignedTo': employeeUid,
    'assignedToName': employeeName,
    'needsAssignment': false,
    'updatedAt': FieldValue.serverTimestamp(),
  }).catchError((Object e) {
    debugPrint('updateIssueAssignment error: $e');
  });
}

// ======================================================
// لما الأدمن يوقف موظف: بلاغاته المفتوحة بتتحوّل لقايمة "محتاجة إسناد"
// بترجّع عدد البلاغات اللي اتحوّلت
// ======================================================

Future<int> releaseEmployeeIssues(String employeeUid) async {
  final snapshot =
      await _issuesCol.where('assignedTo', isEqualTo: employeeUid).get();

  final open = snapshot.docs.where((doc) {
    final status = doc.data()['status'];
    return status == IssueStatus.newIssue.name ||
        status == IssueStatus.inProgress.name;
  }).toList();

  // Firestore بيقبل 500 تعديل في الدفعة الواحدة، فبنقسم
  for (var i = 0; i < open.length; i += 400) {
    final batch = FirebaseFirestore.instance.batch();

    for (final doc in open.skip(i).take(400)) {
      batch.update(doc.reference, {
        'assignedTo': '',
        'assignedToName': '',
        'needsAssignment': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  return open.length;
}

// ======================================================
// NOTIFICATION MANAGEMENT
// ======================================================

int getUnreadNotificationsCount() {
  return notificationsNotifier.value
      .where((notification) => !notification.read)
      .length;
}

void markNotificationAsRead(String notificationId) {
  _notificationsCol.doc(notificationId).update({'read': true}).catchError(
    (Object e) {
      debugPrint('markNotificationAsRead error: $e');
    },
  );
}

void markAllNotificationsAsRead() {
  final batch = FirebaseFirestore.instance.batch();
  var count = 0;

  for (final notification in notificationsNotifier.value) {
    if (notification.read) continue;
    batch.update(_notificationsCol.doc(notification.id), {'read': true});
    count++;
  }

  if (count == 0) return;

  batch.commit().catchError((Object e) {
    debugPrint('markAllNotificationsAsRead error: $e');
  });
}

void deleteNotification(String notificationId) {
  _notificationsCol.doc(notificationId).delete().catchError((Object e) {
    debugPrint('deleteNotification error: $e');
  });
}

void clearAllNotifications() {
  final all = notificationsNotifier.value;
  if (all.isEmpty) return;

  final batch = FirebaseFirestore.instance.batch();

  for (final notification in all) {
    batch.delete(_notificationsCol.doc(notification.id));
  }

  batch.commit().catchError((Object e) {
    debugPrint('clearAllNotifications error: $e');
  });
}
