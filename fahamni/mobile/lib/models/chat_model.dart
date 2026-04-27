import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'user_model.dart';

enum ChatConversationFilter {
  all,
  group,
}

// --- VOICE FEATURE START ---
enum MessageType {
  text,
  image,
  file,
  voice,
}
// --- VOICE FEATURE END ---

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
    this.messages = const <MessageModel>[],
    this.media = const <String>[],
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

  MessageModel? get _resolvedLastMessage =>
      lastMessage ?? (messages.isNotEmpty ? messages.last : null);

  String get lastSenderName {
    if (_resolvedLastMessage == null) return 'No messages';
    return _resolvedLastMessage!.senderId;
  }

  String get lastMessageText {
    final MessageModel? message = _resolvedLastMessage;
    if (message == null) {
      return 'No messages yet';
    }
    if ((message.text ?? '').trim().isNotEmpty) {
      return message.text!.trim();
    }
    if (message.type == MessageType.voice || message.voiceUrl != null) {
      return 'Voice message';
    }
    if (message.attachments.isNotEmpty) {
      return message.type == MessageType.image ? 'Photo' : 'Attachment';
    }
    return 'No messages yet';
  }

  String get lastMessageTime {
    final DateTime? timestamp =
        _lastMessageTime ?? _resolvedLastMessage?.createdAt.toDate();
    if (timestamp == null) return '';
    return DateFormat.jm().format(timestamp);
  }

  int get unreadCount => messages.where((m) => !m.isRead).length;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
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
      'lastMessageTime': _lastMessageTime ?? _resolvedLastMessage?.createdAt,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      'messages': messages.map((MessageModel m) => m.toMap()).toList(),
      'media': media,
    };
  }

  factory ConversationModel.fromMap(Map<String, dynamic> map) {
    final DateTime? resolvedLastMessageTime = _parseDateTime(
      map['lastMessageTime'] ?? map['last_message_time'] ?? map['last_message_at'],
    );
    final String conversationId =
        map['conversationId']?.toString() ??
        map['conversation_id']?.toString() ??
        '';
    final MessageModel? resolvedLastMessage =
        map['lastMessage'] is Map
            ? MessageModel.fromMap(
                Map<String, dynamic>.from(map['lastMessage'] as Map),
              )
            : map['last_message'] is Map
                ? MessageModel.fromMap(
                    Map<String, dynamic>.from(map['last_message'] as Map),
                  )
                : (map['last_message']?.toString().trim().isNotEmpty ?? false)
                    ? MessageModel(
                        id: '',
                        conversationId: conversationId,
                        senderId: map['sender_id']?.toString() ?? '',
                        receiverId: '',
                        text: map['last_message'].toString(),
                        type: MessageType.text,
                        attachments: const <AttachmentModel>[],
                        voiceUrl: null,
                        voiceDuration: null,
                        createdAt: Timestamp.fromDate(
                          resolvedLastMessageTime ?? DateTime.now(),
                        ),
                        readBy: const <String>[],
                      )
                    : null;

    final List<MessageModel> resolvedMessages =
        (map['messages'] as List<dynamic>?)
            ?.map(
              (dynamic x) => MessageModel.fromMap(
                Map<String, dynamic>.from(x as Map),
              ),
            )
            .toList() ??
        <MessageModel>[];

    final List<String> resolvedParticipants = _parseParticipants(map);

    return ConversationModel(
      conversationName:
          map['conversationName']?.toString() ??
          map['conversation_name']?.toString() ??
          map['user_name']?.toString() ??
          '',
      conversationId: conversationId,
      participants: resolvedParticipants,
      isGroup: map['isGroup'] == true || map['is_group'] == true,
      participantDisplayName:
          map['participantDisplayName']?.toString() ??
          map['participant_display_name']?.toString() ??
          map['user_name']?.toString() ??
          '',
      participantAvatarUrl:
          map['participantAvatarUrl']?.toString() ??
          map['participant_avatar_url']?.toString() ??
          map['user_picture']?.toString() ??
          '',
      participantSubtitle:
          map['participantSubtitle']?.toString() ??
          map['participant_subtitle']?.toString() ??
          '',
      isVerified: map['isVerified'] == true || map['is_verified'] == true,
      isOnline: map['isOnline'] == true || map['is_online'] == true,
      lastMessage: resolvedLastMessage,
      lastMessageTime: resolvedLastMessageTime,
      messages: resolvedMessages,
      media: List<String>.from(map['media'] ?? const <String>[]),
      createdAt:
          _parseDateTime(map['createdAt'] ?? map['created_at']) ??
          DateTime.now(),
      status: map['status']?.toString() ?? 'active',
    );
  }
}

