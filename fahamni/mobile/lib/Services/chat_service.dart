import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Services/notification_service.dart';
import '../models/chat_model.dart';
import '../models/notification_model.dart';
import '../repositories/chat_repository.dart';

class ChatService {
  ChatService(
    this._chatRepository, {
    NotificationService? notificationService,
  }) : _notificationService = notificationService ?? NotificationService();

  final ChatRepository _chatRepository;
  final NotificationService _notificationService;

  Stream<List<ConversationModel>> getConversations(
    String userId, {
    Object? filter,
  }) {
    return _chatRepository.getConversations(userId, filter: filter).map((conversations) {
      final List<ConversationModel> sortedConversations =
          List<ConversationModel>.from(conversations)
            ..sort((a, b) => _conversationTime(b).compareTo(_conversationTime(a)));
      return sortedConversations;
    });
  }

  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _chatRepository.getMessages(conversationId).map((messages) {
      final List<MessageModel> sortedMessages = List<MessageModel>.from(messages)
        ..sort(
          (a, b) => a.sendingDateTime.compareTo(b.sendingDateTime),
        );
      return sortedMessages;
    });
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required String content,
    String? messageId,
    TextEditingController? controller,
  }) async {
    final String trimmedContent = content.trim();
    if (trimmedContent.isEmpty) return;

    final DateTime timestamp = DateTime.now();
    final MessageModel message = MessageModel(
      messageId: messageId ?? '',
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      content: trimmedContent,
      sendingDateTime: timestamp,
    );

    await _chatRepository.sendMessage(message);
    if (receiverId != senderId && await _notifAllowed(receiverId, 'new_messages')) {
      await _notificationService.sendNotification(
        NotificationModel(
          title: 'New message',
          content: trimmedContent,
          dateTime: timestamp,
          isRead: false,
          notificationId: '',
          receiverId: receiverId,
          type: 'message',
          senderId: senderId,
          conversationId: conversationId,
        ),
      );
    }
    controller?.clear();
  }

  Future<ConversationModel> ensureDirectConversation({
    required String currentUserId,
    required String otherUserId,
  }) {
    return _chatRepository.ensureDirectConversation(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
    );
  }

  ConversationModel buildUpdatedConversationPreview(
    ConversationModel conversation,
    MessageModel lastMessage,
  ) {
    return conversation.copyWith(
      lastMessage: lastMessage,
      lastMessageTime: lastMessage.sendingDateTime,
    );
  }

  DateTime _conversationTime(ConversationModel conversation) {
    return conversation.lastMessage?.sendingDateTime ??
        conversation.createdAt;
  }

  Future<bool> _notifAllowed(String userId, String prefKey) async {
    try {
      final db = FirebaseFirestore.instance;
      final userDoc = await db.collection('users').doc(userId).get();
      final role = userDoc.data()?['role'] as String? ?? 'student';
      final collection = role == 'tutor'
          ? 'tutors'
          : role == 'parent'
              ? 'parents'
              : 'students';
      final doc = await db.collection(collection).doc(userId).get();
      final prefs =
          doc.data()?['notification_prefs'] as Map<String, dynamic>? ?? {};
      return prefs[prefKey] as bool? ?? true;
    } catch (_) {
      return true;
    }
  }
}
