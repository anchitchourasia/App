import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SessionUser {
  final String name;
  final String ec;
  final String department;
  final String designation;
  final String category;
  final String role;

  const SessionUser({
    required this.name,
    required this.ec,
    required this.department,
    required this.designation,
    required this.category,
    this.role = 'EMPLOYEE',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'ec': ec,
    'department': department,
    'designation': designation,
    'category': category,
    'role': role,
  };

  static SessionUser fromJson(Map<String, dynamic> j) => SessionUser(
    name: _firstText([
      j['name'],
      j['empName'],
      j['employeeName'],
      j['EMP_NAME'],
      j['EMPNAME'],
    ]),
    ec: _firstText([
      j['ec'],
      j['empNo'],
      j['employeeCode'],
      j['employeeId'],
      j['EMP_NO'],
    ]),
    department: _firstText([
      j['department'],
      j['departmentName'],
      j['dept'],
      j['deptName'],
      j['DEPARTMENT'],
      j['DEPT'],
    ]),
    designation: _firstText([
      j['designation'],
      j['designationName'],
      j['jobTitle'],
      j['desig'],
      j['DESIGNATION'],
    ]),
    category: _firstText([
      j['category'],
      j['employeeCategory'],
      j['userCategory'],
      j['empCategory'],
    ]),
    role: _firstText([
      j['role'],
      j['userRole'],
      j['ROLE'],
    ], fallback: 'EMPLOYEE'),
  );

  static String _firstText(List<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';

      if (text.isNotEmpty &&
          text.toUpperCase() != 'NULL' &&
          text.toUpperCase() != 'N/A') {
        return text;
      }
    }

    return fallback;
  }
}

class SessionStore {
  static const _kUserId = 'session_user_id';
  static const _kIsAdmin = 'session_is_admin';
  static const _kUserJson = 'session_user_json';

  static SessionUser? currentUser;
  static String? currentUserId;
  static bool isAdmin = false;

  // ─── NEW getters for Chat feature ──────────────────────────────
  /// Returns the logged-in user's ID (used by ChatBubbleButton)
  static String? get employeeId => currentUserId;

  /// Returns the logged-in user's display name (used by ChatBubbleButton)
  static String? get employeeName => currentUser?.name;

  /// True only for the real technical chat administrator.
  /// An APPROVER must use normal Admin Support chat.
  /// Only the designated support/admin account can access the employee inbox.
  /// An APPROVER is not a chat administrator, even if SessionStore.isAdmin is true.
  static bool get isChatAdmin {
    final userId = (currentUserId ?? '').trim().toLowerCase();

    // Replace/add actual official admin account IDs if required.
    const chatAdminIds = <String>{'admin'};

    return chatAdminIds.contains(userId);
  }

  /// Normal users—including APPROVER—send messages to Admin Support.
  static String get chatReceiverId => isChatAdmin ? 'all' : 'admin';
  // ───────────────────────────────────────────────────────────────

  // Call this once at app start
  static Future<void> loadFromDisk() async {
    final sp = await SharedPreferences.getInstance();
    currentUserId = sp.getString(_kUserId);
    isAdmin = sp.getBool(_kIsAdmin) ?? false;

    final userJson = sp.getString(_kUserJson);
    if (userJson != null && userJson.trim().isNotEmpty) {
      try {
        currentUser = SessionUser.fromJson(
          jsonDecode(userJson) as Map<String, dynamic>,
        );
      } catch (_) {
        currentUser = null;
      }
    }
  }

  // Call this after successful login
  static Future<void> saveLogin({
    required String userId,
    required bool admin,
    SessionUser? user,
  }) async {
    currentUserId = userId;
    isAdmin = admin;
    currentUser = user;

    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUserId, userId);
    await sp.setBool(_kIsAdmin, admin);
    if (user != null) {
      await sp.setString(_kUserJson, jsonEncode(user.toJson()));
    } else {
      await sp.remove(_kUserJson);
    }
  }

  static Future<void> logout() async {
    currentUser = null;
    currentUserId = null;
    isAdmin = false;

    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kUserId);
    await sp.remove(_kIsAdmin);
    await sp.remove(_kUserJson);
  }

  static bool get isLoggedIn =>
      (currentUserId != null && currentUserId!.isNotEmpty);
}
