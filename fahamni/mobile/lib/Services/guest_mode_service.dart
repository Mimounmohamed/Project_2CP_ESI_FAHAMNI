import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fahamni/models/user_model.dart';

/// Service to handle guest mode checks for pending teachers.
class GuestModeService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Check if the current teacher is in guest mode (pending approval).
  /// Returns true if teacher account is pending, false otherwise.
  static Future<bool> isTeacherInGuestMode() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final userDoc = await _db.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return false;

      final role = userDoc['role'] as String? ?? 'student';
      if (role != 'tutor') return false;

      final accountStatus = userDoc['account_status'] as String? ?? 'pending';
      return accountStatus == 'pending';
    } catch (_) {
      return false;
    }
  }

  /// Get the account status of the current user.
  static Future<AccountStatus?> getCurrentUserAccountStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userDoc = await _db.collection('users').doc(user.uid).get();
      if (!userDoc.exists) return null;

      final statusStr = userDoc['account_status'] as String? ?? 'pending';
      return AccountStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => AccountStatus.pending,
      );
    } catch (_) {
      return null;
    }
  }

  /// Stream to monitor if user's guest status changes (for real-time updates).
  static Stream<bool> streamIsTeacherInGuestMode() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(false);
    }

    return _db.collection('users').doc(user.uid).snapshots().map((doc) {
      if (!doc.exists) return false;
      final role = doc['role'] as String? ?? 'student';
      if (role != 'tutor') return false;
      final accountStatus = doc['account_status'] as String? ?? 'pending';
      return accountStatus == 'pending';
    });
  }
}
