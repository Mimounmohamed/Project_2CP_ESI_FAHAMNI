import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user_model.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/tutor_model.dart';
import '../models/student_model.dart';
import '../models/parent_model.dart';
import 'phone_auth_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
 
 
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
 
  // ---------------------------------------------------------------------------
  // FIXED: signUp now accepts an optional children list.
  // When the role is parent and children are provided, saveChildren() is called
  // immediately after the parent document is written — inside the same try block
  // so a failure rolls back cleanly (the auth account is deleted on error).
  // ---------------------------------------------------------------------------
  Future<UserModel?> signUp(
    String email,
    String password,
    UserModel usermodel, {
    List<Map<String, dynamic>> children = const [],
    List<PlatformFile>? certificationFiles,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final uid = credential.user!.uid;
 
      final Map<String, dynamic> data = usermodel.toMap();
      data['uid'] = uid;
      if (usermodel.role == UserRole.tutor && certificationFiles != null && certificationFiles.isNotEmpty) {
        final List<String> certUrls = await _uploadCertificationFiles(uid, certificationFiles);
        data['certification_url'] = certUrls.first;
        data['certification_urls'] = certUrls;
      }
 
      final collection = _collectionForRole(usermodel.role);
      await _db.collection(collection).doc(uid).set(data);
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'role': usermodel.role.name,
        'account_status': usermodel.accountStatus.name,
      });
 
      // Register children immediately after the parent document is created.
      if (usermodel.role == UserRole.parent && children.isNotEmpty) {
        await saveChildren(parentUid: uid, children: children);
      }
 
      return usermodel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      // Clean up the auth account if Firestore writes fail so there is no
      // orphaned Firebase Auth user without a matching Firestore document.
      try {
        await _auth.currentUser?.delete();
      } catch (_) {}
      throw 'Registration failed: ${e.toString()}';
    }
  }
 
  // ---------------------------------------------------------------------------
  // login — unchanged
  // ---------------------------------------------------------------------------
  Future<UserModel?> login(String emailOrPhone, String password) async {
    try {
      String email = emailOrPhone;
      if (!emailOrPhone.contains('@')) {
        final phone = emailOrPhone.startsWith('+')
            ? emailOrPhone
            : '+213${emailOrPhone.replaceAll(RegExp(r'[^0-9]'), '')}';
        email = await _getEmailFromPhone(phone);
      }
 
      final credential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      final uid = credential.user!.uid;

      late DocumentSnapshot<Map<String, dynamic>> userDoc;
      try {
        userDoc = await _db.collection('users').doc(uid).get();
      } catch (e) {
        throw Exception('Failed to load user record: $e');
      }

      if (!userDoc.exists) {
        throw Exception('No account profile found. Please sign up first.');
      }
      if ((userDoc['role'] ?? '') == 'admin') {
        await _auth.signOut();
        throw Exception('Admin accounts must use the web dashboard.');
      }
      final role = UserRole.values.firstWhere(
          (r) => r.name == (userDoc['role'] ?? 'student'),
          orElse: () => UserRole.student);

      late UserModel? userModel;
      try {
        userModel = await _fetchUserProfile(uid, role);
      } catch (e) {
        throw Exception('Failed to load profile data: $e');
      }

      if (userModel == null) {
        await _auth.signOut();
        throw Exception('Your registration was not completed. Please delete your account or contact support to sign up again.');
      }

      try {
        await _db.collection(_collectionForRole(role)).doc(uid).set({
          'last_login_date': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> _getEmailFromPhone(String phone) async {
    for (final collection in ['students', 'tutors', 'parents']) {
      final query = await _db
          .collection(collection)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return query.docs.first['email'] as String;
      }
    }
    throw 'No account found with this phone number.';
  }
 
  Future<UserModel?> _fetchUserProfile(String uid, UserRole role) async {
    final collection = _collectionForRole(role);
    final doc = await _db.collection(collection).doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    switch (role) {
      case UserRole.student:
        return StudentModel.fromMap(data);
      case UserRole.tutor:
        return TutorModel.fromMap(data);
      case UserRole.parent:
        return ParentModel.fromMap(data);
    }
  }
 
  String _collectionForRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'students';
      case UserRole.tutor:
        return 'tutors';
      case UserRole.parent:
        return 'parents';
    }
  }
 
  Future<String> _uploadCertificationFile(String uid, PlatformFile file) async {
    final String fileName = file.name;
    final Reference ref = FirebaseStorage.instance
        .ref()
        .child('tutor_certifications/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName');
    final metadata = SettableMetadata(contentType: _contentTypeForFile(fileName));

    UploadTask uploadTask;
    if (file.path != null && file.path!.isNotEmpty) {
      uploadTask = ref.putFile(File(file.path!), metadata);
    } else if (file.bytes != null) {
      uploadTask = ref.putData(file.bytes!, metadata);
    } else {
      throw Exception('Certification upload failed: file path and bytes are both unavailable.');
    }

    final TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<List<String>> _uploadCertificationFiles(String uid, List<PlatformFile> files) async {
    final urls = <String>[];
    for (final file in files) {
      urls.add(await _uploadCertificationFile(uid, file));
    }
    return urls;
  }

  String _contentTypeForFile(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }
 
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Invalid email format.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-verification-code':
        return 'Incorrect OTP code. Please try again.';
      case 'session-expired':
        return 'OTP expired. Please request a new code.';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
 
  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    await PhoneAuthService.sendOtp(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
      onAutoVerified: () {},
    );
  }
 
  // ---------------------------------------------------------------------------
  // FIXED: verifyOtpAndRegister also accepts children and saves them.
  // ---------------------------------------------------------------------------
  Future<UserModel> verifyOtpAndRegister({
    required String verificationId,
    required String smsCode,
    required String email,
    required String password,
    required UserModel userModel,
    List<Map<String, dynamic>> children = const [],
    List<PlatformFile>? certificationFiles,
  }) async {
    final phoneCredential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
 
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
 
    try {
      await credential.user!.linkWithCredential(phoneCredential);
    } on FirebaseAuthException catch (e) {
      await credential.user!.delete();
      throw _handleAuthError(e);
    }
 
    final data = userModel.toMap();
    data['uid'] = uid;
    if (userModel.role == UserRole.tutor && certificationFiles != null && certificationFiles.isNotEmpty) {
      final List<String> certUrls = await _uploadCertificationFiles(uid, certificationFiles);
      data['certification_url'] = certUrls.first;
      data['certification_urls'] = certUrls;
    }
    final collection = _collectionForRole(userModel.role);
    await _db.collection(collection).doc(uid).set(data);
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'role': userModel.role.name,
      'account_status': userModel.accountStatus.name,
    });
 
    // Register children for parent accounts.
    if (userModel.role == UserRole.parent && children.isNotEmpty) {
      await saveChildren(parentUid: uid, children: children);
    }
 
    return _buildModelWithUid(userModel, uid);
  }
 
  // ---------------------------------------------------------------------------
  // FIXED: registerAndSendEmailVerification also accepts children.
  // ---------------------------------------------------------------------------
  Future<void> registerAndSendEmailVerification({
    required String email,
    required String password,
    required UserModel userModel,
    List<Map<String, dynamic>> children = const [],
    List<PlatformFile>? certificationFiles,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      await credential.user!.sendEmailVerification();
 
      final data = userModel.toMap();
      data['uid'] = uid;
      if (userModel.role == UserRole.tutor && certificationFiles != null && certificationFiles.isNotEmpty) {
        final List<String> certUrls = await _uploadCertificationFiles(uid, certificationFiles);
        data['certification_url'] = certUrls.first;
        data['certification_urls'] = certUrls;
      }
      final collection = _collectionForRole(userModel.role);
      await _db.collection(collection).doc(uid).set(data);
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'role': userModel.role.name,
        'account_status': userModel.accountStatus.name,
      });
 
      // Register children for parent accounts.
      if (userModel.role == UserRole.parent && children.isNotEmpty) {
        await saveChildren(parentUid: uid, children: children);
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }
 
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }
 
  UserModel _buildModelWithUid(UserModel model, String uid) {
    return model.copyWithUid(uid);
  }
 
  Future<void> checkIfUserExists({
    required String email,
    required String phone,
  }) async {
    final signInMethods = await _auth.fetchSignInMethodsForEmail(email);
    if (signInMethods.isNotEmpty) {
      throw 'This email is already registered.';
    }

    for (final collection in ['students', 'tutors', 'parents']) {
      final phoneQuery = await _db
          .collection(collection)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (phoneQuery.docs.isNotEmpty) {
        throw 'This phone number is already registered.';
      }
    }
  }
 
  Future<void> updateEmail({required String newEmail}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Not logged in.';
 
      final emailQuery = await _db
          .collection('users')
          .where('email', isEqualTo: newEmail)
          .limit(1)
          .get();
      if (emailQuery.docs.isNotEmpty) throw 'This email is already registered.';
 
      final uid = user.uid;
 
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('updateUserEmail')
          .call({'newEmail': newEmail});
 
      await _db.collection('users').doc(uid).update({'email': newEmail});
      final userDoc = await _db.collection('users').doc(uid).get();
      final role = UserRole.values.firstWhere(
        (r) => r.name == (userDoc['role'] ?? 'student'),
        orElse: () => UserRole.student,
      );
      await _db
          .collection(_collectionForRole(role))
          .doc(uid)
          .update({'email': newEmail});
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }
 
  Future<void> updatePhone({required String newPhone}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Not logged in.';
 
      for (final collection in ['students', 'tutors', 'parents']) {
        final query = await _db
            .collection(collection)
            .where('phone', isEqualTo: newPhone)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          throw 'This phone number is already registered.';
        }
      }
 
      final uid = user.uid;
 
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('updateUserPhone')
          .call({'newPhone': newPhone});
 
      final userDoc = await _db.collection('users').doc(uid).get();
      final role = UserRole.values.firstWhere(
        (r) => r.name == (userDoc['role'] ?? 'student'),
        orElse: () => UserRole.student,
      );
      await _db
          .collection(_collectionForRole(role))
          .doc(uid)
          .update({'phone': newPhone});
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }
 
  Future<void> verifyCurrentPassword(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw 'Not logged in.';
 
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
 
    try {
      await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Not logged in.';

      await verifyCurrentPassword(currentPassword);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> deleteAccount({required String password}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Not logged in.';

      await verifyCurrentPassword(password);
      final uid = user.uid;

      final userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final role = UserRole.values.firstWhere(
          (r) => r.name == (userDoc['role'] ?? 'student'),
          orElse: () => UserRole.student,
        );

        final batch = _db.batch();
        batch.delete(_db.collection(_collectionForRole(role)).doc(uid));
        batch.delete(_db.collection('users').doc(uid));
        await batch.commit();
      }

      await user.delete();
      try { await _googleSignIn.signOut(); } catch (_) {}
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      rethrow;
    }
  }
 
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final emailQuery = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (emailQuery.docs.isEmpty) {
        throw 'No account found with this email.';
      }
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }
 
  Future<String> getEmailFromPhone(String phone) async {
    return await _getEmailFromPhone(phone);
  }

  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userDoc = await _db.collection('users').doc(user.uid).get();
    if (!userDoc.exists) return null;

    final role = UserRole.values.firstWhere(
      (r) => r.name == (userDoc['role'] ?? 'student'),
      orElse: () => UserRole.student,
    );
    return _fetchUserProfile(user.uid, role);
  }

  Future<void> updatePersonalInfo({
    required String uid,
    required String firstName,
    required String lastName,
    required String location,
    required DateTime birthday,
  }) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final role = UserRole.values.firstWhere(
      (r) => r.name == (userDoc['role'] ?? 'student'),
      orElse: () => UserRole.student,
    );

    await _db.collection(_collectionForRole(role)).doc(uid).update({
      'first_name': firstName,
      'last_name': lastName,
      'location': location,
      'birthday': Timestamp.fromDate(birthday),
    });
  }

  Future<void> updateStudyInfo({
    required String uid,
    required String schoolLevel,
    required String grade,
    required String speciality,
    required String school,
    required List<String> preferredSubjects,
  }) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final role = UserRole.values.firstWhere(
      (r) => r.name == (userDoc['role'] ?? 'student'),
      orElse: () => UserRole.student,
    );

    await _db.collection(_collectionForRole(role)).doc(uid).update({
      'school_level': schoolLevel,
      'grade': grade,
      'speciality': speciality,
      'learning_objectives': school,
      'preferred_subjects': preferredSubjects,
    });
  }
 
  Future<void> updatePasswordWithOtp({
    required String email,
    required String newPassword,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      throw 'A password reset link has been sent to $email. Please use it to set your new password.';
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }
 
  Future<void> checkEmailExists(String email) async {
    final signInMethods = await _auth.fetchSignInMethodsForEmail(email);
    if (signInMethods.isEmpty) throw 'No account found with this email.';
  }
 
  final GoogleSignIn _googleSignIn = GoogleSignIn();
 
  Future<UserModel?> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;
 
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final uid = result.user!.uid;
 
      final userDoc = await _db.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        await _auth.signOut();
        await _googleSignIn.signOut();
        return null;
      }
 
      final role = UserRole.values.firstWhere(
          (r) => r.name == (userDoc['role'] ?? 'student'),
          orElse: () => UserRole.student);
      final userModel = await _fetchUserProfile(uid, role);
      await _db.collection(_collectionForRole(role)).doc(uid).set({
        'last_login_date': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Google sign-in failed: ${e.toString()}';
    }
  }
 
  // ---------------------------------------------------------------------------
  // saveChildren — FIXED field name: uses 'children_uids' (snake_case) to match
  // ParentModel.toMap() so both reads and writes use the same Firestore field.
  // ---------------------------------------------------------------------------
  Future<void> saveChildren({
    required String parentUid,
    required List<Map<String, dynamic>> children,
  }) async {
    final batch = _db.batch();
    final List<String> childIds = [];
 
    for (final child in children) {
      final ref = _db.collection('children').doc();
      childIds.add(ref.id);
 
      final gender = child['gender'] ?? 'male';
      final picture = child['picture'] != null && child['picture'] != ''
          ? child['picture']
          : gender == 'female'
              ? 'assets/images/childgirl.png'
              : 'assets/images/chidboy.png';
 
      batch.set(ref, {
        'id': ref.id,
        'parentUid': parentUid,
        'name': child['name'] ?? '',
        'gender': gender,
        'level': child['level'] ?? '',
        'grade': child['grade'] ?? '',
        'speciality': child['speciality'] ?? '',
        'subjects': child['subjects'] ?? [],
        'picture': picture,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
 
    await batch.commit();
 
    // FIXED: field name is 'children_uids' to match ParentModel.toMap() and
    // ParentModel.fromMap(). The original code used 'childrenUids' (camelCase)
    // here but 'children_uids' (snake_case) in the model — causing two separate
    // Firestore fields and an always-empty childrenUids list on reads.
    await _db.collection('parents').doc(parentUid).update({
      'children_uids': childIds,
    });
  }
}

