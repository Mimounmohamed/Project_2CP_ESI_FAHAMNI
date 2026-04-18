import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class EmailOtpService {
  final _db        = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  String _generateCode() {
    final rng = Random.secure();
    return (100000 + rng.nextInt(900000)).toString();
  }

  Future<void> sendOtp({
    required String email,
    required String firstName,
  }) async {
    final code   = _generateCode();
    final expiry = DateTime.now().add(const Duration(minutes: 10));

    await _db.collection('email_otps').doc(email).set({
      'code':      code,
      'expiresAt': Timestamp.fromDate(expiry),
      'verified':  false,
    });

    await _functions.httpsCallable('sendOtpEmail').call({
      'email':     email,
      'firstName': firstName,
      'code':      code,
      'isReset':   false,
    });
  }

  Future<void> sendPasswordResetOtp({required String email}) async {
    final code   = _generateCode();
    final expiry = DateTime.now().add(const Duration(minutes: 10));

    await _db.collection('email_otps').doc(email).set({
      'code':      code,
      'expiresAt': Timestamp.fromDate(expiry),
      'type':      'password_reset',
      'verified':  false,
    });

    await _functions.httpsCallable('sendOtpEmail').call({
      'email':   email,
      'firstName': '',
      'code':    code,
      'isReset': true,
    });
  }

  Future<void> verifyOtp({
    required String email,
    required String code,
  }) async {
    final doc = await _db.collection('email_otps').doc(email).get();

    if (!doc.exists) {
      throw 'No verification code found. Please request a new one.';
    }

    final data       = doc.data()!;
    final storedCode = data['code'] as String;
    final expiresAt  = (data['expiresAt'] as Timestamp).toDate();

    if (DateTime.now().isAfter(expiresAt)) {
      await _db.collection('email_otps').doc(email).delete();
      throw 'Code has expired. Please request a new one.';
    }

    if (storedCode != code) {
      throw 'Incorrect code. Please try again.';
    }

    await _db.collection('email_otps').doc(email).delete();
  }

  Future<void> sendWelcomeEmail({
    required String email,
    required String firstName,
  }) async {
    await _functions.httpsCallable('sendWelcomeEmail').call({
      'email':     email,
      'firstName': firstName,
    });
  }

  Future<void> sendPasswordChangedEmail({required String email}) async {
    await _functions.httpsCallable('sendPasswordChangedEmail').call({
      'email': email,
    });
  }
}