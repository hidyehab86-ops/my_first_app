import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app_lang.dart';
import 'main.dart';

// ======================================================
// MANAGE USERS SCREEN (المواطنين) - مربوطة بـ Firestore
// ======================================================

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<_CitizenUser> _users = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSub;

  bool _loading = true;
  bool _hasError = false;
  String _searchText = '';

  bool get _isAr => appLang.value == 'ar';

  String _tr(String ar, String en) => _isAr ? ar : en;

  @override
  void initState() {
    super.initState();

    // قايمة المواطنين بتتقرا من Firebase
    _usersSub = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'citizen')
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;

        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          return _CitizenUser(
            uid: doc.id,
            name: (data['name'] ?? '') as String,
            email: (data['email'] ?? '') as String,
            phone: (data['phone'] ?? '') as String,
            active: data['active'] != false,
          );
        }).toList()
          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        setState(() {
          _users
            ..clear()
            ..addAll(list);
          _loading = false;
          _hasError = false;
        });
      },
      onError: (Object e) {
        debugPrint('users list error: $e');
        if (!mounted) return;
        setState(() {
          _loading = false;
          _hasError = true;
        });
      },
    );
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<_CitizenUser> get _filteredUsers {
    final q = _searchText.trim().toLowerCase();
    if (q.isEmpty) return _users;

    return _users.where((user) {
      return user.name.toLowerCase().contains(q) ||
          user.email.toLowerCase().contains(q) ||
          user.phone.contains(q);
    }).toList();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------- إيقاف / تفعيل حساب مواطن ----------
  void _toggleActive(_CitizenUser user) {
    final suspending = user.active;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Directionality(
          textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text(
              suspending
                  ? _tr('إيقاف الحساب', 'Suspend Account')
                  : _tr('تفعيل الحساب', 'Activate Account'),
            ),
            content: Text(
              suspending
                  ? _tr(
                      'هل أنت متأكد من إيقاف حساب ${user.name}؟ مش هيقدر يدخل التطبيق.',
                      'Suspend ${user.name}? They will not be able to sign in.',
                    )
                  : _tr(
                      'هل تريد تفعيل حساب ${user.name}؟',
                      'Activate ${user.name}?',
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(_tr('إلغاء', 'Cancel')),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);

                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'active': !user.active}).catchError((Object e) {
                    debugPrint('toggle citizen active error: $e');
                    _showSnack(
                      _tr('تعذر تحديث الحساب', 'Could not update the account'),
                    );
                  });
                },
                child: Text(
                  suspending
                      ? _tr('إيقاف', 'Suspend')
                      : _tr('تفعيل', 'Activate'),
                  style: TextStyle(
                    color: suspending ? Colors.red : AppColors.navy,
                  ),
                ),
              ),
            ],
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
        final filtered = _filteredUsers;

        return Directionality(
          textDirection: _isAr ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              title: Text(_tr('إدارة المستخدمين', 'Manage Users')),
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _searchText = value),
                    decoration: InputDecoration(
                      hintText: _tr(
                        'ابحث بالاسم أو الإيميل أو الموبايل',
                        'Search by name, email or phone',
                      ),
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildBody(filtered)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(List<_CitizenUser> filtered) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _tr('تعذر تحميل المستخدمين', 'Could not load users'),
            style: const TextStyle(color: AppColors.slateSecondary),
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _users.isEmpty
                ? _tr('لا يوجد مواطنون مسجلون بعد', 'No citizens registered yet')
                : _tr('لا توجد نتائج', 'No results'),
            style: const TextStyle(color: AppColors.slateSecondary),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _userCard(filtered[index]),
    );
  }

  Widget _userCard(_CitizenUser user) {
    final statusColor =
        user.active ? const Color(0xFF15803D) : const Color(0xFFB91C1C);

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
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppColors.containerLow,
            child: Icon(Icons.person_outline, color: AppColors.navy),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isEmpty ? '-' : user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slateSecondary,
                  ),
                ),
                if (user.phone.isNotEmpty)
                  Text(
                    user.phone,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.slateSecondary,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  user.active
                      ? _tr('نشط', 'Active')
                      : _tr('موقوف', 'Suspended'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: user.active
                ? _tr('إيقاف الحساب', 'Suspend')
                : _tr('تفعيل الحساب', 'Activate'),
            icon: Icon(
              user.active ? Icons.block : Icons.check_circle_outline,
              color: statusColor,
            ),
            onPressed: () => _toggleActive(user),
          ),
        ],
      ),
    );
  }
}

class _CitizenUser {
  const _CitizenUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.active,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final bool active;
}
