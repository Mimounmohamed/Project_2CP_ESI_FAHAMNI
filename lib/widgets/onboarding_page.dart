import 'package:flutter/material.dart';

class OnboardingPage extends StatefulWidget {
  final String image;
  final String title;
  final String description;

  const OnboardingPage({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _imageSlide;
  late Animation<Offset> _titleSlide;
  late Animation<Offset> _descSlide;
  late Animation<double> _imageFade;
  late Animation<double> _titleFade;
  late Animation<double> _descFade;
  late Animation<double> _imageScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // ← much slower
    );

    // Image: slides from left + scales up
    _imageSlide = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _imageScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _imageFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Title: slides from right, starts after image
    _titleSlide = Tween<Offset>(
      begin: const Offset(1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.75, curve: Curves.easeOutCubic),
    ));

    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.6, curve: Curves.easeIn),
      ),
    );

    // Description: slides from left, starts last
    _descSlide = Tween<Offset>(
      begin: const Offset(-1.5, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
    ));

    _descFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 0.85, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final maxWidth = constraints.maxWidth;
        final isCompact = maxHeight < 560 || maxWidth < 360;
        final imageHeight = (maxHeight * (isCompact ? 0.42 : 0.48)).clamp(170.0, 300.0);
        final titleFontSize = isCompact ? 24.0 : 30.0;
        final descFontSize = isCompact ? 15.0 : 18.0;
        final descPadding = isCompact ? 6.0 : 16.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(height: isCompact ? 12 : 24),

          // Image: slide + scale + fade
          SlideTransition(
            position: _imageSlide,
            child: ScaleTransition(
              scale: _imageScale,
              child: FadeTransition(
                opacity: _imageFade,
                child: Image.asset(
                  widget.image,
                  height: imageHeight,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

              SizedBox(height: isCompact ? 10 : 24),

          // Title: slide from right + fade
          SlideTransition(
            position: _titleSlide,
            child: FadeTransition(
              opacity: _titleFade,
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: "Inter",
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ),
          ),

              SizedBox(height: isCompact ? 6 : 12),

          // Description: slide from left + fade
          SlideTransition(
            position: _descSlide,
            child: FadeTransition(
              opacity: _descFade,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: descPadding),
                child: Text(
                  widget.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: "Nunito",
                    fontSize: descFontSize,
                    fontWeight: FontWeight.w400,
                    color: Color(0xCC1F2937),
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ),

              SizedBox(height: isCompact ? 4 : 12),
            ],
          ),
        );
      },
    );
  }
}