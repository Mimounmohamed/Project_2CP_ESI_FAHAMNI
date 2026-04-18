import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'Splash_Screen/splash.dart';
import 'TeacherDashboard/teacher_dashboard.dart';
import 'navigation/app_navigation.dart';

const bool kSkipSplash = true;

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
      home: kSkipSplash ? const TeacherDashboardScreen() : const SplashScreen(),

    );
  }
}
