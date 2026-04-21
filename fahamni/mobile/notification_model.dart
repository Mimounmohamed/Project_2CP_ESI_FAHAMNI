import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String content;
  final DateTime dateTime;
  final bool isRead;
  final String notificationId;
  final String receiverId;
  final String type;

  NotificationModel({
    required this.content,
    required this.dateTime,
    required this.isRead,
    required this.notificationId,
    required this.receiverId,
    required this.type,
  });

  // Convertit un document Firestore en objet Dart
  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      content: map['content'] ?? '',
      // Firestore renvoie un Timestamp, on le convertit en DateTime
      dateTime: (map['date_time'] as Timestamp).toDate(),
      isRead: map['id_read'] ?? false,
      notificationId: map['notification_id'] ?? '',
      receiverId: map['reciever_id'] ?? '',
      type: map['type'] ?? '',
    );
  }

  // Convertit l'objet Dart en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'date_time': Timestamp.fromDate(dateTime),
      'id_read': isRead,
      'notification_id': notificationId,
      'reciever_id': receiverId,
      'type': type,
    };
  }
}