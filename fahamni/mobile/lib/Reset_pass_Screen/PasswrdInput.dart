import 'package:flutter/material.dart';

class PasswordInput extends StatefulWidget {
  final String label;
  final TextEditingController controller;

  const PasswordInput({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  State<PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _showPassword = false;

  OutlineInputBorder _border([Color color = const Color(0xFFE0E0E0), double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: 8),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: "Inter",
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xff1f2937),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: !_showPassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '${widget.label} is required';
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
            hintText: "Enter password",
            hintStyle: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 17,
              fontFamily: "Lexend",
            ),
            prefixIcon: const Icon(Icons.lock_outline, size: 22, color: Color(0xFF94A3B8)),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: const Color(0xFF94A3B8),
              ),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
            enabledBorder: _border(),
            focusedBorder: _border(const Color(0xFFE0E0E0), 2),
            errorBorder: _border(Colors.red, 1.5),
            focusedErrorBorder: _border(Colors.red, 1.5),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

