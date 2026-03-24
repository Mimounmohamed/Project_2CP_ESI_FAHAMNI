import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'Services/firebase_options.dart';
import 'Splash_Screen/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  onCodeSent: (id) {
  debugPrint('onCodeSent: verificationId received');
  // ...
};
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Firebase already initialized: $e');
  }
   
   await FirebaseAppCheck.instance.activate(
  androidProvider: AndroidProvider.debug,
);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
