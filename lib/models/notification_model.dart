import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String? id;
  final String content;
  final DateTime dateTime;
  final String idRead;
  final String notificationId;
  final String receiverId;
  final String type;

  NotificationModel({
    this.id,
    required this.content,
    required this.dateTime,
    required this.idRead,
    required this.notificationId,
    required this.receiverId,
    required this.type,
  });

  /// from map transormf a map to dart object
  factory NotificationModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return NotificationModel(
      id: docId,
      content: map['content'] ?? '',
      dateTime: map['date_time'] != null
          ? (map['date_time'] as Timestamp).toDate()
          : DateTime.now(),
      idRead: map['is_read'] ?? '',
      notificationId: map['notification_id'] ?? '',
      receiverId: map['reciever_id'] ?? '',
      type: map['type'] ?? '',
    );
  }

  /// to tranform dart object to map or firebase document
  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'date_time': Timestamp.fromDate(dateTime),
      'id_read': idRead,
      'notification_id': notificationId,
      'reciever_id': receiverId,
      'type': type,
    };
  }
}