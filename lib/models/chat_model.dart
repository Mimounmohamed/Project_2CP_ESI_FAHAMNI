import 'package:intl/intl.dart'; // Add this to your pubspec.yaml for date formatting
import 'user_model.dart';

enum ChatConversationFilter {
  all,
  group,
}

class ConversationModel {
  final String conversationName;
  final String conversationId;
  final List<String> participants;
  final bool isGroup;
  final UserRole? otherParticipantRole;
  final String participantDisplayName;
  final String participantAvatarUrl;
  final String participantSubtitle;
  final bool isVerified;
  final bool isOnline;
  final MessageModel? lastMessage;
  final DateTime? _lastMessageTime;
  final List<MessageModel> messages;
  final List<String> media;
  final DateTime createdAt;
  final String status;

  ConversationModel({
    required this.conversationId,
    required this.participants,
    this.conversationName = '',
    this.isGroup = false,
    this.otherParticipantRole,
    this.participantDisplayName = '',
    this.participantAvatarUrl = '',
    this.participantSubtitle = '',
    this.isVerified = false,
    this.isOnline = false,
    this.lastMessage,
    DateTime? lastMessageTime,
    this.messages = const [],
    this.media = const [],
    DateTime? createdAt,
    this.status = 'active',
  }) : _lastMessageTime = lastMessageTime,
       createdAt = createdAt ?? DateTime.now();

  ConversationModel copyWith({
    String? conversationName,
    String? conversationId,
    List<String>? participants,
    bool? isGroup,
    UserRole? otherParticipantRole,
    String? participantDisplayName,
    String? participantAvatarUrl,
    String? participantSubtitle,
    bool? isVerified,
    bool? isOnline,
    MessageModel? lastMessage,
    DateTime? lastMessageTime,
    List<MessageModel>? messages,
    List<String>? media,
    DateTime? createdAt,
    String? status,
  }) {
    return ConversationModel(
      conversationId: conversationId ?? this.conversationId,
      participants: participants ?? this.participants,
      conversationName: conversationName ?? this.conversationName,
      isGroup: isGroup ?? this.isGroup,
      otherParticipantRole: otherParticipantRole ?? this.otherParticipantRole,
      participantDisplayName:
          participantDisplayName ?? this.participantDisplayName,
      participantAvatarUrl: participantAvatarUrl ?? this.participantAvatarUrl,
      participantSubtitle: participantSubtitle ?? this.participantSubtitle,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? _lastMessageTime,
      messages: messages ?? this.messages,
      media: media ?? this.media,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  // --- GETTERS FOR UI ---

  // Gets the last message safely

  MessageModel? get _resolvedLastMessage =>
      lastMessage ?? (messages.isNotEmpty ? messages.last : null);
  // Inside your ConversationModel class
  String get lastSenderName {
    if (_resolvedLastMessage == null) return "No messages";

    // Logic: If the senderId is mine, return "You", otherwise return the conversation name
    // Note: You'll need to pass your own userId to this logic or handle it in the UI
    return _resolvedLastMessage!.senderId;
  }

  String get lastMessageText => _resolvedLastMessage?.content ?? "No messages yet";

  String get lastMessageTime {
    final DateTime? timestamp =
        _lastMessageTime ?? _resolvedLastMessage?.sendingDateTime;
    if (timestamp == null) return "";
    // Returns 10:30 AM format
    return DateFormat.jm().format(timestamp);
  }

  int get unreadCount => messages.where((m) => !m.isRead).length;

  // --- DATA METHODS ---

  Map<String, dynamic> toMap() {
    return {
      'conversationName': conversationName,
      'conversationId': conversationId,
      'participants': participants,
      'isGroup': isGroup,
      'participantDisplayName': participantDisplayName,
      'participantAvatarUrl': participantAvatarUrl,
      'participantSubtitle': participantSubtitle,
      'isVerified': isVerified,
      'isOnline': isOnline,
      'lastMessage': lastMessage?.toMap(),
      'lastMessageTime': _lastMessageTime ?? _resolvedLastMessage?.sendingDateTime,
      'createdAt': createdAt,
      'status': status,
      'messages': messages.map((m) => m.toMap()).toList(),
      'media': media,
    };
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    final MessageModel? resolvedLastMessage =
        map['lastMessage'] is Map
        ? MessageModel.fromMap(
            Map<String, dynamic>.from(map['lastMessage'] as Map),
          )
        : map['last_message'] is Map
            ? MessageModel.fromMap(
                Map<String, dynamic>.from(map['last_message'] as Map),
              )
            : null;

    final List<MessageModel> resolvedMessages =
        (map['messages'] as List<dynamic>?)
            ?.map((x) => MessageModel.fromMap(Map<String, dynamic>.from(x as Map)))
            .toList() ??
        [];

    return ConversationModel(
      conversationName: map['conversationName'] ?? map['conversation_name'] ?? '',
      conversationId: map['conversationId'] ?? map['conversation_id'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      isGroup: map['isGroup'] ?? map['is_group'] ?? false,
      participantDisplayName:
          map['participantDisplayName'] ?? map['participant_display_name'] ?? '',
      participantAvatarUrl:
          map['participantAvatarUrl'] ?? map['participant_avatar_url'] ?? '',
      participantSubtitle:
          map['participantSubtitle'] ?? map['participant_subtitle'] ?? '',
      isVerified: map['isVerified'] ?? map['is_verified'] ?? false,
      isOnline: map['isOnline'] ?? map['is_online'] ?? false,
      lastMessage: resolvedLastMessage,
      lastMessageTime: _parseDateTime(
        map['lastMessageTime'] ?? map['last_message_time'],
      ),
      messages: resolvedMessages,
      media: List<String>.from(map['media'] ?? []),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      status: map['status'] ?? 'active',
    );
  }
}

class MessageModel {
  final String messageId;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime sendingDateTime;
  final bool isRead;

  MessageModel({
    required this.messageId,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sendingDateTime,
    this.isRead = false,
  });

  // Helper to create a new instance with updated fields
  MessageModel copyWith({
    String? messageId,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? content,
    DateTime? sendingDateTime,
    bool? isRead,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      sendingDateTime: sendingDateTime ?? this.sendingDateTime,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'conversationId': conversationId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'sendingDateTime': sendingDateTime,
      'isRead': isRead,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      messageId: map['messageId'] ?? map['message_id'] ?? '',
      conversationId: map['conversationId'] ?? map['conversation_id'] ?? '',
      senderId: map['senderId'] ?? map['sender_id'] ?? '',
      receiverId: map['receiverId'] ?? map['receiver_id'] ?? '',
      content: map['content'] ?? '',
      // Safely handle both DateTime and Firestore Timestamp
      sendingDateTime: _parseDateTime(
            map['sendingDateTime'] ?? map['sending_date_time'],
          ) ??
          DateTime.now(),
      isRead: map['isRead'] ?? map['is_read'] ?? false,
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);

  try {
    final dynamic converted = (value as dynamic).toDate();
    if (converted is DateTime) {
      return converted;
    }
  } catch (_) {
    return null;
  }

  return null;
}
