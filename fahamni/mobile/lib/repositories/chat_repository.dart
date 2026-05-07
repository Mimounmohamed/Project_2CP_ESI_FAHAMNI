import '../models/chat_model.dart';

abstract class ChatRepository {
  Stream<List<ConversationModel>> getConversations(
    String userId, {
    Object? filter,
  });

  Stream<List<MessageModel>> getMessages(String conversationId);

  Future<void> sendMessage(MessageModel message);

  Future<ConversationModel> ensureDirectConversation({
    required String currentUserId,
    required String otherUserId,
  });

  Future<void> updateMessage(MessageModel message);

  Future<void> updateConversation(ConversationModel conversation);
}


