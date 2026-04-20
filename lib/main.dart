import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fahamni/Login_Screen/LoginScreen.dart';

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
      home: const LoginScreen(),
    );
  }
}
