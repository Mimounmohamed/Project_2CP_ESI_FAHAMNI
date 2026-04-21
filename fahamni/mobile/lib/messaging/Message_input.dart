import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({
    super.key,
    this.controller,
    this.onSend,
    this.onAiPressed,
  });

  final TextEditingController? controller;
  final Future<void> Function(String text)? onSend;
  final VoidCallback? onAiPressed;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  late final TextEditingController _internalController;
  TextEditingController get _controller =>
      widget.controller ?? _internalController;
  bool _isTextEmpty = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _internalController = TextEditingController();
    _controller.addListener(_handleTextChanged);
    _handleTextChanged();
  }

  @override
  void didUpdateWidget(covariant MessageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      final TextEditingController oldController =
          oldWidget.controller ?? _internalController;
      oldController.removeListener(_handleTextChanged);
      _controller.addListener(_handleTextChanged);
      _handleTextChanged();
    }
  }

  void _handleTextChanged() {
    if (!mounted) return;
    final bool nextIsEmpty = _controller.text.isEmpty;
    if (_isTextEmpty == nextIsEmpty) return;
    setState(() {
      _isTextEmpty = nextIsEmpty;
    });
  }

  Future<void> _handleSend() async {
    if (_isSending || widget.onSend == null) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await widget.onSend!(_controller.text);
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _internalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(20, 0, 0, 128),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: (){},
                child: const Icon(
                  Icons.sentiment_satisfied_alt_outlined,
                  color: Color(0xFF000080),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: GoogleFonts.nunito(fontSize: 14),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (!_isSending) {
                      _handleSend();
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(color: Color(0xFF1F2937)),
                    border: InputBorder.none,
                  ),
                ),
              ),

              if (_isTextEmpty) ...[
                GestureDetector(
                  onTap: (){},
                  child: const Icon(
                    Icons.attach_file_outlined,
                    color: Color(0xFF1F2937),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: (){},
                  child: const Icon(
                    Icons.mic_none_outlined,
                    color: Color(0xFF1F2937),
                    size: 24,
                  ),
                ),
              ] else
                Transform.rotate(
                  angle:
                      -45 *
                      (3.14159 / 180), // Rotates 45 degrees counter-clockwise
                  child: IconButton(
                    icon: const Icon(
                      Icons.send,
                      color: Color(0xFF000080),
                      size: 28,
                    ),
                    onPressed: _isSending ? null : _handleSend,
                  ),
                ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: widget.onAiPressed,
                icon: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF000080),
                  size: 22,
                ),
                tooltip: 'AI Assistant',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
