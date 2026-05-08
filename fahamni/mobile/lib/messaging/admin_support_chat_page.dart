import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Services/chat_service.dart';
import '../models/chat_model.dart';
import '../repositories/firestore_chat_repository.dart';
import 'Message_input.dart';
import 'messagerow.dart';

class AdminSupportChatPage extends StatefulWidget {
  const AdminSupportChatPage({super.key, required this.conversation});

  final ConversationModel conversation;

  @override
  State<AdminSupportChatPage> createState() => _AdminSupportChatPageState();
}

class _AdminSupportChatPageState extends State<AdminSupportChatPage> {
  final ChatService _chatService = ChatService(FirestoreChatRepository());
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(
    String text,
    List<AttachmentModel> attachments,
    List<File> filesToUpload,
  ) async {
    final String senderId = _auth.currentUser?.uid ?? '';
    if (senderId.isEmpty) return;

    try {
      await _chatService.sendMessage(
        conversationId: widget.conversation.conversationId,
        senderId: senderId,
        receiverId: 'admin',
        content: text,
        controller: _messageController,
        attachments: attachments,
        filesToUpload: filesToUpload,
      );
      _scheduleScrollToBottom();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Message failed to send: $error')));
    }
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = _auth.currentUser?.uid ?? '';
    const String supportAvatar =
        'https://ui-avatars.com/api/?name=App%20Support&background=000080&color=ffffff';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              backgroundColor: Color(0xFFEDEBFF),
              child: Icon(Icons.support_agent, color: Color(0xFF000080)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Support',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  'En ligne',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF16A34A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.info_outline, color: Color(0xFF000080)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessages(
                widget.conversation.conversationId,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load messages.'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? const <MessageModel>[];
                if (messages.length != _lastMessageCount) {
                  _lastMessageCount = messages.length;
                  _scheduleScrollToBottom();
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Send a message to the admin team.',
                      style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final bool isMe = message.senderId == currentUserId;
                    return MessageRow(
                      message: message,
                      isMe: isMe,
                      senderAvatarUrl: isMe
                          ? 'https://ui-avatars.com/api/?name=Me&background=000080&color=ffffff'
                          : supportAvatar,
                    );
                  },
                );
              },
            ),
          ),
          MessageInput(
            controller: _messageController,
            onSend: _send,
            onAiPressed: null,
          ),
        ],
      ),
    );
  }
}
