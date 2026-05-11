import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavbar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTap;
  const CustomBottomNavbar({
    super.key,
    required this.selectedIndex,
    required this.onTap});

  @override
  State<CustomBottomNavbar> createState() => _CustomBottomNavbarState();
}

class _CustomBottomNavbarState extends State<CustomBottomNavbar> {
  Widget navItem(
    String iconpath,
    String label,
    int index, {
    required bool compact,
  }) {
    bool selected = widget.selectedIndex == index;

    return GestureDetector(
      onTap: () {
        widget.onTap(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 10)
            : selected
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                : const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF000080) : Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconpath,
              height: compact ? 22 : 24,
              width: compact ? 22 : 24,
              color: selected ? Colors.white : const Color(0xFF000080),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: selected && !compact
                  ? Row(
                      children: [
                        const SizedBox(width: 8),
                        AnimatedOpacity(
                          opacity: selected ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontFamily: "Nunito",
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 390;

        return ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 20),
            height: 70,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF94A3B8).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 15,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    navItem(
                      "assets/images/fi-rr-home.svg",
                      "Home",
                      0,
                      compact: compact,
                    ),
                    navItem(
                      "assets/images/explore.svg",
                      "Explore",
                      1,
                      compact: compact,
                    ),
                    navItem(
                      "assets/images/course.svg",
                      "Courses",
                      2,
                      compact: compact,
                    ),
                    navItem(
                      "assets/images/chat.svg",
                      "Chat",
                      3,
                      compact: compact,
                    ),
                    navItem(
                      "assets/images/profile.svg",
                      "Profile",
                      4,
                      compact: compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}