// --- ATTACHMENT FEATURE START ---
class AttachmentModel {
  final String url;
  final String name;
  final int size;
  final String mimeType;

  const AttachmentModel({
    required this.url,
    required this.name,
    required this.size,
    required this.mimeType,
  });

  bool get isImage => mimeType.startsWith('image/');

  String get kind => isImage ? 'image' : 'file';

  int get sizeBytes => size;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'url': url,
      'name': name,
      'size': size,
      'sizeBytes': size,
      'mimeType': mimeType,
      'kind': kind,
    };
  }

  factory AttachmentModel.fromMap(Map<String, dynamic> map) {
    return AttachmentModel(
      url: map['url']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      size: map['size'] is int
          ? map['size'] as int
          : map['sizeBytes'] is int
              ? map['sizeBytes'] as int
              : int.tryParse(map['size']?.toString() ?? '') ??
                  int.tryParse(map['sizeBytes']?.toString() ?? '') ??
                  0,
      mimeType: map['mimeType']?.toString() ?? 'application/octet-stream',
    );
  }
}
// --- ATTACHMENT FEATURE END ---

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String receiverId;
  final String? text;
  // --- VOICE FEATURE START ---
  final MessageType type;
  final String? voiceUrl;
  final int? voiceDuration;
  // --- VOICE FEATURE END ---
  // --- ATTACHMENT FEATURE START ---
  final List<AttachmentModel> attachments;
  // --- ATTACHMENT FEATURE END ---
  final Timestamp createdAt;
  final List<String> readBy;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.type,
    required this.attachments,
    required this.voiceUrl,
    required this.voiceDuration,
    required this.createdAt,
    required this.readBy,
  });

  String get messageId => id;

  String get content => text ?? '';

  DateTime get sendingDateTime => createdAt.toDate();

  bool get isRead => readBy.isNotEmpty;

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? receiverId,
    String? text,
    MessageType? type,
    List<AttachmentModel>? attachments,
    String? voiceUrl,
    int? voiceDuration,
    Timestamp? createdAt,
    List<String>? readBy,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      type: type ?? this.type,
      attachments: attachments ?? this.attachments,
      voiceUrl: voiceUrl ?? this.voiceUrl,
      voiceDuration: voiceDuration ?? this.voiceDuration,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'messageId': id,
      'conversationId': conversationId,
      'conversation_id': conversationId,
      'senderId': senderId,
      'sender_id': senderId,
      'receiverId': receiverId,
      'receiver_id': receiverId,
      'text': text,
      'content': text ?? '',
      'type': type.name,
      'attachments':
          attachments.map((AttachmentModel attachment) => attachment.toMap()).toList(),
      'voiceUrl': voiceUrl,
      'voiceDuration': voiceDuration,
      'createdAt': createdAt,
      'created_at': createdAt,
      'sendingDateTime': createdAt,
      'readBy': readBy,
      'isRead': isRead,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    final String? resolvedText =
        map['text']?.toString() ??
        map['content']?.toString();
    final List<AttachmentModel> resolvedAttachments =
        (map['attachments'] as List<dynamic>?)
            ?.map(
              (dynamic attachment) => AttachmentModel.fromMap(
                Map<String, dynamic>.from(attachment as Map),
              ),
            )
            .toList() ??
        const <AttachmentModel>[];
    final String? resolvedVoiceUrl = map['voiceUrl']?.toString();
    final int? resolvedVoiceDuration = map['voiceDuration'] is int
        ? map['voiceDuration'] as int
        : int.tryParse(map['voiceDuration']?.toString() ?? '');
    final Timestamp resolvedCreatedAt = _parseTimestamp(
      map['createdAt'] ?? map['created_at'] ?? map['sendingDateTime'],
    );
    final String senderId =
        map['senderId']?.toString() ?? map['sender_id']?.toString() ?? '';
    final String receiverId =
        map['receiverId']?.toString() ?? map['receiver_id']?.toString() ?? '';
    final List<String> resolvedReadBy =
        (map['readBy'] as List<dynamic>?)
            ?.map((dynamic value) => value.toString())
            .where((String value) => value.isNotEmpty)
            .toList() ??
        _legacyReadBy(
          map['isRead'] == true || map['is_read'] == true,
          senderId,
          receiverId,
        );

    return MessageModel(
      id:
          map['id']?.toString() ??
          map['messageId']?.toString() ??
          map['message_id']?.toString() ??
          '',
      conversationId:
          map['conversationId']?.toString() ??
          map['conversation_id']?.toString() ??
          '',
      senderId: senderId,
      receiverId: receiverId,
      text: resolvedText,
      type: _parseMessageType(
        map['type']?.toString(),
        attachments: resolvedAttachments,
        voiceUrl: resolvedVoiceUrl,
        text: resolvedText,
      ),
      attachments: resolvedAttachments,
      voiceUrl: resolvedVoiceUrl,
      voiceDuration: resolvedVoiceDuration,
      createdAt: resolvedCreatedAt,
      readBy: resolvedReadBy,
    );
  }
}

