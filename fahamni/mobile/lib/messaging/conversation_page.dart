import 'dart:io';
import 'package:fahamni/messaging/conversation_doc_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Services/ai_service.dart';
import '../Services/chat_service.dart';
import '../models/chat_model.dart';
import '../models/student_profile.dart';
import '../repositories/firestore_chat_repository.dart';
import 'Message_input.dart';
import 'ai_assistant_sheet.dart';
import 'messagerow.dart';

class ConversationPage extends StatefulWidget {
  final ConversationModel conversation;
  final String imageUrl;
  final String currentUserId;
  final bool openAiOnLoad;

  const ConversationPage({
    super.key,
    required this.conversation,
    required this.imageUrl,
    required this.currentUserId,
    this.openAiOnLoad = false,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final AIService _aiService = AIService();
  final ChatService _chatService =
      ChatService(FirestoreChatRepository());
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _lastMessageCount = 0;
  List<MessageModel> _latestMessages = const <MessageModel>[];
  StudentProfile? _studentProfile;

  @override
  void initState() {
    super.initState();
    if (widget.openAiOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openAiAssistant();
        }
      });
    }
  }

  String _receiverIdFor(String senderId) {
    for (final String participantId in widget.conversation.participants) {
      if (participantId != senderId) {
        return participantId;
      }
    }

    final MessageModel? lastMessage =
        _latestMessages.isNotEmpty ? _latestMessages.last : widget.conversation.lastMessage;
    if (lastMessage != null) {
      if (lastMessage.senderId == senderId) {
        return lastMessage.receiverId;
      }
      return lastMessage.senderId;
    }

    return '';
  }

  void _scrollToBottom({bool animated = true}) {
    if (!_scrollController.hasClients) return;

    final double target = _scrollController.position.maxScrollExtent;
    if (animated) {
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }

    _scrollController.jumpTo(target);
  }

  void _scheduleScrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToBottom(animated: animated);
    });
  }

  Future<void> _handleSend(String text, List<AttachmentModel> attachments, List<File> filesToUpload) async {
    final String senderId = _auth.currentUser?.uid ?? widget.currentUserId;
    final String receiverId = _receiverIdFor(senderId);
    
    if (senderId.isEmpty || receiverId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to identify the conversation recipient.'),
        ),
      );
      return;
    }

    if (text.trim().isEmpty && filesToUpload.isEmpty) return;

    try {
      await _chatService.sendMessage(
        conversationId: widget.conversation.conversationId,
        senderId: senderId,
        receiverId: receiverId,
        content: text,
        controller: _messageController,
        attachments: attachments,
        filesToUpload: filesToUpload,
      );
      _scheduleScrollToBottom();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message failed to send: $error')),
      );
    }
  }

  Future<void> _handleSendToTutor(String text) async {
    final String senderId = _auth.currentUser?.uid ?? widget.currentUserId;
    final String receiverId = _receiverIdFor(senderId);
    if (senderId.isEmpty || receiverId.isEmpty) {
      return;
    }

    await _chatService.sendMessage(
      conversationId: widget.conversation.conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: text,
      controller: null,
    );
  }

  Future<void> _openAiAssistant() async {
    final String currentUserId = _auth.currentUser?.uid ?? widget.currentUserId;
    try {
      _studentProfile ??= await _aiService.getStudentProfile(currentUserId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI assistant unavailable: $error')),
      );
      return;
    }

    if (!mounted || _studentProfile == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AIAssistantSheet(
        aiService: _aiService,
        studentProfile: _studentProfile!,
        conversationMessages: _latestMessages,
        onSendToTutor: _handleSendToTutor,
      ),
    );
  }

  Future<void> _confirmDeleteMessage(BuildContext context, MessageModel message) async {
    final messenger = ScaffoldMessenger.of(context);
    final bool shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete message'),
            content: const Text('Are you sure you want to delete this message?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!mounted || !shouldDelete) return;

    final String userId = _auth.currentUser?.uid ?? widget.currentUserId;
    try {
      await _chatService.deleteMessage(
        messageId: message.id,
        conversationId: widget.conversation.conversationId,
        userId: userId,
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete message: $error')),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String activeUserId = _auth.currentUser?.uid ?? widget.currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(widget.imageUrl),
                ),
                if (widget.conversation.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.participantDisplayName.isNotEmpty
                        ? widget.conversation.participantDisplayName
                        : widget.conversation.conversationName,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1F2937),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.conversation.isOnline)
                    Text(
                      'En ligne',
                      style: GoogleFonts.inter(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openAiAssistant,
            icon: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF000080),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConversationDocPage(
                    imageUrl: widget.imageUrl,
                    name: widget.conversation.conversationName,
                    conversation: widget.conversation,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.info_outline,
              color: Color(0xFF1F2937),
            ),
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
                  return const Center(
                    child: Text('Failed to load messages.'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final List<MessageModel> messages =
                    snapshot.data ?? const <MessageModel>[];
                _latestMessages = messages;

                if (messages.length != _lastMessageCount) {
                  final bool animated = _lastMessageCount != 0;
                  _lastMessageCount = messages.length;
                  _scheduleScrollToBottom(animated: animated);
                }

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Start a conversation with ${widget.conversation.participantDisplayName}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final MessageModel msg = messages[index];
                    final bool isMe = msg.senderId == activeUserId;
                    return MessageRow(
                      message: msg,
                      isMe: isMe,
                      senderAvatarUrl: isMe
                          ? 'https://ui-avatars.com/api/?name=Me&background=000080&color=ffffff'
                          : widget.imageUrl,
                      onLongPress: isMe
                          ? () => _confirmDeleteMessage(context, msg)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          MessageInput(
            controller: _messageController,
            onSend: _handleSend,
          ),
        ],
      ),
    );
  }
}
