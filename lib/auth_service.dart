import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'app_lang.dart';
import 'app_navigation.dart';

// خطأ بنعرض رسالته للمستخدم مباشرة
class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

String _roleName(UserRole role) {
  switch (role) {
    case UserRole.citizen:
      return tr('المواطن', 'citizen');
    case UserRole.employee:
      return tr('الموظف', 'employee');
    case UserRole.admin:
      return tr('الأدمن', 'admin');
  }
}

// تحويل أكواد Firebase لرسائل مفهومة
String _authMessage(String code) {
  switch (code) {
    case 'invalid-email':
      return tr('البريد الإلكتروني غير صحيح', 'The email address is not valid');
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return tr(
        'البريد الإلكتروني أو كلمة السر غير صحيحة',
        'Incorrect email or password',
      );
    case 'email-already-in-use':
      return tr(
        'هذا البريد الإلكتروني مسجّل بالفعل',
        'This email is already registered',
      );
    case 'weak-password':
      return tr('كلمة السر ضعيفة (6 حروف على الأقل)', 'The password is too weak');
    case 'user-disabled':
      return tr('تم إيقاف هذا الحساب', 'This account has been disabled');
    case 'too-many-requests':
      return tr(
        'محاولات كتير غلط. استنى شوية وجرّب تاني',
        'Too many attempts. Please try again later',
      );
    case 'network-request-failed':
      return tr('مفيش اتصال بالإنترنت', 'No internet connection');
    default:
      return tr('حصلت مشكلة. جرّب تاني', 'Something went wrong. Try again');
  }
}

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // إنشاء حساب مواطن جديد
  static Future<void> signUpCitizen({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    UserCredential credential;

    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authMessage(e.code));
    }

    final user = credential.user!;

    try {
      await _db.collection('users').doc(user.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': 'citizen',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // لو الحفظ فشل نمسح الحساب عشان ميبقاش ناقص
      try {
        await user.delete();
      } catch (_) {}
      throw AuthException(
        tr('تعذر حفظ بيانات الحساب. جرّب تاني', 'Could not save the account data. Try again'),
      );
    }
  }

  // الأدمن بيعمل حساب موظف جديد
  // بنستخدم نسخة Firebase تانية عشان الأدمن ميتسجلش خروج
  static Future<void> createEmployee({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String department,
  }) async {
    FirebaseApp secondary;

    try {
      secondary = Firebase.app('employeeCreator');
    } catch (_) {
      secondary = await Firebase.initializeApp(
        name: 'employeeCreator',
        options: Firebase.app().options,
      );
    }

    final secondaryAuth = FirebaseAuth.instanceFor(app: secondary);

    UserCredential credential;

    try {
      credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authMessage(e.code));
    }

    final newUser = credential.user!;

    try {
      // الكتابة بتتم بحساب الأدمن (النسخة الأساسية)
      await _db.collection('users').doc(newUser.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': 'employee',
        'department': department,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      try {
        await newUser.delete();
      } catch (_) {}
      await secondaryAuth.signOut();
      throw AuthException(
        tr('تعذر حفظ بيانات الموظف. جرّب تاني', 'Could not save the employee data. Try again'),
      );
    }

    await secondaryAuth.signOut();
  }

  // تسجيل الدخول مع التأكد إن الحساب مطابق للدور المختار
  static Future<void> signIn({
    required String email,
    required String password,
    required UserRole expectedRole,
  }) async {
    UserCredential credential;

    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authMessage(e.code));
    }

    final uid = credential.user!.uid;
    Map<String, dynamic>? data;

    try {
      final snapshot = await _db.collection('users').doc(uid).get();
      data = snapshot.data();
    } catch (_) {
      await _auth.signOut();
      throw AuthException(
        tr('تعذر قراءة بيانات الحساب. جرّب تاني', 'Could not read the account data. Try again'),
      );
    }

    if (data == null) {
      await _auth.signOut();
      throw AuthException(
        tr('هذا الحساب غير مكتمل. تواصل مع الإدارة', 'This account is incomplete. Contact the admin'),
      );
    }

    if (data['active'] == false) {
      await _auth.signOut();
      throw AuthException(tr('تم إيقاف هذا الحساب', 'This account has been disabled'));
    }

    if (data['role'] != expectedRole.name) {
      await _auth.signOut();
      throw AuthException(
        tr(
          'هذا الحساب ليس حساب ${_roleName(expectedRole)}',
          'This account is not a ${_roleName(expectedRole)} account',
        ),
      );
    }
  }

  // رابط استعادة كلمة السر على الإيميل
  static Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_authMessage(e.code));
    }
  }

  static Future<void> signOut() => _auth.signOut();
}