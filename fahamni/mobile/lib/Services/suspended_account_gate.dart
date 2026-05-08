import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fahamni/Account_Settings_Parent/account_screen.dart';
import 'package:fahamni/Account_Settings_Student/account_screen.dart'
    as student_account;
import 'package:fahamni/Account_Settings_Teacher/account_screen.dart'
    as teacher_account;
import 'package:fahamni/models/user_model.dart';

class SuspendedAccountGate extends StatelessWidget {
  const SuspendedAccountGate({super.key, required this.child});

  final Widget child;

  static Widget accountScreenForRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        return const student_account.AccountScreen(suspendedMode: true);
      case UserRole.parent:
        return const ParentAccountScreen(suspendedMode: true);
      case UserRole.tutor:
        return const teacher_account.AccountScreen(suspendedMode: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return child;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data();
        final role = UserModel.parseRole(userData?['role']);
        final roleDoc = FirebaseFirestore.instance
            .collection(_collectionForRole(role))
            .doc(user.uid);

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: roleDoc.snapshots(),
          builder: (context, profileSnapshot) {
            final profileData = profileSnapshot.data?.data();
            final isSuspended =
                profileData?['is_suspended'] == true ||
                userData?['is_suspended'] == true;
            if (isSuspended) {
              return accountScreenForRole(role);
            }
            return child;
          },
        );
      },
    );
  }

  static String _collectionForRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'students';
      case UserRole.tutor:
        return 'tutors';
      case UserRole.parent:
        return 'parents';
    }
  }
}
