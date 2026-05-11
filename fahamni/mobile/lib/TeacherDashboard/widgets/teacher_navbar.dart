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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool compact = constraints.maxWidth < 390;

        return ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            margin: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB).withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(30),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _TeacherNavItem(
                      iconPath: 'assets/images/fi-rr-home.svg',
                      label: 'Home',
                      selected: selectedIndex == 0,
                      compact: compact,
                      onTap: () => onTap(0),
                    ),
                    _TeacherNavItem(
                      iconPath: 'assets/images/course.svg',
                      label: 'Services',
                      selected: selectedIndex == 1,
                      compact: compact,
                      onTap: () => onTap(1),
                    ),
                    _TeacherNavItem(
                      iconPath: 'assets/images/chat.svg',
                      label: 'Chat',
                      selected: selectedIndex == 2,
                      compact: compact,
                      onTap: () => onTap(2),
                    ),
                    _TeacherNavItem(
                      iconPath: 'assets/images/profile.svg',
                      label: 'Profile',
                      selected: selectedIndex == 3,
                      compact: compact,
                      onTap: () => onTap(3),
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

class _TeacherNavItem extends StatelessWidget {
  const _TeacherNavItem({
    required this.iconPath,
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String iconPath;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: selected
            ? EdgeInsets.symmetric(
                horizontal: compact ? 10 : 14,
                vertical: 10,
              )
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0D138B) : Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: compact ? 20 : 22,
              height: compact ? 20 : 22,
              colorFilter: ColorFilter.mode(
                selected ? Colors.white : const Color(0xFF0D138B),
                BlendMode.srcIn,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Row(
                      children: [
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: "Nunito",
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
}
