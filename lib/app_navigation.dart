import 'package:flutter/material.dart';

import 'admin_dashboard_screen.dart';
import 'auth_service.dart';
import 'citizen_home_screen.dart';
import 'issues_store.dart';
import 'employee_dashboard_screen.dart';
import 'role_selection_screen.dart';

// نوع المستخدم
enum UserRole { citizen, employee, admin }

// بعد تسجيل الدخول: افتح الصفحة الرئيسية حسب النوع
// وامسح كل الصفحات اللي قبلها (Welcome / Role / Login)
void openHomeForRole(BuildContext context, UserRole role) {
  // نبدأ نقرا البلاغات من Firebase حسب الدور
  startIssuesSync(role.name);

  final Widget home;

  switch (role) {
    case UserRole.citizen:
      home = const CitizenHomeScreen();
      break;
    case UserRole.employee:
      home = const EmployeeDashboardScreen();
      break;
    case UserRole.admin:
      home = const AdminDashboardScreen();
      break;
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => home),
    (route) => false,
  );
}

// تسجيل الخروج: رجوع لاختيار النوع (نفس السلوك للكل)
void logoutToRoleSelection(BuildContext context) {
  stopIssuesSync();
  AuthService.signOut();

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
    (route) => false,
  );
}