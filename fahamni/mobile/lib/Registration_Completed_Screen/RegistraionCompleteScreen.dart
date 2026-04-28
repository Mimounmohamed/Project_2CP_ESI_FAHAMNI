import 'package:flutter/material.dart';
import '../StudentHomePage/Student_homepage.dart';
import '../TeacherDashboard/teacher_dashboard.dart';
import '../Services/email_otp_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Account_Settings_Student/account_screen.dart' as student_acc;
import '../Account_Settings_Teacher/account_screen.dart' as teacher_acc;

class RegistrationComplete extends StatefulWidget {
  final String email;
  final String firstName;
  const RegistrationComplete({super.key, required this.email, required this.firstName});

  @override
  State<RegistrationComplete> createState() => _RegistrationCompleteState();
}

class _RegistrationCompleteState extends State<RegistrationComplete> {
  String? _role;

  @override
  void initState() {
    super.initState();
    EmailOtpService().sendWelcomeEmail(email: widget.email, firstName: widget.firstName);
    _loadRole();
  }

  Future<void> _loadRole() async {
    await FirebaseAuth.instance.authStateChanges().first;
    if (!mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!mounted) return;
    setState(() => _role = doc.data()?['role'] as String?);
  }

  Future<void> _goToDashboard() async {
    if (!mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    String role = _role ?? '';
    if (role.isEmpty) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      role = doc.data()?['role'] as String? ?? '';
    }

    if (!mounted) return;

    Widget page;
    if (role == 'tutor') {
      page = const Teacherpage();
    } else if (role == 'student') {
      page = const Studentpage();
    } else {
      page = const Studentpage();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  void _goToCompleteProfile() {
    final role = _role ?? '';
    Widget page;
    if (role == 'tutor') {
      page = const teacher_acc.AccountScreen();
    } else {
      page = const student_acc.AccountScreen();
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: Color(0xFF0F172A),
          ),
          onPressed: _goToDashboard, 
        ),
        title: const Text(
          "Registration Complete",
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [

            const SizedBox(height: 120),

            /// Image
            Image.asset(
              'assets/images/Vector@2x.png',
              height: 120,
            ),

            const SizedBox(height: 30),

            /// Congratulations Title
            const Text(
              'Congratulations!',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            /// Description
            const Text(
              'Your profile is all set. Welcome to our learning community! '
              'Start exploring courses or complete your bio.',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
                height: 26 / 16, // 26px line height
              ),
              textAlign: TextAlign.center,
            ),

            const Spacer(),

            /// Go to Dashboard Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0B1F8F),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _goToDashboard, 
                child: const Text(
                  'Go to Dashboard',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Complete Profile Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFF0B1F8F) ,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _goToCompleteProfile,
                child: const Text(
                  'Complete Profile',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B1F8F) ,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}


