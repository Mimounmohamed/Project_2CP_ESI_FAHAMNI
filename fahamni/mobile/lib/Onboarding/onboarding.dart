import 'package:flutter/material.dart';
import '../../widgets/onboarding_page.dart';
import '../Login_Screen/LoginScreen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _controller = PageController();
  int currentIndex = 0;

  late AnimationController _buttonController;
  late Animation<Offset> _buttonSlide;
  late Animation<double> _buttonFade;

  final List<Map<String, String>> pages = [
    {
      "image": "assets/images/Image (1).png",
      "title": "Learn Smarter, Faster",
      "desc":
          "Explore qualified teachers and discover experts in different subjects near you or online."
    },
    {
      "image": "assets/images/Placeholder for educational scheduling illustration.png",
      "title": "Support Your Child's Success",
      "desc":
          "Monitor progress, connect with trusted teachers, and ensure your child gets the guidance they need."
    },
    {
      "image": "assets/images/page3.png",
      "title": "Share Your Knowledge",
      "desc":
          "Offer your services, manage your sessions, and connect with students who need your expertise."
    },
  ];

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900), // ← slower
    );

    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 2.0), // ← starts further below
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: Curves.easeOutBack, // ← bouncy landing
      ),
    );

    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _buttonController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _buttonController.forward();
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => currentIndex = index);
    _buttonController.forward(from: 0);
  }

  void nextPage() {
    if (currentIndex < pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreenPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    key: ValueKey(index),
                    image: pages[index]["image"]!,
                    title: pages[index]["title"]!,
                    description: pages[index]["desc"]!,
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => buildDot(index == currentIndex),
              ),
            ),

            const SizedBox(height: 28),

            // Buttons bounce up from below
            SlideTransition(
              position: _buttonSlide,
              child: FadeTransition(
                opacity: _buttonFade,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF000080),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                currentIndex == pages.length - 1
                                    ? "Get Started"
                                    : "Next",
                                style: const TextStyle(
                                  fontFamily: "Inter",
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (currentIndex == 0)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreenPage(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF000080),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              "Skip",
                              style: TextStyle(
                                fontFamily: "Inter",
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF000080),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget buildDot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF000080) : const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

