import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final firestore = FirebaseFirestore.instance;


  //CREATE
  Future<void> sendNotification(NotificationModel notification) async {
    try {
      final String notificationId = notification.notificationId.isNotEmpty
          ? notification.notificationId
          : firestore.collection('notifications').doc().id;

      await firestore
          .collection('notifications')
          .doc(notificationId)
          .set({
        ...notification.toMap(),
        'notification_id': notificationId,
      });
    } catch (e) {
      rethrow;
    }
  }

  //READ
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return firestore
        .collection('notifications')
        .where('receiver_id', isEqualTo: userId)
        .orderBy('date_time', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => NotificationModel.fromMap(doc.data(), docId: doc.id))
        .toList());
  }

  //UPDATE
  Future<void> markAsRead(String docId) async {
    try {
      await firestore.collection('notifications').doc(docId).update({
        'is_read': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAllAsRead(String userId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
        .collection('notifications')
        .where('receiver_id', isEqualTo: userId)
        .where('is_read', isEqualTo: false)
        .get();

    final WriteBatch batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'is_read': true});
    }
    await batch.commit();
  }
  // DELETE
  Future<void> deleteNotification(String docId) async {
    try {
      await firestore.collection('notifications').doc(docId).delete();
    } catch (e) {
      rethrow;
    }
  }
}

typedef NotificatinService = NotificationService;
