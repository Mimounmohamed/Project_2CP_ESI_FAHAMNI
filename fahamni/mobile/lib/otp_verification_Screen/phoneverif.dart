import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'OTPbox.dart';
import 'package:fahamni/Registration_Completed_Screen/RegistraionCompleteScreen.dart';
import 'package:fahamni/models/user_model.dart';
import 'package:fahamni/models/student_model.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:fahamni/models/parent_model.dart';
import 'package:fahamni/Services/auth_.service.dart';
import 'package:fahamni/Services/email_otp_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneVerificationPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const PhoneVerificationPage({super.key, required this.data});

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _authService = AuthService();
  final _emailOtpService = EmailOtpService();
  String? _verificationId;
  String? _errorMessage;
  bool _isSending = true;
  bool _isVerifying = false;
  late bool _isPhoneFlow;

  @override
  void initState() {
    super.initState();
    _isPhoneFlow = widget.data['verificationMethod'] == 'phone';
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_isPhoneFlow) {
        await _sendOtp();
      } else {
        _sendEmailOtp();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _otpCode => _controllers.map((c) => c.text).join();

  Future<void> _sendOtp() async {
    setState(() { _isSending = true; _errorMessage = null; });
    await _authService.sendOtp(
      phoneNumber: widget.data['phone'] as String,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _isSending = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() { _errorMessage = error; _isSending = false; });
      },
    );
  }

  Future<void> _verifyOtp() async {
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
      final userModel = _buildUserModel();
      await _authService.verifyOtpAndRegister(
        verificationId: _verificationId!,
        smsCode:        _otpCode,
        email:          widget.data['email'],
        password:       widget.data['password'],
        userModel:      userModel,
        certificationFiles: widget.data['certificationFiles'] as List<PlatformFile>?,
      );
       await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);
      if (userModel.role == UserRole.parent && widget.data['children'] != null) {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  await _authService.saveChildren(
    parentUid: uid,
    children: List<Map<String, dynamic>>.from(widget.data['children']),
  );
}
      _goToComplete();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _sendEmailOtp() async {
    setState(() { _isSending = true; _errorMessage = null; });
    try {
      await _emailOtpService.sendOtp(
        email:     widget.data['email'],
        firstName: widget.data['firstName'],
      );
      if (!mounted) return;
      setState(() => _isSending = false);
    } catch (e) {
      if (!mounted) return;
      setState(() { _errorMessage = e.toString(); _isSending = false; });
    }
  }

  Future<void> _verifyEmailOtp() async {
    if (_otpCode.length < 6) {
      setState(() => _errorMessage = 'Please enter the full 6-digit code.');
      return;
    }
    setState(() { _isVerifying = true; _errorMessage = null; });
    try {
      await _emailOtpService.verifyOtp(
        email: widget.data['email'],
        code:  _otpCode,
      );
      final userModel = _buildUserModel();
      await _authService.signUp(
        widget.data['email'],
        widget.data['password'],
        userModel,
        certificationFiles: widget.data['certificationFiles'] as List<PlatformFile>?,
      );
       await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);
      if (userModel.role == UserRole.parent && widget.data['children'] != null) {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  await _authService.saveChildren(
    parentUid: uid,
    children: List<Map<String, dynamic>>.from(widget.data['children']),
  );
}
      _goToComplete();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    if (_isPhoneFlow) {
      await _sendOtp();
    } else {
      await _sendEmailOtp();
    }
  }

  void _goToComplete() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => RegistrationComplete(
          email:     widget.data['email'],
          firstName: widget.data['firstName'],
        ),
      ),
      (route) => false,
    );
  }

  String _defaultPicture() {
    final role   = widget.data['role']   as UserRole;
    final gender = widget.data['gender'] as Gender;

    if (role == UserRole.tutor) {
      return gender == Gender.female
          ? 'assets/images/tutorfemale.png'
          : 'assets/images/tutormale.png';
    } else if (role == UserRole.student) {
      return gender == Gender.female
          ? 'assets/images/studentfemale.png'
          : 'assets/images/studentmale.png';
    } else {
      return gender == Gender.female
          ? 'assets/images/parentfemale.png'
          : 'assets/images/parentmale.png';
    }
  }

  UserModel _buildUserModel() {
    final data = widget.data;
    final role = data['role'] as UserRole;
    if (role == UserRole.student) {
      final commune = data['commune'] as String? ?? '';
      final city = data['location'] as String? ?? '';
      final location = commune.isNotEmpty ? '$commune, $city' : city;
      return StudentModel(
        uid: '', firstName: data['firstName'], lastName: data['lastName'],
        email: data['email'], phone: data['phone'],
        location: location, gender: data['gender'],
        birthday: data['birthday'], accountStatus: AccountStatus.validated,
        isSuspended: false,
        schoolLevel:        data['schoolLevel']        ?? '',
        learningObjectives: data['learningObjectives'] ?? '',
        preferredSubjects:  List<String>.from(data['preferredSubjects'] ?? []),
        favoriteTeachers:   List<String>.from(data['favoriteTeachers'] ?? []),
        Courses:            List<String>.from(data['courses'] ?? []),
        picture: data['picture'] ?? _defaultPicture(),
        grade: data['grade'] ?? '',
        speciality: data['speciality'] ?? '',
      );
    } else if (role == UserRole.tutor) {
      final tutorCommune = data['commune'] as String? ?? '';
      final tutorCity    = data['location'] as String? ?? '';
      final tutorLocation = tutorCommune.isNotEmpty
          ? '$tutorCommune, $tutorCity'
          : tutorCity;
      return TutorModel(
        uid: '', firstName: data['firstName'], lastName: data['lastName'],
        email: data['email'], phone: data['phone'],
        location: tutorLocation, gender: data['gender'],
        birthday: data['birthday'], accountStatus: AccountStatus.pending,
        isSuspended: false,
        expertiseDomain:        data['expertiseDomain']        ?? '',
        levelsTaught:           List<String>.from(data['levelsTaught'] ?? []),
        teachingMode:           data['teachingMode']           ?? '',
        isAvailable:            data['isAvailable']            ?? false,
        certified:              data['certified']              ?? false,
        pedagogicalDescription: data['pedagogicalDescription'] ?? '',
        averageRating:          data['averageRating']          ?? 0.0,
        yearsOfExperience:      data['yearsOfExperience']      ?? 0,
        academicDescription:    data['academicDescription']    ?? '',
        certificationUrl:       data['certificationUrl']       ?? '',
        picture: data['picture'] ?? _defaultPicture(),
      );
    } else {
      final parentCommune = data['commune'] as String? ?? '';
      final parentCity    = data['location'] as String? ?? '';
      final parentLocation = parentCommune.isNotEmpty
          ? '$parentCommune, $parentCity'
          : parentCity;
      return ParentModel(
        uid: '', firstName: data['firstName'], lastName: data['lastName'],
        email: data['email'], phone: data['phone'],
        location: parentLocation, gender: data['gender'],
        birthday: data['birthday'], accountStatus: AccountStatus.validated,
        isSuspended: false,
        childrenUids: List<String>.from(data['childrenUids'] ?? []),
        picture: data['picture'] ?? _defaultPicture(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isSending || _isVerifying;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFFAFAFA),
        surfaceTintColor: const Color(0xFFFAFAFA),
        shadowColor: Colors.transparent,
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
                child: Image.asset(
                  "assets/images/Vector@2x.png",
                  height: 100,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Fahamni",
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: 30,
                  letterSpacing: -0.75,
                ),
              ),
              const Text(
                "A peaceful place for growth",
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xff64748B),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                _isPhoneFlow ? "Phone Verification" : "Email Verification",
                style: const TextStyle(
                  fontFamily: 'Inter', color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700, fontSize: 28,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isPhoneFlow
                    ? (_isSending
                        ? "Sending code to ${widget.data['phone']}…"
                        : "Enter the code sent to ${widget.data['phone']}")
                    : (_isSending
                        ? "Sending code to ${widget.data['email']}…"
                        : "Enter the code sent to\n${widget.data['email']}.\nCheck your inbox and spam folder."),
                style: const TextStyle(
                  fontFamily: "Inter", fontSize: 16, color: Color(0xff64748B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) => OTPBox(
                    controller: _controllers[index],
                    focusNode:  _focusNodes[index],
                    nextFocusNode: index < 5 ? _focusNodes[index + 1] : null,
                  )),
                ),
              ),
              const SizedBox(height: 40),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFFE53935), fontSize: 14,
                      fontFamily: "Inter", fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000080),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x33137FEC),
                        offset: const Offset(0, 8),
                        blurRadius: 10,
                        spreadRadius: -6,
                      ),
                      BoxShadow(
                        color: const Color(0x33137FEC),
                        offset: const Offset(0, 20),
                        blurRadius: 25,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: isLoading
                          ? null
                          : (_isPhoneFlow ? _verifyOtp : _verifyEmailOtp),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                "Verify Code",
                                style: TextStyle(
                                  color: Colors.white, fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: isLoading ? null : _resend,
                child: Text(
                  _isSending ? "Sending…" : "Resend Code",
                  style: const TextStyle(
                    fontFamily: "Inter", color: Color(0xBF000080),
                    fontSize: 16, fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

