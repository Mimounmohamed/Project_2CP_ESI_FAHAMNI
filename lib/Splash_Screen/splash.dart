import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fahamni/Services/auth_.service.dart';
import 'package:fahamni/models/user_model.dart';
import 'package:fahamni/StudentHomePage/Student_homepage.dart';
import 'package:fahamni/TeacherDashboard/teacher_dashboard.dart';
import '../Onboarding/onboarding.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _logoSlideLeft;
  late Animation<double> _textSlideAnim;
  late Animation<double> _textFadeAnim;

  @override
  void initState() {
    super.initState();
    print('SPLASH: initState started');

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
      ),
    );

    _logoSlideLeft = Tween<double>(begin: 0, end: -52).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _textSlideAnim = Tween<double>(begin: -30, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _textFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.62, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) {
      print('SPLASH: Animation completed');
    });

    // Use WidgetsBinding to ensure navigation happens after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('SPLASH: Post frame callback - scheduling navigation');
      Future.delayed(const Duration(milliseconds: 4000), () async {
        if (!mounted) return;
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          try {
            final profile = await AuthService().getCurrentUserProfile();
            if (!mounted) return;
            if (profile?.role == UserRole.tutor) {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const Teacherpage()));
              return;
            }
            if (profile != null) {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const Studentpage()));
              return;
            }
          } catch (_) {}
        }
        if (mounted) {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const OnboardingScreen()));
        }
      });
    });
  }

  @override
  void dispose() {
    print('SPLASH: dispose called');
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('SPLASH: build method');
    return Scaffold(
      body: Container(
        color: const Color(0xFFFAFAFA),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Invisible ghost row to reserve layout size
                      Opacity(
                        opacity: 0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(width: 150, height: 150),
                            SizedBox(width: 8),
                            Text(
                              'Fahamni',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Logo slides left
                      Transform.translate(
                        offset: Offset(_logoSlideLeft.value, 0),
                        child: Opacity(
                          opacity: _fadeAnim.value,
                          child: Transform.scale(
                            scale: _scaleAnim.value,
                            child: Image.asset(
                              'assets/images/Vector@2x.png',
                              width: 150,
                              height: 150,
                            ),
                          ),
                        ),
                      ),

                      // Name slides right
                      Positioned(
                        right: 0,
                        child: Transform.translate(
                          offset: Offset(_textSlideAnim.value, 0),
                          child: Opacity(
                            opacity: _textFadeAnim.value,
                            child: const Text(
                              'Fahamni',
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                                letterSpacing: -0.75,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              // Slogan if needed
            ],
          ),
        ),
      ),
    );
  }
}