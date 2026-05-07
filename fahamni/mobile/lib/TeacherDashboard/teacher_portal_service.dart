import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'models/teacher_portal_models.dart';
import '../Services/notification_service.dart';
import '../models/notification_model.dart';
import '../models/quote_model.dart';
import '../models/service_model.dart';
import '../models/session_model.dart';
import '../models/student_model.dart';
import '../models/tutor_model.dart';
import '../models/user_model.dart';

class TeacherPortalService {
  TeacherPortalService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<TeacherServicesDashboardData> loadDashboard() async {
    final TutorModel tutor = await _loadCurrentTutor();
    final List<ServiceModel> services = await _loadServices(tutor.uid);

    // Collect all pending_ids from services
    final Set<String> pendingStudentIds = {};
    for (var service in services) {
      pendingStudentIds.addAll(service.pendingIds);
    }

    // Combine student IDs to fetch
    final Set<String> allStudentIds = {...pendingStudentIds};

    final Map<String, StudentModel> students = await _loadStudentsByIds(
      allStudentIds,
    );
    final Set<String> childIds = await _loadChildIdsByIds(allStudentIds);

    // Create joinRequests from pending_ids of services
    final List<TeacherJoinRequestDetail> serviceRequests = [];
    for (var service in services) {
      for (var studentId in service.pendingIds) {
        final student = students[studentId];
        if (student == null) continue;

        serviceRequests.add(
          TeacherJoinRequestDetail(
            quote: QuoteModel(
              quoteId: 'pending_${studentId}_${service.serviceId}',
              studentId: studentId,
              tutorId: tutor.uid,
              serviceId: service.serviceId,
              serviceName: service.name,
              subject: service.subject,
              level: service.level,
              objective: 'Join Request for ${service.name}',
              frequency: '${service.sessionsnum} sessions',
              duration: '${service.duration} min',
              budget: '${service.price} DA',
              status: QuoteStatus.pending,
              createdAt:
                  service.updatedAt ?? service.createdAt ?? DateTime.now(),
            ),
            studentName: _studentName(student),
            studentLevel: student.schoolLevel,
            studentAvatar: student.picture,
            serviceTitle: service.name,
            description:
                'Student requested to join your service: ${service.name}',
            subject: service.subject,
            teachingMode: service.mode,
            sessionsCount: service.sessionsnum,
            sessionDurationLabel: '${service.duration} min',
            createdAtLabel: 'Now',
            isChild: childIds.contains(studentId),
          ),
        );
      }
    }

    final List<TeacherJoinRequestDetail> joinRequests = serviceRequests;

    // If no join requests constructed from service.pendingIds, try to infer
    // join requests from recent notifications as a fallback (covers timing issues).
    if (joinRequests.isEmpty) {
      try {
        final QuerySnapshot<Map<String, dynamic>> notifSnap = await _firestore
            .collection('notifications')
            .where('tutor_id', isEqualTo: tutor.uid)
            .where('type', isEqualTo: 'join_request')
            .orderBy('date_time', descending: true)
            .get();

        final Set<String> senderIds = {};
        for (final d in notifSnap.docs) {
          final s = d.data()['sender_id'] as String? ?? '';
          if (s.isNotEmpty) senderIds.add(s);
        }

        final Map<String, StudentModel> notifStudents =
            await _loadStudentsByIds(senderIds);

        for (final d in notifSnap.docs) {
          final data = d.data();
          final String sender = data['sender_id'] as String? ?? '';
          if (sender.isEmpty) continue;
          final String serviceId = data['service_id'] ?? '';
          ServiceModel? svc;
          try {
            svc = services.firstWhere((s) => s.serviceId == serviceId);
          } catch (_) {
            svc = null;
          }
          final student = notifStudents[sender];
          joinRequests.add(TeacherJoinRequestDetail(
            quote: QuoteModel(
              quoteId: 'notif_${d.id}',
              studentId: sender,
              tutorId: tutor.uid,
              serviceId: serviceId,
              serviceName: svc?.name ?? '',
              subject: svc?.subject ?? '',
              level: '',
              objective: 'Join Request for ${svc?.name ?? ''}',
              frequency: svc != null ? '${svc.sessionsnum} sessions' : '',
              duration: svc != null ? '${svc.duration} min' : '',
              budget: svc != null ? '${svc.price} DA' : '',
              status: QuoteStatus.pending,
              createdAt: (data['date_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
            ),
            studentName: _studentName(student),
            studentLevel: student?.schoolLevel ?? '',
            studentAvatar: student?.picture ?? '',
            serviceTitle: svc?.name ?? (data['content'] ?? ''),
            description: data['content'] ?? '',
            subject: svc?.subject ?? '',
            teachingMode: svc?.mode ?? '',
            sessionsCount: svc?.sessionsnum ?? 0,
            sessionDurationLabel: svc != null ? '${svc.duration} min' : '',
            createdAtLabel: 'Now',
            isChild: childIds.contains(sender),
          ));
        }
      } catch (_) {}
    }

    joinRequests.sort((a, b) {
      final DateTime aDate =
          a.quote.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bDate =
          b.quote.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return TeacherServicesDashboardData(
      tutor: tutor,
      services: services,
      joinRequests: joinRequests,
    );
  }

  Future<ServiceModel> createService(TeacherServiceDraft draft) async {
    final TutorModel tutor = await _loadCurrentTutor();
    final DocumentReference<Map<String, dynamic>> doc = _firestore
        .collection('services')
        .doc();
    final Timestamp now = Timestamp.now();

    final ServiceModel model = ServiceModel(
      serviceId: doc.id,
      tutorId: tutor.uid,
      name: draft.name,
      area: draft.domain,
      level: draft.grade,
      subject: draft.domain.toUpperCase(),
      mode: draft.mode,
      description: draft.description,
      price: draft.price,
      duration: draft.sessionDurationMinutes,
      isActive: true,
      maxStudents: draft.membersCount,
      enrollednum: 0,
      sessionsnum: draft.sessionsCount,
      picture: draft.imagePath,
      studentIds: const [],
      pendingIds: const [],
      createdAt: now.toDate(),
      updatedAt: now.toDate(),
    );

    await doc.set({...model.toMap(), 'created_at': now, 'updated_at': now});

    return model;
  }

  Future<void> updateServiceStatus({
    required String serviceId,
    required bool isActive,
  }) async {
    await _firestore.collection('services').doc(serviceId).update({
      'is_active': isActive,
      'updated_at': Timestamp.now(),
    });
  }

  Future<void> deleteService(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).delete();
  }

  Future<void> respondToQuote({
    required TeacherJoinRequestDetail request,
    required QuoteStatus status,
    TeacherQuoteResponseDraft? response,
  }) async {
    final TutorModel currentTutor = await _loadCurrentTutor();
    // If it's a join request from the pending_ids of a service
    if (request.quote.quoteId.startsWith('pending_')) {
      final studentId = request.quote.studentId;
      final serviceId = request.quote.serviceId;
      final serviceRef = _firestore.collection('services').doc(serviceId);

      if (status == QuoteStatus.accepted) {
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(serviceRef);
          if (!snapshot.exists) return;

          final List studentIds = List<String>.from(
            snapshot.data()?['student_ids'] ?? [],
          );
          final List pendingIds = List<String>.from(
            snapshot.data()?['pending_ids'] ?? [],
          );
          int enrolled = snapshot.data()?['enrolled_num'] ?? 0;

          pendingIds.remove(studentId);
          if (!studentIds.contains(studentId)) {
            studentIds.add(studentId);
            enrolled++;
          }

          transaction.update(serviceRef, {
            'student_ids': studentIds,
            'pending_ids': pendingIds,
            'enrolled_num': enrolled,
            'updated_at': Timestamp.now(),
          });
        });
        // notify the requester (student or parent who initiated the join request)
        try {
          final NotificationService ns = NotificationService();
          // For join requests, the studentId is the one who should receive the notification
          // If it was sent by a parent on behalf of a child, the studentId will be the child
          // If it was sent directly by a student, the studentId will be the sender
          final String receiver = studentId;
          await ns.sendNotification(
            NotificationModel(
              title: 'Join request accepted',
              content: '${request.studentName} has been accepted to ${request.serviceTitle}.',
              dateTime: DateTime.now(),
              isRead: false,
              notificationId: '',
              receiverId: receiver,
              type: 'join_request_response',
              senderId: currentTutor.uid,
              tutorId: currentTutor.uid,
              serviceId: serviceId,
            ),
          );
        } catch (e) {
          // Log the error but don't fail the operation
          debugPrint('Failed to send join request acceptance notification: $e');
        }
      } else {
        await serviceRef.update({
          'pending_ids': FieldValue.arrayRemove([studentId]),
          'updated_at': Timestamp.now(),
        });
        // notify the requester about rejection
        try {
          final NotificationService ns = NotificationService();
          // For join requests, the studentId is the one who should receive the notification
          final String receiver = studentId;
          await ns.sendNotification(
            NotificationModel(
              title: 'Join request rejected',
              content: '${request.studentName} join request for ${request.serviceTitle} was rejected.',
              dateTime: DateTime.now(),
              isRead: false,
              notificationId: '',
              receiverId: receiver,
              type: 'join_request_response',
              senderId: currentTutor.uid,
              tutorId: currentTutor.uid,
              serviceId: serviceId,
            ),
          );
        } catch (e) {
          // Log the error but don't fail the operation
          debugPrint('Failed to send join request rejection notification: $e');
        }
      }
      return;
    }

    // Traditional Quote Request logic
    final _QuoteDocumentLocation location = await _locateQuoteDocument(
      request.quote.quoteId,
    );

    // If accepting a traditional quote that points to a specific service
    if (request.quote.serviceId.isNotEmpty) {
      final studentId = request.quote.studentId;
      final serviceId = request.quote.serviceId;
      final serviceRef = _firestore.collection('services').doc(serviceId);

      await _firestore.runTransaction((transaction) async {
        final serviceSnap = await transaction.get(serviceRef);
        if (serviceSnap.exists) {
          final List studentIds = List<String>.from(
            serviceSnap.data()?['student_ids'] ?? [],
          );
          final List pendingIds = List<String>.from(
            serviceSnap.data()?['pending_ids'] ?? [],
          );
          int enrolled = serviceSnap.data()?['enrolled_num'] ?? 0;

          pendingIds.remove(studentId);

          if (status == QuoteStatus.accepted &&
              !studentIds.contains(studentId)) {
            studentIds.add(studentId);
            enrolled++;
          }

          transaction.update(serviceRef, {
            'student_ids': studentIds,
            'pending_ids': pendingIds,
            'enrolled_num': enrolled,
            'updated_at': Timestamp.now(),
          });
        }

        transaction.update(location.reference, {
          'status': status.name,
          'response_price': response?.priceLabel ?? '',
          'response_sessions_count': response?.sessionsCount ?? 0,
          'updated_at': Timestamp.now(),
        });
      });
      await _markDuplicateQuoteDocumentsResponded(
        request.quote,
        status,
        response,
        except: location.reference,
      );
      return;
    }

    // Default update for other quote statuses or custom quotes
    await location.reference.update({
      'status': status.name,
      'response_price': response?.priceLabel ?? '',
      'response_sessions_count': response?.sessionsCount ?? 0,
      'updated_at': Timestamp.now(),
    });
    await _markDuplicateQuoteDocumentsResponded(
      request.quote,
      status,
      response,
      except: location.reference,
    );
  }

  Future<void> createSession({
    required TeacherJoinRequestDetail request,
    required TeacherSessionDraft draft,
  }) async {
    final TutorModel tutor = await _loadCurrentTutor();
    final DocumentReference<Map<String, dynamic>> doc = _firestore
        .collection('sessions')
        .doc();
    final DateTime startTime = DateTime(
      draft.date.year,
      draft.date.month,
      draft.date.day,
      draft.startTime.hour,
      draft.startTime.minute,
    );
    final DateTime endTime = startTime.add(
      Duration(minutes: draft.durationMinutes),
    );

    final SessionModel session = SessionModel(
      sessionId: doc.id,
      serviceId: request.quote.serviceId,
      studentIds: [request.quote.studentId],
      tutorId: tutor.uid,
      status: SessionStatus.Planned,
      type: request.serviceTitle,
      modality: draft.sessionType,
      mode: draft.sessionType,
      meetingLink: draft.meetingLink,
      date: DateTime(draft.date.year, draft.date.month, draft.date.day),
      startTime: startTime,
      endTime: endTime,
    );

    await doc.set(session.toMap());
  }

  Future<void> rescheduleSession({
    required String sessionId,
    required TeacherSessionDraft draft,
  }) async {
    final DateTime startTime = DateTime(
      draft.date.year,
      draft.date.month,
      draft.date.day,
      draft.startTime.hour,
      draft.startTime.minute,
    );
    final DateTime endTime = startTime.add(
      Duration(minutes: draft.durationMinutes),
    );

    await _firestore.collection('sessions').doc(sessionId).update({
      'date': Timestamp.fromDate(
        DateTime(draft.date.year, draft.date.month, draft.date.day),
      ),
      'start_time': Timestamp.fromDate(startTime),
      'end_time': Timestamp.fromDate(endTime),
      'modality': draft.sessionType,
      'meeting_link': draft.meetingLink,
      'updated_at': Timestamp.now(),
    });
  }

  Future<String?> findLatestSessionId(TeacherJoinRequestDetail request) async {
    final TutorModel tutor = await _loadCurrentTutor();
    Query<Map<String, dynamic>> query = _firestore
        .collection('sessions')
        .where('tutor_id', isEqualTo: tutor.uid)
        .where('student_ids', arrayContains: request.quote.studentId);

    if (request.quote.serviceId.isNotEmpty) {
      query = query.where('service_id', isEqualTo: request.quote.serviceId);
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
    if (snapshot.docs.isEmpty) {
      return null;
    }

    snapshot.docs.sort((a, b) {
      final Timestamp? aDate = a.data()['date'] as Timestamp?;
      final Timestamp? bDate = b.data()['date'] as Timestamp?;
      return (bDate?.millisecondsSinceEpoch ?? 0).compareTo(
        aDate?.millisecondsSinceEpoch ?? 0,
      );
    });

    return snapshot.docs.first.id;
  }

  Future<void> addResource({
    required TeacherJoinRequestDetail request,
    required TeacherResourceDraft draft,
  }) async {
    final TutorModel tutor = await _loadCurrentTutor();
    final DocumentReference<Map<String, dynamic>> doc = _firestore
        .collection('resources')
        .doc();

    await doc.set({
      'resource_id': doc.id,
      'tutor_id': tutor.uid,
      'session_id': request.quote.quoteId,
      'service_id': request.quote.serviceId,
      'student_id': request.quote.studentId,
      'title': draft.name,
      'subject': request.subject,
      'level': request.studentLevel,
      'description': request.description,
      'content_type': draft.type == TeacherResourceType.link
          ? 'link'
          : 'document',
      'access_level': 'request',
      'allowed_users': [request.quote.studentId, tutor.uid],
      'is_public': false,
      'added_at': Timestamp.now(),
      'file_url': draft.filePath,
      'file_name': draft.filePath.split('/').last,
      'link_url': draft.link,
    });
  }

  Future<TutorModel> _loadCurrentTutor() async {
    final User? currentUser = await _auth.authStateChanges().first;
    if (currentUser == null) {
      throw Exception('You need to be signed in to manage teacher services.');
    }

    final DocumentSnapshot<Map<String, dynamic>> userSnapshot = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!userSnapshot.exists || userSnapshot.data() == null) {
      throw Exception('User profile not found in users collection.');
    }

    final Map<String, dynamic> userData = userSnapshot.data()!;
    if (userData['role'] != 'tutor') {
      throw Exception('This account does not have the teacher role.');
    }

    final DocumentSnapshot<Map<String, dynamic>> tutorSnapshot =
        await _firestore.collection('tutors').doc(currentUser.uid).get();
    final Map<String, dynamic> mergedData = <String, dynamic>{
      ...userData,
      if (tutorSnapshot.data() != null) ...tutorSnapshot.data()!,
    };

    return TutorModel.fromMap({...mergedData, 'uid': userSnapshot.id});
  }

  Future<List<ServiceModel>> _loadServices(String tutorId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('services')
        .where('tutor_id', isEqualTo: tutorId)
        .get();

    final List<ServiceModel> services = snapshot.docs.map((doc) {
      return ServiceModel.fromMap({
        ...doc.data(),
        'service_id': doc.data()['service_id'] ?? doc.id,
      });
    }).toList();

    services.sort((a, b) {
      if (a.isActive == b.isActive) {
        final DateTime aDate =
            a.updatedAt ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bDate =
            b.updatedAt ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      }
      return a.isActive ? -1 : 1;
    });
    return services;
  }

  Future<void> _markDuplicateQuoteDocumentsResponded(
    QuoteModel quote,
    QuoteStatus status,
    TeacherQuoteResponseDraft? response, {
    required DocumentReference<Map<String, dynamic>> except,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'status': status.name,
      'response_price': response?.priceLabel ?? '',
      'response_sessions_count': response?.sessionsCount ?? 0,
      'updated_at': Timestamp.now(),
    };

    for (final String collectionName in <String>['quote_requests', 'quotes']) {
      Query<Map<String, dynamic>> query = _firestore
          .collection(collectionName)
          .where('student_id', isEqualTo: quote.studentId)
          .where('tutor_id', isEqualTo: quote.tutorId);

      if (quote.serviceId.isNotEmpty) {
        query = query.where('service_id', isEqualTo: quote.serviceId);
      }

      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      await Future.wait(
        snapshot.docs.map((doc) async {
          if (doc.reference.path == except.path) {
            return;
          }
          final QuoteModel duplicate = QuoteModel.fromMap({
            ...doc.data(),
            'quote_id': doc.data()['quote_id'] ?? doc.id,
          });
          if (duplicate.status != QuoteStatus.pending ||
              _quoteRequestKey(duplicate) != _quoteRequestKey(quote)) {
            return;
          }
          await doc.reference.update(payload);
        }),
      );
    }
  }

  String _quoteRequestKey(QuoteModel quote) {
    return _quoteRequestKeyFor(
      studentId: quote.studentId,
      tutorId: quote.tutorId,
      serviceId: quote.serviceId,
      subject: quote.subject,
      objective: quote.objective,
    );
  }

  String _quoteRequestKeyFor({
    required String studentId,
    required String tutorId,
    required String serviceId,
    String subject = '',
    String objective = '',
  }) {
    final String servicePart = serviceId.isNotEmpty ? serviceId : 'custom';
    if (studentId.isNotEmpty && tutorId.isNotEmpty) {
      return '$studentId|$tutorId|$servicePart';
    }
    return '$servicePart|$subject|$objective';
  }

  Future<Map<String, StudentModel>> _loadStudentsByIds(
    Set<String> studentIds,
  ) async {
    final Map<String, StudentModel> students = <String, StudentModel>{};
    if (studentIds.isEmpty) return students;

    await Future.wait(
      studentIds.map((studentId) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
            .collection('students')
            .doc(studentId)
            .get();
        if (snapshot.exists && snapshot.data() != null) {
          students[studentId] = StudentModel.fromMap({
            ...snapshot.data()!,
            'uid': snapshot.id,
          });
          return;
        }

        final DocumentSnapshot<Map<String, dynamic>> childSnapshot =
            await _firestore.collection('children').doc(studentId).get();
        if (!childSnapshot.exists || childSnapshot.data() == null) {
          return;
        }

        students[studentId] = _studentFromChildSnapshot(childSnapshot);
      }),
    );

    return students;
  }

