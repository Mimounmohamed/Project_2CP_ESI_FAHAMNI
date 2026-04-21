import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Size? minimumSize;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double fontSize;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.minimumSize,
    this.borderRadius = 25,
    this.padding,
    this.fontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xBF000080),
        minimumSize: minimumSize ?? const Size(250, 50),
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: "Inter",
          fontSize: fontSize,
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
