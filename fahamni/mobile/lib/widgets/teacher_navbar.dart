import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TeacherNavbar extends StatelessWidget {
  const TeacherNavbar({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onTap;

  Widget _navItem(
    BuildContext context, {
    required String iconPath,
    required String label,
    required int index,
    required bool compact,
  }) {
    final bool selected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: compact
            ? const EdgeInsets.symmetric(horizontal: 9, vertical: 10)
            : selected
                ? const EdgeInsets.symmetric(horizontal: 15, vertical: 10)
                : const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF000080) : Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              height: compact ? 21 : 24,
              width: compact ? 21 : 24,
              color: selected ? Colors.white : const Color(0xFF000080),
            ),
            if (selected && !compact) ...[
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 18),
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFF94A3B8).withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(30),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 9 : 14,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _navItem(
                      context,
                      iconPath: 'assets/images/fi-rr-home.svg',
                      label: 'Home',
                      index: 0,
                      compact: compact,
                    ),
                    _navItem(
                      context,
                      iconPath: 'assets/images/course.svg',
                      label: 'Services',
                      index: 1,
                      compact: compact,
                    ),
                    _navItem(
                      context,
                      iconPath: 'assets/images/chat.svg',
                      label: 'Chat',
                      index: 2,
                      compact: compact,
                    ),
                    _navItem(
                      context,
                      iconPath: 'assets/images/profile.svg',
                      label: 'Profile',
                      index: 3,
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