  Future<Set<String>> _loadChildIdsByIds(Set<String> ids) async {
    if (ids.isEmpty) {
      return <String>{};
    }

    final Set<String> childIds = <String>{};
    await Future.wait(
      ids.map((id) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
            .collection('children')
            .doc(id)
            .get();
        if (snapshot.exists) {
          childIds.add(id);
        }
      }),
    );
    return childIds;
  }

  StudentModel _studentFromChildSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};
    final String name = (data['name'] ?? '').toString().trim();
    final List<String> parts = name.split(RegExp(r'\s+'));

    return StudentModel(
      uid: snapshot.id,
      firstName: parts.isNotEmpty ? parts.first : 'Child',
      lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
      email: '',
      phone: '',
      location: '',
      gender: data['gender'] == 'female' ? Gender.female : Gender.male,
      birthday: DateTime(2000),
      picture: (data['picture'] ?? '').toString(),
      accountStatus: AccountStatus.validated,
      schoolLevel: (data['level'] ?? '').toString(),
      learningObjectives: '',
      preferredSubjects: List<String>.from(data['subjects'] ?? []),
      favoriteTeachers: const <String>[],
      Courses: const <String>[],
      grade: (data['grade'] ?? '').toString(),
      speciality: (data['speciality'] ?? '').toString(),
    );
  }

  Future<_QuoteDocumentLocation> _locateQuoteDocument(String quoteId) async {
    for (final String collection in <String>['quote_requests', 'quotes']) {
      final DocumentReference<Map<String, dynamic>> reference = _firestore
          .collection(collection)
          .doc(quoteId);
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await reference
          .get();
      if (snapshot.exists) {
        return _QuoteDocumentLocation(
          collection: collection,
          reference: reference,
        );
      }
    }
    throw Exception('Quote request not found.');
  }

  String _studentName(StudentModel? student) {
    if (student == null) {
      return 'Student';
    }
    final String fullName = '${student.firstName} ${student.lastName}'.trim();
    return fullName.isEmpty ? 'Student' : fullName;
  }
}

class _QuoteDocumentLocation {
  const _QuoteDocumentLocation({
    required this.collection,
    required this.reference,
  });

  final String collection;
  final DocumentReference<Map<String, dynamic>> reference;
}
