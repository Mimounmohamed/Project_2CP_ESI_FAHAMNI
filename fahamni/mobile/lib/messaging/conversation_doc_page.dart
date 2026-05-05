import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../Services/chat_service.dart';
import 'inside_conversation_buttons.dart';
import '../models/chat_model.dart';
import '../repositories/firestore_chat_repository.dart';

class ConversationDocPage extends StatelessWidget {
  final String imageUrl;
  final String name;
  final ConversationModel conversation;
  final ChatService? chatService;

  const ConversationDocPage({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.conversation,
    this.chatService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
        ),
        actions: [
          PopupMenuButton<int>(
            color: const Color(0xFFFFFFFF),
            icon: const Icon(Icons.menu, color: Color(0xFF1F2937)),
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            onSelected: (value) {},
            itemBuilder: (context) => [
              const PopupMenuItem(value: 1, child: Text("Delete Conversation")),
              const PopupMenuItem(value: 2, child: Text("Quit Conversation")),
              const PopupMenuItem(value: 3, child: Text("Report Conversation")),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          CircleAvatar(
            radius: 40.0,
            backgroundImage: NetworkImage(imageUrl),
          ),
          const SizedBox(height: 6.0),
          Text(
            name,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16.0,
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10.0),
          InsideConversationButtons(
            conversation: conversation,
            chatService: chatService ?? ChatService(FirestoreChatRepository()),
          ),
          const SizedBox(height: 8.0),
        ],
      ),
    );
  }
}

