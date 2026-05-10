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

      await firestore.collection('notifications').doc(notificationId).set({
        ...notification.toMap(),
        'notification_id': notificationId,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendNotificationOnce(NotificationModel notification) async {
    final String notificationId = notification.notificationId.isNotEmpty
        ? notification.notificationId
        : firestore.collection('notifications').doc().id;
    final doc = await firestore
        .collection('notifications')
        .doc(notificationId)
        .get();
    if (doc.exists) {
      return;
    }
    await sendNotification(
      NotificationModel(
        title: notification.title,
        content: notification.content,
        dateTime: notification.dateTime,
        isRead: notification.isRead,
        notificationId: notificationId,
        receiverId: notification.receiverId,
        type: notification.type,
        senderId: notification.senderId,
        conversationId: notification.conversationId,
        tutorId: notification.tutorId,
        serviceId: notification.serviceId,
      ),
    );
  }

  Future<String> resolveStudentNotificationReceiver(String studentId) async {
    try {
      final childDoc = await firestore
          .collection('children')
          .doc(studentId)
          .get();
      final data = childDoc.data();
      if (childDoc.exists && data != null) {
        final parentUid = (data['parentUid'] ?? data['parent_uid'] ?? '')
            .toString()
            .trim();
        if (parentUid.isNotEmpty) {
          return parentUid;
        }
      }
    } catch (_) {}
    return studentId;
  }

  Future<void> sendStudentRequestResponseNotification({
    required String studentId,
    required String tutorId,
    required bool accepted,
    String serviceId = '',
    String subject = '',
    bool isJoinRequest = false,
  }) async {
    try {
      final receiverId = await resolveStudentNotificationReceiver(studentId);
      final serviceName = await _serviceName(serviceId);
      final context = serviceName.isNotEmpty
          ? ' for $serviceName'
          : subject.isNotEmpty
          ? ' for $subject'
          : '';

      await sendNotification(
        NotificationModel(
          title: accepted ? 'Request Accepted' : 'Request Declined',
          content: accepted
              ? 'Your service request$context has been accepted by the teacher.'
              : 'Your service request$context was declined by the teacher.',
          dateTime: DateTime.now(),
          isRead: false,
          notificationId: '',
          receiverId: receiverId,
          type: isJoinRequest ? 'join_request_response' : 'quote_response',
          senderId: tutorId,
          tutorId: tutorId,
          serviceId: serviceId,
        ),
      );
    } catch (_) {}
  }

  Future<void> sendSessionScheduledNotifications({
    required String sessionId,
    required String tutorId,
    required String serviceId,
    required List<String> studentIds,
    required DateTime startTime,
  }) {
    return _sendSessionNotifications(
      sessionId: sessionId,
      tutorId: tutorId,
      serviceId: serviceId,
      studentIds: studentIds,
      title: 'Session Scheduled',
      type: 'session_scheduled',
      content: 'A new session has been scheduled${_whenText(startTime)}.',
    );
  }

  Future<void> sendSessionRescheduledNotifications({
    required String sessionId,
    required String tutorId,
    required String serviceId,
    required List<String> studentIds,
    required DateTime startTime,
  }) {
    return _sendSessionNotifications(
      sessionId: sessionId,
      tutorId: tutorId,
      serviceId: serviceId,
      studentIds: studentIds,
      title: 'Session Re-Scheduled',
      type: 'session_rescheduled',
      content: 'A session has been re-scheduled${_whenText(startTime)}.',
    );
  }

  Future<void> sendSessionCancelledNotifications({
    required String sessionId,
    required String tutorId,
    required String serviceId,
    required List<String> studentIds,
  }) {
    return _sendSessionNotifications(
      sessionId: sessionId,
      tutorId: tutorId,
      serviceId: serviceId,
      studentIds: studentIds,
      title: 'Session Cancelled',
      type: 'session_cancelled',
      content: 'A session has been cancelled.',
    );
  }

  Future<void> sendSessionReminderNotifications({
    required String sessionId,
    required String tutorId,
    required String serviceId,
    required List<String> studentIds,
    required DateTime startTime,
  }) {
    return _sendSessionNotifications(
      sessionId: sessionId,
      tutorId: tutorId,
      serviceId: serviceId,
      studentIds: studentIds,
      title: 'Upcoming Session',
      type: 'session_reminder',
      content: 'Your session is starting soon${_whenText(startTime)}.',
      onceKeyPrefix: 'session_reminder',
    );
  }

  Future<void> sendStudyResourceNotifications({
    required String resourceId,
    required String tutorId,
    required String title,
    String serviceId = '',
    String sessionId = '',
    List<String> studentIds = const <String>[],
  }) async {
    try {
      final Set<String> recipients = {
        ...studentIds.where((id) => id.isNotEmpty),
      };

      if (recipients.isEmpty && serviceId.isNotEmpty) {
        final serviceDoc = await firestore
            .collection('services')
            .doc(serviceId)
            .get();
        recipients.addAll(
          List<String>.from(serviceDoc.data()?['student_ids'] ?? []),
        );
      }

      if (recipients.isEmpty && sessionId.isNotEmpty) {
        final sessionDoc = await firestore
            .collection('sessions')
            .doc(sessionId)
            .get();
        recipients.addAll(
          List<String>.from(sessionDoc.data()?['student_ids'] ?? []),
        );
        serviceId = serviceId.isNotEmpty
            ? serviceId
            : (sessionDoc.data()?['service_id'] ?? '').toString();
      }

      final resourceTitle = title.trim().isEmpty
          ? 'learning material'
          : title.trim();
      await Future.wait(
        recipients.map((studentId) async {
          final receiverId = await resolveStudentNotificationReceiver(
            studentId,
          );
          await sendNotification(
            NotificationModel(
              title: 'New Resource',
              content:
                  'Your teacher shared new learning material: $resourceTitle.',
              dateTime: DateTime.now(),
              isRead: false,
              notificationId: '',
              receiverId: receiverId,
              type: 'new_resource',
              senderId: tutorId,
              tutorId: tutorId,
              serviceId: serviceId,
            ),
          );
        }),
      );
    } catch (_) {}
  }

  Future<void> _sendSessionNotifications({
    required String sessionId,
    required String tutorId,
    required String serviceId,
    required List<String> studentIds,
    required String title,
    required String content,
    required String type,
    String onceKeyPrefix = '',
  }) async {
    try {
      final Set<String> uniqueStudentIds = {
        ...studentIds.where((id) => id.trim().isNotEmpty),
      };

      await Future.wait(
        uniqueStudentIds.map((studentId) async {
          final receiverId = await resolveStudentNotificationReceiver(
            studentId,
          );
          final notification = NotificationModel(
            title: title,
            content: content,
            dateTime: DateTime.now(),
            isRead: false,
            notificationId: onceKeyPrefix.isEmpty
                ? ''
                : '${onceKeyPrefix}_${sessionId}_$receiverId',
            receiverId: receiverId,
            type: type,
            senderId: tutorId,
            tutorId: tutorId,
            serviceId: serviceId,
          );
          if (onceKeyPrefix.isEmpty) {
            await sendNotification(notification);
          } else {
            await sendNotificationOnce(notification);
          }
        }),
      );
    } catch (_) {}
  }

  Future<String> _serviceName(String serviceId) async {
    if (serviceId.trim().isEmpty) {
      return '';
    }
    try {
      final doc = await firestore.collection('services').doc(serviceId).get();
      return (doc.data()?['name'] ?? '').toString().trim();
    } catch (_) {
      return '';
    }
  }

  String _whenText(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return ' on ${dateTime.day}/${dateTime.month}/${dateTime.year} at $hour:$minute';
  }

  //READ
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return firestore
        .collection('notifications')
        .where('receiver_id', isEqualTo: userId)
        .orderBy('date_time', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => NotificationModel.fromMap(doc.data(), docId: doc.id),
              )
              .toList(),
        );
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
  Future<void> sendTeacherApprovalNotification(
    String teacherUid,
    String teacherName,
  ) async {
    try {
      final notification = NotificationModel(
        title: 'Account Approved',
        content:
            'Congratulations! Your account has been verified by admin. You now have full access to all features.',
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
  Future<void> sendAdminNewTutorNotification(
    String tutorUid,
    String tutorName,
  ) async {
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
  Future<void> sendAdminNewReportNotification(
    String reporterName,
    String reportedName,
    String reportType,
  ) async {
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
  Future<void> sendAdminServiceIssueNotification(
    String serviceName,
    String tutorName,
    String issue,
  ) async {
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
      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection('admins')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      // Fallback: return empty list if admins collection doesn't exist or can't be accessed
      return [];
    }
  }
}

typedef NotificatinService = NotificationService;
