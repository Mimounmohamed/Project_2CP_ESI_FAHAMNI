import 'package:flutter/material.dart';

class Passwrd extends StatefulWidget {
  const Passwrd({super.key});

  @override
  State<Passwrd> createState() => _PasswrdState();
}

class _PasswrdState extends State<Passwrd> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24),
      child: TextFormField(
        obscureText: _obscurePassword,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Password is required';
          }
          if (value.length < 8) {
            return 'Minimum 8 characters';
          }
          if (!value.contains(RegExp(r'[A-Z]'))) {
            return 'Must contain at least one uppercase letter';
          }
          if (!value.contains(RegExp(r'[0-9]'))) {
            return 'Must contain at least one number';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: 'Enter password',
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 14,
            fontFamily: 'Lexend',
          ),
          prefixIcon: const Icon(
            Icons.lock_outline,
            size: 20,
            color: Color(0xFF94A3B8),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: const Color(0xFF94A3B8),
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          filled: true,
          fillColor: const Color(0xFFFFFFFF),
        ),
      ),
    );
  }
}