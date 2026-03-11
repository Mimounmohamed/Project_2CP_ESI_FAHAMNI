import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavbar extends StatefulWidget {
  const CustomBottomNavbar({super.key});

  @override
  State<CustomBottomNavbar> createState() => _CustomBottomNavbarState();
}

class _CustomBottomNavbarState extends State<CustomBottomNavbar> {
  int selectedIndex = 0;

  Widget navItem(String iconpath, String label, int index) {
    bool selected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: selected ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10) : const EdgeInsets.symmetric(horizontal: 10, vertical: 10) ,
        decoration: BoxDecoration(
          color: selected ? Color(0xFF000080) : Colors.white,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
                iconpath,
                height: 24,
                width: 24,
                color: selected ? Colors.white : Color(0xFF000080)),
            AnimatedSize(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: selected
                  ? Row(
                      children: [
                        SizedBox(width: 8),
                        AnimatedOpacity(
                          opacity: selected ? 1.0 : 0.0,
                          duration: Duration(milliseconds: 200),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          navItem("assets/fi-rr-home.svg", "Home", 0),
          navItem("assets/explore.svg", "explore", 1),
          navItem("assets/course.svg", "Courses", 2),
          navItem("assets/chat.svg", "Chat", 3),
          navItem("assets/profile.svg", "Profile", 4),
        ],
      ),
    );
  }
}