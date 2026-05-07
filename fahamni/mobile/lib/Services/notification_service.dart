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

  /// Send teacher approval notification
  Future<void> sendTeacherApprovalNotification(String teacherUid, String teacherName) async {
    try {
      final notification = NotificationModel(
        title: 'Account Approved',
        content: 'Congratulations! Your account has been verified by admin. You now have full access to all features.',
        dateTime: DateTime.now(),
        isRead: false,
        notificationId: '',
        receiverId: teacherUid,
        type: 'teacher_approved',
        senderId: 'system',
      );
      await sendNotification(notification);
    } catch (e) {
      rethrow;
    }
  }

  /// Send admin notification for new tutor registration
  Future<void> sendAdminNewTutorNotification(String tutorUid, String tutorName) async {
    try {
      final adminIds = await _getAllAdminIds();
      for (final adminId in adminIds) {
        final notification = NotificationModel(
          title: 'New Tutor Registration',
          content: '$tutorName has registered as a tutor and needs approval.',
          dateTime: DateTime.now(),
          isRead: false,
          notificationId: '',
          receiverId: adminId,
          type: 'new_tutor_registration',
          senderId: tutorUid,
          tutorId: tutorUid,
        );
        await sendNotification(notification);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Send admin notification for new report
  Future<void> sendAdminNewReportNotification(String reporterName, String reportedName, String reportType) async {
    try {
      final adminIds = await _getAllAdminIds();
      for (final adminId in adminIds) {
        final notification = NotificationModel(
          title: 'New Report Submitted',
          content: '$reporterName reported $reportedName for $reportType.',
          dateTime: DateTime.now(),
          isRead: false,
          notificationId: '',
          receiverId: adminId,
          type: 'new_report',
          senderId: 'system',
        );
        await sendNotification(notification);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Send admin notification for service issues
  Future<void> sendAdminServiceIssueNotification(String serviceName, String tutorName, String issue) async {
    try {
      final adminIds = await _getAllAdminIds();
      for (final adminId in adminIds) {
        final notification = NotificationModel(
          title: 'Service Issue Reported',
          content: 'Issue with "$serviceName" by $tutorName: $issue',
          dateTime: DateTime.now(),
          isRead: false,
          notificationId: '',
          receiverId: adminId,
          type: 'service_issue',
          senderId: 'system',
        );
        await sendNotification(notification);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get all admin IDs for sending notifications
  Future<List<String>> _getAllAdminIds() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore.collection('admins').get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      // Fallback: return empty list if admins collection doesn't exist or can't be accessed
      return [];
    }
  }
}

typedef NotificatinService = NotificationService;


