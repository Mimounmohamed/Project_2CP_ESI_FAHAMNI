import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'OTPbox.dart';
import 'package:fahamni/Services/auth_.service.dart';
import 'package:fahamni/Services/email_otp_service.dart';
import 'package:fahamni/Reset_pass_Screen/Forgetpass.dart';
class otpresetpassPage extends StatefulWidget {
  final String contact;     // trimmed email  OR  E.164 phone (+213...)
  final bool isPhoneFlow;

  const otpresetpassPage({
    super.key,
    required this.contact,
    required this.isPhoneFlow,
  });

  @override
  State<otpresetpassPage> createState() => _otpresetpassPageState();
}

class _otpresetpassPageState extends State<otpresetpassPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final _authService    = AuthService();
  final _emailOtpService = EmailOtpService();

  String? _verificationId;
  String? _errorMessage;
  bool _isSending   = true;
  bool _isVerifying = false;

  String get _otpCode => _controllers.map((c) => c.text).join();

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.isPhoneFlow ? _sendSmsOtp() : _sendEmailOtp();
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes)  f.dispose();
    super.dispose();
  }

  // ── Email OTP ────────────────────────────────────────────────────────────

  Future<void> _sendEmailOtp() async {
    setState(() { _isSending = true; _errorMessage = null; });
    try {
      await _emailOtpService.sendPasswordResetOtp(email: widget.contact);
      if (mounted) setState(() => _isSending = false);
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); _isSending = false; });
    }
  }

  Future<void> _verifyEmailOtp() async {
    if (_otpCode.length < 6) {
      setState(() => _errorMessage = 'Please enter the full 6-digit code.');
      return;
    }
    setState(() { _isVerifying = true; _errorMessage = null; });
    try {
      await _emailOtpService.verifyOtp(email: widget.contact, code: _otpCode);
      // OTP correct → go set new password
      _goToReset(verifiedEmail: widget.contact);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  // ── Phone / SMS OTP ──────────────────────────────────────────────────────

  Future<void> _sendSmsOtp() async {
    setState(() { _isSending = true; _errorMessage = null; });
    await _authService.sendOtp(
      phoneNumber: widget.contact,
      onCodeSent: (id) {
        if (!mounted) return;
        setState(() { _verificationId = id; _isSending = false; });
      },
      onError: (err) {
        if (!mounted) return;
        setState(() { _errorMessage = err; _isSending = false; });
      },
    );
  }

  Future<void> _verifySmsOtp() async {
    if (_verificationId == null) {
      setState(() => _errorMessage = 'OTP not sent yet. Tap "Resend Code".');
      return;
    }
    if (_otpCode.length < 6) {
      setState(() => _errorMessage = 'Please enter the full 6-digit code.');
      return;
    }
    setState(() { _isVerifying = true; _errorMessage = null; });
    try {
      // 1 — validate the SMS code (throws if wrong/expired)
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpCode,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      // 2 — get the email linked to this phone number
      final linkedEmail = await _authService.getEmailFromPhone(widget.contact);

      // 3 — sign out the temporary phone session immediately
      await FirebaseAuth.instance.signOut();

      // 4 — navigate to reset password, carrying the linked email
      _goToReset(verifiedEmail: linkedEmail);
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Verification failed.');
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  // ── Navigation ───────────────────────────────────────────────────────────

  void _goToReset({required String verifiedEmail}) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordPage(verifiedEmail: verifiedEmail),
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLoading = _isSending || _isVerifying;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFFAFAFA),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              Container(
                alignment: Alignment.center,
                child: Image.asset("assets/images/Vector@2x.png", height: 100),
              ),
              const SizedBox(height: 10),
              const Text("Fahamni",
                  style: TextStyle(fontFamily: 'Inter', color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700, fontSize: 30, letterSpacing: -0.75)),
              const Text("A peaceful place for growth",
                  style: TextStyle(fontFamily: "Inter", fontSize: 16,
                      fontWeight: FontWeight.w400, color: Color(0xff64748B))),

              const SizedBox(height: 40),

              Text(
                widget.isPhoneFlow ? "Phone Verification" : "Email Verification",
                style: const TextStyle(fontFamily: 'Inter', color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w700, fontSize: 28),
              ),
              const SizedBox(height: 6),
              Text(
                _isSending
                    ? "Sending code to ${widget.contact}…"
                    : widget.isPhoneFlow
                        ? "Enter the SMS code sent to\n${widget.contact}"
                        : "Enter the code sent to\n${widget.contact}\nCheck your inbox and spam folder.",
                style: const TextStyle(fontFamily: "Inter", fontSize: 16, color: Color(0xff64748B)),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) => OTPBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    nextFocusNode: i < 5 ? _focusNodes[i + 1] : null,
                  )),
                ),
              ),

              const SizedBox(height: 20),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Color(0xFFE53935), fontSize: 14,
                          fontFamily: "Inter", fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center),
                ),

              const SizedBox(height: 20),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 55,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF000080),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33137FEC), offset: Offset(0, 8), blurRadius: 10, spreadRadius: -6),
                    BoxShadow(color: Color(0x33137FEC), offset: Offset(0, 20), blurRadius: 25, spreadRadius: -5),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: isLoading
                        ? null
                        : (widget.isPhoneFlow ? _verifySmsOtp : _verifyEmailOtp),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text("Verify Code",
                              style: TextStyle(color: Colors.white, fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              TextButton(
                onPressed: isLoading
                    ? null
                    : (widget.isPhoneFlow ? _sendSmsOtp : _sendEmailOtp),
                child: Text(
                  _isSending ? "Sending…" : "Resend Code",
                  style: const TextStyle(fontFamily: "Inter", color: Color(0xBF000080),
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}