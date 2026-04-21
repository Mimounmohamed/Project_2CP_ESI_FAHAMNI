import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fahamni/Login_Screen/LoginScreen.dart';
import 'package:fahamni/StudentHomePage/Student_homepage.dart';
import 'package:fahamni/TeacherDashboard/teacher_dashboard.dart';
import 'package:fahamni/ParentDashboread/ParentHomePage/home_page.dart';

import 'firebase_options.dart';
import 'navigation/app_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // AI features stay inactive until a local .env file is provided.
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: NavigationService.instance.navigatorKey,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _checking = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;

      if (!doc.exists) {
        setState(() => _checking = false);
        return;
      }

      final role = doc['role'] as String? ?? 'student';
      Widget home;
      switch (role) {
        case 'tutor':
          home = const TeacherDashboardScreen();
          break;
        case 'parent':
          home = const Parenthomepage();
          break;
        default:
          home = const Studenthomepage();
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => home),
      );
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF000080)),
        ),
      );
    }
    return const LoginScreen();
  }
}
