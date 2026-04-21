import 'package:fahamni/models/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.messageModel,
    required this.isme,
  });

  final MessageModel messageModel;
  final bool isme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(),

      child: Align(
        alignment: isme ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 265),

          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
          decoration: BoxDecoration(
            color: Color(isme ? 0xFF000080 : 0xFFFFFFFF),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1), // Soft shadow color
                spreadRadius: 1, // How much the shadow spreads
                blurRadius: 4, // How "blurry" the shadow is
                offset: const Offset(0, 4),
              ),
            ],

            borderRadius: BorderRadius.only(
              topRight: Radius.circular(16),
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(isme ? 16 : 0),
              bottomRight: Radius.circular(isme ? 0 : 16),
            ),
          ),
          child: Text(
            messageModel.content,
            style: GoogleFonts.inter(
              color: Color(isme ? 0xFFFFFFFF : 0xFF1F2937),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
