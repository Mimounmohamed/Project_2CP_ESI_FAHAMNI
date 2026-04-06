import 'package:flutter/material.dart';

import '../models/chat_model.dart';
import '../repositories/chat_repository.dart';

class ChatService {
  ChatService(this._chatRepository);

  final ChatRepository _chatRepository;

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
    controller?.clear();
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
}
