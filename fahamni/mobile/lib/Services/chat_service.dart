import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:io';
import '../Services/notification_service.dart';
import '../Services/ressource_service.dart';
import '../models/chat_model.dart';
import '../models/notification_model.dart';
import '../repositories/chat_repository.dart';

class ChatService {
  ChatService(
    this._chatRepository, {
    NotificationService? notificationService,
    ResourceService? resourceService,
  }) : _notificationService = notificationService ?? NotificationService(),
       _resourceService = resourceService ?? ResourceService();

  final ChatRepository _chatRepository;
  final NotificationService _notificationService;
  final ResourceService _resourceService;

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
    List<AttachmentModel> attachments = const <AttachmentModel>[],
    List<File> filesToUpload = const <File>[],
  }) async {
    final String trimmedContent = content.trim();
    if (trimmedContent.isEmpty && attachments.isEmpty && filesToUpload.isEmpty) return;

    final List<AttachmentModel> uploadedAttachments = [];
    for (final File file in filesToUpload) {
      final AttachmentModel uploadedAttachment = await _resourceService.uploadChatAttachment(
        file: file,
        conversationId: conversationId,
        userId: senderId,
      );
      uploadedAttachments.add(uploadedAttachment);
    }

    final List<AttachmentModel> allAttachments = [
      ...attachments,
      ...uploadedAttachments,
    ];

    final DateTime timestamp = DateTime.now();
    final MessageType messageType = allAttachments.isNotEmpty
        ? allAttachments.any((AttachmentModel attachment) => attachment.isImage)
            ? MessageType.image
            : MessageType.file
        : MessageType.text;

    final MessageModel message = MessageModel(
      id: messageId ?? '',
      conversationId: conversationId,
      senderId: senderId,
      receiverId: receiverId,
      text: trimmedContent.isEmpty ? null : trimmedContent,
      type: messageType,
      attachments: allAttachments,
      voiceUrl: null,
      voiceDuration: null,
      createdAt: Timestamp.fromDate(timestamp),
      readBy: const <String>[],
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

  /// Gets all attachments from a conversation's messages as a stream
  Stream<List<AttachmentModel>> getConversationAttachments(String conversationId) {
    return getMessages(conversationId).map((messages) {
      final List<AttachmentModel> allAttachments = [];
      for (final MessageModel message in messages) {
        allAttachments.addAll(message.attachments);
      }
      return allAttachments;
    });
  }

  /// Gets all media (image) URLs from a conversation's messages as a stream
  Stream<List<String>> getConversationMediaUrls(String conversationId) {
    return getConversationAttachments(conversationId).map((attachments) {
      return attachments
          .where((attachment) => attachment.isImage)
          .map((attachment) => attachment.url)
          .toList();
    });
  }

  /// Gets all file attachments (non-images) from a conversation's messages as a stream
  Stream<List<AttachmentModel>> getConversationFileAttachments(String conversationId) {
    return getConversationAttachments(conversationId).map((attachments) {
      return attachments.where((attachment) => !attachment.isImage && !attachment.isLink).toList();
    });
  }

  /// Gets all link attachments from a conversation's messages as a stream
  Stream<List<AttachmentModel>> getConversationLinkAttachments(String conversationId) {
    return getConversationAttachments(conversationId).map((attachments) {
      return attachments.where((attachment) => attachment.isLink).toList();
    });
  }

  /// Creates a link attachment model from a URL and title
  AttachmentModel createLinkAttachment({
    required String url,
    required String title,
  }) {
    return AttachmentModel(
      url: url,
      name: title,
      size: 0,
      mimeType: 'application/link',
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

  /// Soft deletes a message by marking it as deleted
  /// Only the sender can delete their own messages
  Future<void> deleteMessage({
    required String messageId,
    required String conversationId,
    required String userId,
  }) async {
    try {
      // First, get the message to verify ownership
      final messages = await _chatRepository.getMessages(conversationId).first;
      final message = messages.firstWhere(
        (msg) => msg.id == messageId,
        orElse: () => throw Exception('Message not found'),
      );

      // Check if user is the sender
      if (message.senderId != userId) {
        throw Exception('You can only delete your own messages');
      }

      // Check if message is already deleted
      if (message.isDeleted) {
        throw Exception('Message is already deleted');
      }

      // Create updated message with soft delete
      final updatedMessage = message.copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
      );

      // Update the message in Firestore
      await _chatRepository.updateMessage(updatedMessage);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Soft deletes a conversation by marking it as deleted
  /// Only participants can delete conversations
  Future<void> deleteConversation({
    required String conversationId,
    required String userId,
  }) async {
    try {
      // First, get the conversation to verify participation
      final conversations = await _chatRepository.getConversations(userId).first;
      final conversation = conversations.firstWhere(
        (conv) => conv.conversationId == conversationId,
        orElse: () => throw Exception('Conversation not found'),
      );

      // Check if user is a participant
      if (!conversation.participants.contains(userId)) {
        throw Exception('You are not a participant in this conversation');
      }

      // Check if conversation is already deleted
      if (conversation.isDeleted) {
        throw Exception('Conversation is already deleted');
      }

      // Create updated conversation with soft delete
      final updatedConversation = conversation.copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
      );

      // Update the conversation in Firestore
      await _chatRepository.updateConversation(updatedConversation);
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }
}


