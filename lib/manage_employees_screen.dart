
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'app_lang.dart';
import 'auth_service.dart';
import 'issues_store.dart';
import 'main.dart';

// ======================================================
// Manage Employees Screen
// ======================================================

class ManageEmployeesScreen extends StatefulWidget {
  const ManageEmployeesScreen({super.key});

  @override
  State<ManageEmployeesScreen> createState() =>
      _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState
    extends State<ManageEmployeesScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  final List<_Employee> _employees = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _employeesSub;

  @override
  void initState() {
    super.initState();

    // قايمة الموظفين بتتقرا من Firebase
    _employeesSub = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'employee')
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;

        setState(() {
          _employees
            ..clear()
            ..addAll(snapshot.docs.map((doc) {
              final data = doc.data();
              return _Employee(
                uid: doc.id,
                name: (data['name'] ?? '') as String,
                email: (data['email'] ?? '') as String,
                phone: (data['phone'] ?? '') as String,
                department: (data['department'] ?? '') as String,
                active: data['active'] != false,
              );
            }));
        });
      },
      onError: (Object e) {
        debugPrint('employees list error: $e');
      },
    );
  }

  String _searchText = '';

  bool get _isAr => appLang.value == 'ar';

  String _tr(String ar, String en) => _isAr ? ar : en;

  List<_Employee> get _filteredEmployees {
    if (_searchText.trim().isEmpty) return _employees;

    final query = _searchText.toLowerCase();

    return _employees.where((employee) {
      return employee.name.toLowerCase().contains(query) ||
          employee.email.toLowerCase().contains(query) ||
          departmentLabel(employee.department, _isAr)
              .toLowerCase()
              .contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _employeesSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // ---------- Add Employee ----------
  void _showAddEmployeeDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    String department = employeeDepartments.first;
    bool saving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (innerContext, setDialogState) {
            return AlertDialog(
              title: Text(_tr('إضافة موظف جديد', 'Add New Employee')),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogField(
                      nameController,
                      _tr('اسم الموظف', 'Employee Name'),
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 12),
                    _dialogField(
                      emailController,
                      _tr('البريد الإلكتروني', 'Email Address'),
                      Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _dialogField(
                      phoneController,
                      _tr('رقم الهاتف', 'Phone Number'),
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _dialogField(
                      passwordController,
                      _tr('كلمة السر (6 حروف على الأقل)',
                          'Password (min 6 characters)'),
                      Icons.lock_outline,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: department,
                      decoration: InputDecoration(
                        labelText: _tr('القسم', 'Department'),
                        prefixIcon: const Icon(Icons.business_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: [
                        for (final key in employeeDepartments)
                          DropdownMenuItem<String>(
                            value: key,
                            child: Text(departmentLabel(key, _isAr)),
                          ),
                      ],
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value == null) return;
                              setDialogState(() => department = value);
                            },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      saving ? null : () => Navigator.pop(dialogContext),
                  child: Text(_tr('إلغاء', 'Cancel')),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: saving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final email = emailController.text.trim();
                          final phone = phoneController.text.trim();
                          final password = passwordController.text;

                          if (name.isEmpty ||
                              email.isEmpty ||
                              password.isEmpty) {
                            _showSnack(
                              _tr(
                                'يرجى إدخال الاسم والبريد وكلمة السر',
                                'Please enter name, email and password',
                              ),
                            );
                            return;
                          }

                          if (!email.contains('@')) {
                            _showSnack(
                              _tr(
                                'البريد الإلكتروني غير صحيح',
                                'The email address is not valid',
                              ),
                            );
                            return;
                          }

                          if (password.length < 6) {
                            _showSnack(
                              _tr(
                                'كلمة السر لازم تكون 6 حروف على الأقل',
                                'Password must be at least 6 characters',
                              ),
                            );
                            return;
                          }

                          setDialogState(() => saving = true);

                          try {
                            await AuthService.createEmployee(
                              name: name,
                              email: email,
                              phone: phone,
                              password: password,
                              department: department,
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            _showSnack(
                              _tr('تمت إضافة الموظف', 'Employee added'),
                            );
                          } on AuthException catch (e) {
                            setDialogState(() => saving = false);
                            _showSnack(e.message);
                          } catch (_) {
                            setDialogState(() => saving = false);
                            _showSnack(
                              _tr(
                                'حصلت مشكلة. جرّب تاني',
                                'Something went wrong. Try again',
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_tr('إضافة', 'Add')),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameController.dispose();
      emailController.dispose();
      phoneController.dispose();
      passwordController.dispose();
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _dialogField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ---------- Suspend / Activate Employee ----------
  void _toggleActive(_Employee employee) {
    final suspending = employee.active;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            suspending
                ? _tr('إيقاف الحساب', 'Suspend Account')
                : _tr('تفعيل الحساب', 'Activate Account'),
          ),
          content: Text(
            suspending
                ? _tr(
                    'هل أنت متأكد من إيقاف حساب ${employee.name}؟ مش هيقدر يدخل التطبيق.',
                    'Suspend ${employee.name}? They will not be able to sign in.',
                  )
                : _tr(
                    'هل تريد تفعيل حساب ${employee.name}؟',
                    'Activate ${employee.name}?',
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(_tr('إلغاء', 'Cancel')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(employee.uid)
                      .update({'active': !employee.active});
                } catch (e) {
                  debugPrint('toggle active error: $e');
                  _showSnack(
                    _tr('تعذر تحديث الحساب', 'Could not update the account'),
                  );
                  return;
                }

                // عند الإيقاف: بلاغاته المفتوحة تروح لقايمة "محتاجة إسناد"
                if (!suspending) return;

                try {
                  final released = await releaseEmployeeIssues(employee.uid);

                  if (released > 0) {
                    _showSnack(
                      _tr(
                        'اتحوّل $released بلاغ لقايمة \"محتاجة إسناد\"',
                        '$released request(s) moved to \"Needs assignment\"',
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('release issues error: $e');
                  _showSnack(
                    _tr(
                      'اتوقف الحساب، لكن تعذر تحويل بلاغاته. حوّلها بإيدك',
                      'Account suspended, but its requests could not be moved. Reassign them manually',
                    ),
                  );
                }
              },
              child: Text(
                suspending ? _tr('إيقاف', 'Suspend') : _tr('تفعيل', 'Activate'),
                style: TextStyle(
                  color: suspending ? Colors.red : AppColors.navy,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------- Employee Details ----------
  void _showEmployeeDetails(_Employee employee) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(employee.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow(Icons.email_outlined, employee.email),
              const SizedBox(height: 12),
              _detailRow(
                Icons.phone_outlined,
                employee.phone.isEmpty
                    ? _tr('غير محدد', 'Not provided')
                    : employee.phone,
              ),
              const SizedBox(height: 12),
              _detailRow(
                Icons.business_outlined,
                departmentLabel(employee.department, _isAr),
              ),
              const SizedBox(height: 12),
              _detailRow(
                employee.active
                    ? Icons.check_circle_outline
                    : Icons.block,
                employee.active
                    ? _tr('الحساب مفعّل', 'Account active')
                    : _tr('الحساب موقوف', 'Account suspended'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(_tr('إغلاق', 'Close')),
            ),
          ],
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.navy, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(value)),
      ],
    );
  }

  // ---------- Employee Card ----------
  Widget _employeeCard(_Employee employee) {
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.containerLow,
              child: Icon(
                Icons.person,
                color: AppColors.navy,
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _showEmployeeDetails(employee),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.email,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      departmentLabel(employee.department, _isAr) +
                          (employee.active
                              ? ''
                              : _tr(' • موقوف', ' • Suspended')),
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: employee.active
                  ? _tr('إيقاف الحساب', 'Suspend')
                  : _tr('تفعيل الحساب', 'Activate'),
              onPressed: () => _toggleActive(employee),
              icon: Icon(
                employee.active
                    ? Icons.block
                    : Icons.check_circle_outline,
                color: employee.active ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Main Screen ----------
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLang,
      builder: (context, language, child) {
        return Directionality(
          textDirection:
              language == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              title: Text(
                _tr('إدارة الموظفين', 'Manage Employees'),
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      _tr('الموظفون', 'Employees'),
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _tr(
                        'عرض وإدارة بيانات موظفي النظام',
                        'View and manage system employees',
                      ),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Total Employees
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.navy,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.groups_outlined,
                            color: Colors.white,
                            size: 35,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              _tr(
                                'إجمالي الموظفين',
                                'Total Employees',
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Text(
                            '${_employees.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Search
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchText = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: _tr(
                          'ابحث عن موظف...',
                          'Search employees...',
                        ),
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _tr('قائمة الموظفين', 'Employees List'),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_filteredEmployees.length}',
                          style: TextStyle(
                            color: AppColors.navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Employees List
                    Expanded(
                      child: _filteredEmployees.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 60,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchText.isEmpty
                                        ? _tr(
                                            'لا يوجد موظفون حتى الآن',
                                            'No employees added yet',
                                          )
                                        : _tr(
                                            'لا توجد نتائج للبحث',
                                            'No search results',
                                          ),
                                    style: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredEmployees.length,
                              itemBuilder: (context, index) {
                                return _employeeCard(
                                  _filteredEmployees[index],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Add Button
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _showAddEmployeeDialog,
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(_tr('إضافة موظف', 'Add Employee')),
            ),
          ),
        );
      },
    );
  }
}

// ======================================================
// Employee Model
// ======================================================

class _Employee {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String department;
  final bool active;

  _Employee({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.active,
  });
}