List<String> _parseParticipants(Map<String, dynamic> map) {
  final List<String> participants = (map['participants'] as List<dynamic>?)
          ?.map((dynamic value) => value.toString())
          .where((String value) => value.isNotEmpty)
          .toList() ??
      <String>[];

  if (participants.isNotEmpty) {
    return participants;
  }

  final String legacyUserId = map['user_uid']?.toString() ?? '';
  if (legacyUserId.isEmpty) {
    return <String>[];
  }

  return <String>[legacyUserId, 'admin'];
}

List<String> _legacyReadBy(bool isRead, String senderId, String receiverId) {
  if (!isRead) {
    return senderId.isEmpty ? <String>[] : <String>[senderId];
  }

  return <String>{
    if (senderId.isNotEmpty) senderId,
    if (receiverId.isNotEmpty) receiverId,
  }.toList();
}

MessageType _parseMessageType(
  String? rawType, {
  required List<AttachmentModel> attachments,
  required String? voiceUrl,
  required String? text,
}) {
  if (rawType != null && rawType.isNotEmpty) {
    for (final MessageType type in MessageType.values) {
      if (type.name == rawType) {
        return type;
      }
    }
  }

  if ((voiceUrl ?? '').isNotEmpty) {
    return MessageType.voice;
  }
  if (attachments.isNotEmpty) {
    return attachments.every((AttachmentModel attachment) => attachment.isImage)
        ? MessageType.image
        : MessageType.file;
  }
  if ((text ?? '').trim().isNotEmpty) {
    return MessageType.text;
  }

  return MessageType.text;
}

Timestamp _parseTimestamp(dynamic value) {
  if (value is Timestamp) {
    return value;
  }
  if (value is DateTime) {
    return Timestamp.fromDate(value);
  }
  if (value is String) {
    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed != null) {
      return Timestamp.fromDate(parsed);
    }
  }

  try {
    final dynamic converted = (value as dynamic).toDate();
    if (converted is DateTime) {
      return Timestamp.fromDate(converted);
    }
  } catch (_) {
    // Keep fallback below.
  }

  return Timestamp.fromDate(DateTime.now());
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
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
