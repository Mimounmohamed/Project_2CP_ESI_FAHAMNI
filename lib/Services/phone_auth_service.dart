import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_client.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_action.dart';

class PhoneAuthService {
  static const _siteKey = '6LfFtI8sAAAAALjEg6LqzvO4j9MbyQV39f4QIQEd';
  static RecaptchaClient? _client; // ← was RecaptchaHandle, now RecaptchaClient

  // Call once at app startup
  static Future<void> init() async {
    try {
      _client = await Recaptcha.fetchClient(_siteKey);
      debugPrint('reCAPTCHA initialized');
    } catch (e) {
      debugPrint('reCAPTCHA init failed: $e');
    }
  }

  // Call this to send OTP
  static Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    required void Function() onAutoVerified,
  }) async {
    // Step 1: get reCAPTCHA token
    try {
      _client ??= await Recaptcha.fetchClient(_siteKey);
      await _client!.execute(RecaptchaAction.custom('SEND_OTP'));
      debugPrint('reCAPTCHA token obtained');
    } catch (e) {
      debugPrint('reCAPTCHA failed, proceeding anyway: $e');
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        onAutoVerified();
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('Auto-retrieval timeout');
      },
    );
  }
  static Future<UserCredential?> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}