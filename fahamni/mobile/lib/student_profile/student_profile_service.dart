import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/student_model.dart';

class StudentProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<StudentModel> getStudentData() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    final doc = await _db.collection('students').doc(user.uid).get();
    if (!doc.exists || doc.data() == null) throw Exception('Student not found');
    return StudentModel.fromMap(doc.data()!);
  }

  Future<void> updateProfile(Map<String, dynamic> fields) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    await _db.collection('students').doc(user.uid).update(fields);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    if (user.email == null) throw Exception('No email on this account');

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    if (user.email == null) throw Exception('No email on this account');

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);

    final uid = user.uid;
    final batch = _db.batch();
    batch.delete(_db.collection('students').doc(uid));
    batch.delete(_db.collection('users').doc(uid));
    await batch.commit();

    await user.delete();
    try { await _googleSignIn.signOut(); } catch (_) {}
  }

  Future<int> getSessionCount(List<String> courseIds) async {
    return courseIds.length;
  }
}


