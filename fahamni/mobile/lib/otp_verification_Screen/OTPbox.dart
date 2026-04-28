import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OTPBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;

  const OTPBox({
    super.key,
    required this.controller,
    required this.focusNode,
    this.nextFocusNode,
  });

  @override
  State<OTPBox> createState() => _OTPBoxState();
}

class _OTPBoxState extends State<OTPBox> {
  bool _isFocused = false;
  bool _hasValue = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onValueChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = widget.focusNode.hasFocus);
  }

  void _onValueChange() {
    setState(() => _hasValue = widget.controller.text.isNotEmpty);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onValueChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 46,
      height: 56,
      decoration: BoxDecoration(
        color: _isFocused
            ? const Color(0xFFEEEEFF)   // light navy tint when active
            : _hasValue
                ? const Color(0xFFF0F0FF) // subtle fill when filled
                : const Color(0xFFFFFFFF),
        border: Border.all(
          color: _isFocused
              ? const Color(0xFF000080)
              : _hasValue
                  ? const Color(0x99000080)
                  : const Color(0xFFDDE1E7),
          width: _isFocused ? 2.0 : 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF000080).withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Center(
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          style: TextStyle(
            fontSize: 20,
            fontFamily: "Inter",
            fontWeight: FontWeight.w700,
            color: const Color(0xFF000080),
            height: 1.0, 
          ),
          showCursor: false,
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
            isCollapsed: true,
          ),
          onChanged: (value) {
            if (value.length == 1 && widget.nextFocusNode != null) {
              FocusScope.of(widget.focusNode.context!)
                  .requestFocus(widget.nextFocusNode);
            }
          },
        ),
      ),
    );
  }
}

