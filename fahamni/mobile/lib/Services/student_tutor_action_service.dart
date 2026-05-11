import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'auth_.service.dart';
import 'chat_service.dart';
import 'notification_service.dart';
import '../models/chat_model.dart';
import '../models/notification_model.dart';
import '../models/report_model.dart';
import '../models/service_model.dart';
import '../models/student_model.dart';
import '../models/tutor_model.dart';
import '../models/user_model.dart';
import '../repositories/firestore_chat_repository.dart';

class StudentTutorActionService {
  StudentTutorActionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ChatService? chatService,
    NotificationService? notificationService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _chatService =
           chatService ??
           ChatService(FirestoreChatRepository(firestore: firestore)),
       _notificationService = notificationService ?? NotificationService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ChatService _chatService;
  final NotificationService _notificationService;

  Future<StudentModel> getCurrentStudent() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You need to be signed in first.');
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('students')
        .doc(currentUser.uid)
        .get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Student profile not found.');
    }

    return StudentModel.fromMap({...snapshot.data()!, 'uid': snapshot.id});
  }

  Future<Map<String, dynamic>> _getCurrentUserProfile() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You need to be signed in first.');
    }

    // Try student collection first
    DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('students')
        .doc(currentUser.uid)
        .get();
    if (snapshot.exists && snapshot.data() != null) {
      return {
        'data': {...snapshot.data()!, 'uid': snapshot.id},
        'collection': 'students',
      };
    }

    // Fallback to parent collection
    snapshot = await _firestore
        .collection('parents')
        .doc(currentUser.uid)
        .get();
    if (snapshot.exists && snapshot.data() != null) {
      return {
        'data': {...snapshot.data()!, 'uid': snapshot.id},
        'collection': 'parents',
      };
    }

    throw Exception('Student profile not found.');
  }

  Future<bool> isFavoriteTutor(String tutorId) async {
    final profile = await _getCurrentUserProfile();
    final data = profile['data'] as Map<String, dynamic>;
    final favoriteTeachers = List<String>.from(data['favorite_teachers'] ?? []);
    return favoriteTeachers.contains(tutorId);
  }

  Future<StudentModel?> _tryGetCurrentStudent() async {
    try {
      return await getCurrentStudent();
    } catch (_) {
      return null;
    }
  }

  Future<bool> toggleFavoriteTutor(String tutorId) async {
    final profile = await _getCurrentUserProfile();
    final data = profile['data'] as Map<String, dynamic>;
    final collection = profile['collection'] as String;
    final uid = data['uid'] as String;
    final favoriteTeachers = List<String>.from(data['favorite_teachers'] ?? []);
    final bool isFavorite = favoriteTeachers.contains(tutorId);

    await _firestore.collection(collection).doc(uid).set(<String, dynamic>{
      'favorite_teachers': isFavorite
          ? FieldValue.arrayRemove(<String>[tutorId])
          : FieldValue.arrayUnion(<String>[tutorId]),
    }, SetOptions(merge: true));

    return !isFavorite;
  }

  Future<void> createBookingRequest({
    required TutorModel tutor,
    ServiceModel? service,
    String? studentId,
    String? studentName,
    String? studentLevel,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You need to be signed in first.');
    }

    String requestStudentId = studentId?.trim() ?? '';
    String requestStudentName = studentName?.trim() ?? '';
    String requestStudentLevel = studentLevel?.trim() ?? '';

    if (requestStudentId.isEmpty) {
      final StudentModel? currentStudent = await _tryGetCurrentStudent();
      if (currentStudent != null) {
        requestStudentId = currentStudent.uid;
        requestStudentName =
            '${currentStudent.firstName} ${currentStudent.lastName}'.trim();
        requestStudentLevel = currentStudent.schoolLevel;
      } else {
        throw Exception('Please select a child before booking this service.');
      }
    }

    if (requestStudentName.isEmpty) {
      requestStudentName = 'Student';
    }

    if (service != null) {
      final DocumentReference<Map<String, dynamic>> serviceRef = _firestore
          .collection('services')
          .doc(service.serviceId);

      await _firestore.runTransaction((transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> serviceSnap =
            await transaction.get(serviceRef);
        if (!serviceSnap.exists) return;

        final List<String> pendingIds = List<String>.from(
          serviceSnap.data()?['pending_ids'] ?? [],
        );
        final List<String> studentIds = List<String>.from(
          serviceSnap.data()?['student_ids'] ?? [],
        );

        if (studentIds.contains(requestStudentId)) {
          throw Exception('This student is already enrolled in this service.');
        }
        if (pendingIds.contains(requestStudentId)) {
          throw Exception(
            'A join request is already pending for this student.',
          );
        }

        pendingIds.add(requestStudentId);
        transaction.update(serviceRef, {
          'pending_ids': pendingIds,
          'updated_at': Timestamp.now(),
        });
      });

      await _notificationService.sendNotification(
        NotificationModel(
          title: 'New join request',
          content:
              '$requestStudentName sent a join request for ${service.name}.',
          dateTime: DateTime.now(),
          isRead: false,
          notificationId: '',
          receiverId: tutor.uid,
          type: 'join_request',
          senderId: requestStudentId,
          tutorId: tutor.uid,
          serviceId: service.serviceId,
        ),
      );

      return;
    }

    // Prevent duplicate quote: skip creation if a pending quote already exists
    // for this student+tutor+service combination.
    for (final collection in ['quotes', 'quote_requests']) {
      Query<Map<String, dynamic>> q = _firestore
          .collection(collection)
          .where('student_id', isEqualTo: requestStudentId)
          .where('tutor_id', isEqualTo: tutor.uid)
          .where('status', isEqualTo: 'pending');
      if (service != null) {
        q = q.where('service_id', isEqualTo: service.serviceId);
      }
      final existing = await q.limit(1).get();
      if (existing.docs.isNotEmpty) return;
    }

    final DocumentReference<Map<String, dynamic>> quoteRef = _firestore
        .collection('quotes')
        .doc();

    await quoteRef.set({
      'quote_id': quoteRef.id,
      'student_id': requestStudentId,
      'tutor_id': tutor.uid,
      'service_id': service?.serviceId ?? '',
      'subject': service?.subject ?? tutor.expertiseDomain,
      'level': service?.level ?? requestStudentLevel,
      'objective': service?.name.isNotEmpty == true
          ? 'Book session for ${service!.name}'
          : 'Book a session with ${tutor.firstName} ${tutor.lastName}',
      'frequency': 'To be discussed',
      'duration': service != null ? '${service.duration} min' : '60 min',
      'budget': service != null
          ? '${service.price.toInt()} DA'
          : 'To be discussed',
      'status': 'pending',
      'created_at': Timestamp.now(),
    });

    await _notificationService.sendNotification(
      NotificationModel(
        title: 'New quote request',
        content:
            '$requestStudentName sent a quote request${service != null ? ' for ${service.name}' : ''}.',
        dateTime: DateTime.now(),
        isRead: false,
        notificationId: '',
        receiverId: tutor.uid,
        type: 'quote_request',
        senderId: currentUser.uid,
        tutorId: tutor.uid,
        serviceId: service?.serviceId ?? '',
      ),
    );
  }

  Future<void> createReport({
    required String reportedId,
    required String reportedName,
    required ReportType type,
    required String text,
    Map<String, dynamic> extraData = const <String, dynamic>{},
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You need to be signed in first.');
    }

    final AuthService authService = AuthService();
    final UserModel? reporter = await authService.getCurrentUserProfile();
    if (reporter == null) {
      throw Exception('Unable to load reporter profile.');
    }

    final DocumentReference<Map<String, dynamic>> reportRef = _firestore
        .collection('reports')
        .doc();

    final ReportModel report = ReportModel(
      reportId: reportRef.id,
      reporterUid: reporter.uid,
      reporterName: '${reporter.firstName} ${reporter.lastName}'.trim(),
      reportedId: reportedId,
      reportedName: reportedName,
      type: type,
      text: text,
      createdAt: DateTime.now(),
    );

    await reportRef.set({...report.toMap(), ...extraData});

    // Send admin notification for new report
    try {
      await _notificationService.sendAdminNewReportNotification(
        report.reporterName,
        report.reportedName,
        report.type.name,
      );
    } catch (e) {
      // Don't fail the report creation if admin notification fails
      debugPrint('Failed to send admin notification for report: $e');
    }
  }

  Future<void> createQuoteRequest({
    required TutorModel tutor,
    required String studentId,
    required String subject,
    required String description,
    required String teachingMode,
    required int sessionsCount,
    required int durationMinutes,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You need to be signed in first.');
    }

    if (studentId.isEmpty) {
      throw Exception('Please select a student for the quote request.');
    }

    final DocumentReference<Map<String, dynamic>> quoteRef = _firestore
        .collection('quote_requests')
        .doc();

    await quoteRef.set({
      'quote_id': quoteRef.id,
      'student_id': studentId,
      'tutor_id': tutor.uid,
      'service_id': '',
      'subject': subject,
      'level': '',
      'objective': 'Quote request for $subject',
      'description': description,
      'teaching_mode': teachingMode,
      'frequency': 'To be discussed',
      'duration': '$durationMinutes min',
      'budget': 'To be discussed',
      'sessions_count': sessionsCount,
      'status': 'pending',
      'created_at': Timestamp.now(),
    });

    // Resolve the student/child display name for the notification content
    String studentDisplayName = 'A student';
    try {
      final studentDoc = await _firestore
          .collection('students')
          .doc(studentId)
          .get();
      if (studentDoc.exists && studentDoc.data() != null) {
        final d = studentDoc.data()!;
        final full =
            '${(d['first_name'] ?? '').toString().trim()} ${(d['last_name'] ?? '').toString().trim()}'
                .trim();
        if (full.isNotEmpty) studentDisplayName = full;
      } else {
        final childDoc = await _firestore
            .collection('children')
            .doc(studentId)
            .get();
        if (childDoc.exists && childDoc.data() != null) {
          final n = (childDoc.data()!['name'] ?? '').toString().trim();
          if (n.isNotEmpty) studentDisplayName = n;
        }
      }
    } catch (_) {}

    await _notificationService.sendNotification(
      NotificationModel(
        title: 'New quote request',
        content:
            '$studentDisplayName sent you a quote request for $subject.\n$description',
        dateTime: DateTime.now(),
        isRead: false,
        notificationId: '',
        receiverId: tutor.uid,
        type: 'quote_request',
        senderId: currentUser.uid,
        tutorId: tutor.uid,
        serviceId: '',
      ),
    );
  }

  Future<ConversationModel> createOrGetConversation({
    required TutorModel tutor,
  }) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You need to be signed in first.');
    }
    final ConversationModel conversation = await _chatService
        .ensureDirectConversation(
          currentUserId: currentUser.uid,
          otherUserId: tutor.uid,
        );

    return conversation.copyWith(
      conversationName: '${tutor.firstName} ${tutor.lastName}'.trim(),
      participantDisplayName: '${tutor.firstName} ${tutor.lastName}'.trim(),
      participantAvatarUrl: tutor.picture,
      participantSubtitle: tutor.expertiseDomain,
      isVerified: tutor.certified,
      isOnline: tutor.isAvailable,
    );
  }
}
