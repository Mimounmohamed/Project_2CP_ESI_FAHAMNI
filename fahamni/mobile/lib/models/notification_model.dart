import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String title;
  final String? id;
  final String content;
  final DateTime dateTime;
  final bool isRead;
  final String notificationId;
  final String receiverId;
  final String type;
  final String senderId;
  final String conversationId;
  final String tutorId;
  final String serviceId;

  NotificationModel({
    this.id,
    required this.title,
    required this.content,
    required this.dateTime,
    required this.isRead,
    required this.notificationId,
    required this.receiverId,
    required this.type,
    this.senderId = '',
    this.conversationId = '',
    this.tutorId = '',
    this.serviceId = '',
  });

  /// from map transormf a map to dart object
  factory NotificationModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return NotificationModel(
      id: docId,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      dateTime: map['date_time'] != null
          ? (map['date_time'] as Timestamp).toDate()
          : DateTime.now(),
      isRead: map['is_read'] ?? false,
      notificationId: map['notification_id'] ?? docId ?? '',
      receiverId: map['receiver_id'] ?? map['reciever_id'] ?? '',
      type: map['type'] ?? '',
      senderId: map['sender_id'] ?? '',
      conversationId: map['conversation_id'] ?? '',
      tutorId: map['tutor_id'] ?? '',
      serviceId: map['service_id'] ?? '',
    );
  }

  /// to tranform dart object to map or firebase document
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'date_time': Timestamp.fromDate(dateTime),
      'is_read': isRead,
      'notification_id': notificationId,
      'receiver_id': receiverId,
      'reciever_id': receiverId,
      'type': type,
      'sender_id': senderId,
      'conversation_id': conversationId,
      'tutor_id': tutorId,
      'service_id': serviceId,
    };
  }
}
