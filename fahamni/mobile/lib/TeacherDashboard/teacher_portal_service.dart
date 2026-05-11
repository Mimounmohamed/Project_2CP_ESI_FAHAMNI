import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  final NotificationService _notificationService = NotificationService();

  Future<TeacherServicesDashboardData> loadDashboard() async {
    final TutorModel tutor = await _loadCurrentTutor();
    final List<ServiceModel> services = await _loadServices(tutor.uid);

    final Set<String> pendingStudentIds = {};
    for (var service in services) {
      pendingStudentIds.addAll(service.pendingIds);
    }

    final Set<String> allStudentIds = {...pendingStudentIds};

    final Map<String, StudentModel> students = await _loadStudentsByIds(
      allStudentIds,
    );
    final Set<String> childIds = await _loadChildIdsByIds(allStudentIds);

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
          joinRequests.add(
            TeacherJoinRequestDetail(
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
                createdAt:
                    (data['date_time'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
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
            ),
          );
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
    final WriteBatch batch = _firestore.batch();

    // 1. Create the Group Chat ID
    final DocumentReference<Map<String, dynamic>> convRef = _firestore
        .collection('conversations')
        .doc();

    final Timestamp now = Timestamp.now();
    final String groupName = '${draft.name} Group';

    // 2. Set Conversation Data
    batch.set(convRef, {
      'conversationId': convRef.id,
      'conversation_id': convRef.id,
      'conversationName': groupName,
      'participants': [tutor.uid],
      'isGroup': true,
      'is_group': true,
      'ownerId': tutor.uid,
      'createdAt': now,
      'updatedAt': now,
      'status': 'active',
      'lastMessage': {
        'text': 'Welcome to the group chat for ${draft.name}!',
        'senderId': 'system',
        'type': 'text',
        'created_at': now,
      },
      'lastMessageTime': now,
    });

    // 3. Add Initial System Message to subcollection
    final DocumentReference<Map<String, dynamic>> msgRef = convRef
        .collection('messages')
        .doc();
    batch.set(msgRef, {
      'id': msgRef.id,
      'conversationId': convRef.id,
      'senderId': 'system',
      'text': 'Welcome to the group chat for ${draft.name}!',
      'type': 'text',
      'created_at': now,
      'readBy': [tutor.uid],
    });

    // 4. Create the Service Document
    final DocumentReference<Map<String, dynamic>> svcRef = _firestore
        .collection('services')
        .doc();

    final ServiceModel model = ServiceModel(
      serviceId: svcRef.id,
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
      groupChatId: convRef.id,
      createdAt: now.toDate(),
      updatedAt: now.toDate(),
    );

    batch.set(svcRef, {...model.toMap(), 'created_at': now, 'updated_at': now});

    // 5. Commit all at once to prevent duplication on partial failure/retry
    await batch.commit();

    return model;
  }

  Future<void> updateService({
    required String serviceId,
    required TeacherServiceDraft draft,
  }) async {
    final TutorModel tutor = await _loadCurrentTutor();

    await _firestore.collection('services').doc(serviceId).update({
      'tutor_id': tutor.uid,
      'name': draft.name,
      'area': draft.domain,
      'level': draft.grade,
      'subject': draft.domain.toUpperCase(),
      'mode': draft.mode,
      'description': draft.description,
      'price': draft.price,
      'duration': draft.sessionDurationMinutes,
      'maxstudents': draft.membersCount,
      'sessions_num': draft.sessionsCount,
      'picture': draft.imagePath,
      'updated_at': Timestamp.now(),
    });

    try {
      final svcDoc = await _firestore
          .collection('services')
          .doc(serviceId)
          .get();
      final gId = svcDoc.data()?['group_chat_id'];
      if (gId != null && gId.toString().isNotEmpty) {
        await _firestore.collection('conversations').doc(gId).update({
          'conversationName': '${draft.name} Group',
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      debugPrint('Failed to update group chat name: $e');
    }
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

  Future<String> _resolveNotificationReceiver(
    String studentId,
    bool isChild,
  ) async {
    if (!isChild) return studentId;
    try {
      final snap = await _firestore.collection('children').doc(studentId).get();
      final parentUid =
          (snap.data()?['parentUid'] ?? snap.data()?['parent_uid'] ?? '')
              .toString()
              .trim();
      if (parentUid.isNotEmpty) return parentUid;
    } catch (_) {}
    return studentId;
  }

  Future<void> respondToQuote({
    required TeacherJoinRequestDetail request,
    required QuoteStatus status,
    TeacherQuoteResponseDraft? response,
  }) async {
    final TutorModel currentTutor = await _loadCurrentTutor();
    final String notificationReceiver = await _resolveNotificationReceiver(
      request.quote.studentId,
      request.isChild,
    );

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
          final String? groupChatId = snapshot.data()?['group_chat_id'];

          pendingIds.remove(studentId);
          if (!studentIds.contains(studentId)) {
            studentIds.add(studentId);
            enrolled++;

            if (groupChatId != null && groupChatId.isNotEmpty) {
              transaction.update(
                _firestore.collection('conversations').doc(groupChatId),
                {
                  'participants': FieldValue.arrayUnion([studentId]),
                  'updatedAt': Timestamp.now(),
                },
              );

              final DocumentReference<Map<String, dynamic>> welcomeMsgRef =
                  _firestore
                      .collection('conversations')
                      .doc(groupChatId)
                      .collection('messages')
                      .doc();
              transaction.set(welcomeMsgRef, {
                'id': welcomeMsgRef.id,
                'conversationId': groupChatId,
                'senderId': 'system',
                'text': '${request.studentName} has joined the group.',
                'type': 'text',
                'created_at': Timestamp.now(),
                'readBy': [currentTutor.uid],
              });
            }
          }

          transaction.update(serviceRef, {
            'student_ids': studentIds,
            'pending_ids': pendingIds,
            'enrolled_num': enrolled,
            'updated_at': Timestamp.now(),
          });
        });
      } else {
        await serviceRef.update({
          'pending_ids': FieldValue.arrayRemove([studentId]),
          'updated_at': Timestamp.now(),
        });
      }

      try {
        await _notificationService.sendNotification(
          NotificationModel(
            title: status == QuoteStatus.accepted
                ? 'Request Accepted'
                : 'Request Declined',
            content: status == QuoteStatus.accepted
                ? 'Your service request for ${request.serviceTitle} has been accepted by the teacher.'
                : 'Your service request for ${request.serviceTitle} was declined by the teacher.',
            dateTime: DateTime.now(),
            isRead: false,
            notificationId: '',
            receiverId: notificationReceiver,
            type: 'join_request_response',
            senderId: currentTutor.uid,
            tutorId: currentTutor.uid,
            serviceId: serviceId,
          ),
        );
      } catch (e) {
        debugPrint('Failed to send join request notification: $e');
      }
      return;
    }

    final _QuoteDocumentLocation location = await _locateQuoteDocument(
      request.quote.quoteId,
    );

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
          final String? groupChatId = serviceSnap.data()?['group_chat_id'];

          pendingIds.remove(studentId);

          if (status == QuoteStatus.accepted &&
              !studentIds.contains(studentId)) {
            studentIds.add(studentId);
            enrolled++;

            if (groupChatId != null && groupChatId.isNotEmpty) {
              transaction.update(
                _firestore.collection('conversations').doc(groupChatId),
                {
                  'participants': FieldValue.arrayUnion([studentId]),
                  'updatedAt': Timestamp.now(),
                },
              );

              final DocumentReference<Map<String, dynamic>> welcomeMsgRef =
                  _firestore
                      .collection('conversations')
                      .doc(groupChatId)
                      .collection('messages')
                      .doc();
              transaction.set(welcomeMsgRef, {
                'id': welcomeMsgRef.id,
                'conversationId': groupChatId,
                'senderId': 'system',
                'text': '${request.studentName} has joined the group.',
                'type': 'text',
                'created_at': Timestamp.now(),
                'readBy': [currentTutor.uid],
              });
            }
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
    } else {
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

    try {
      await _notificationService.sendNotification(
        NotificationModel(
          title: status == QuoteStatus.accepted
              ? 'Request Accepted'
              : 'Request Declined',
          content: status == QuoteStatus.accepted
              ? 'Your service request for ${request.subject} has been accepted.'
              : 'Your service request for ${request.subject} was declined.',
          dateTime: DateTime.now(),
          isRead: false,
          notificationId: '',
          receiverId: notificationReceiver,
          type: 'quote_response',
          senderId: currentTutor.uid,
          tutorId: currentTutor.uid,
          serviceId: request.quote.serviceId,
        ),
      );
    } catch (e) {
      debugPrint('Failed to send quote response notification: $e');
    }
    try {
      await _sendQuoteResponseChatMessage(
        tutorId: currentTutor.uid,
        studentId: notificationReceiver,
        status: status,
      );
    } catch (e) {
      debugPrint('Failed to send quote response chat message: $e');
    }
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
    await _notificationService.sendSessionScheduledNotifications(
      sessionId: doc.id,
      tutorId: tutor.uid,
      serviceId: session.serviceId,
      studentIds: session.studentIds,
      startTime: session.startTime,
    );
  }

  Future<void> rescheduleSession({
    required String sessionId,
    required TeacherSessionDraft draft,
  }) async {
    final sessionDoc = await _firestore
        .collection('sessions')
        .doc(sessionId)
        .get();
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

    if (sessionDoc.exists && sessionDoc.data() != null) {
      final session = SessionModel.fromMap({
        ...sessionDoc.data()!,
        'session_id': sessionDoc.id,
        'start_time': Timestamp.fromDate(startTime),
        'end_time': Timestamp.fromDate(endTime),
        'date': Timestamp.fromDate(
          DateTime(draft.date.year, draft.date.month, draft.date.day),
        ),
      });
      await _notificationService.sendSessionRescheduledNotifications(
        sessionId: session.sessionId,
        tutorId: session.tutorId,
        serviceId: session.serviceId,
        studentIds: session.studentIds,
        startTime: session.startTime,
      );
    }
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
    await _notificationService.sendStudyResourceNotifications(
      resourceId: doc.id,
      tutorId: tutor.uid,
      title: draft.name,
      serviceId: request.quote.serviceId,
      sessionId: request.quote.quoteId,
      studentIds: [request.quote.studentId],
    );
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

  Future<void> sendEstimatePdfToChat({
    required String tutorId,
    required String studentId,
    required Uint8List pdfBytes,
    required String invoiceNumber,
  }) async {
    if (tutorId.isEmpty || studentId.isEmpty) return;
    final String receiverId = await _resolveNotificationReceiver(
      studentId,
      true,
    );

    final String conversationId = await _getOrCreateConversationId(
      tutorId: tutorId,
      studentId: receiverId,
    );

    final String storagePath =
        'chats/$conversationId/attachments/$invoiceNumber.pdf';
    final Reference ref = FirebaseStorage.instance.ref(storagePath);
    final UploadTask task = ref.putData(
      pdfBytes,
      SettableMetadata(contentType: 'application/pdf'),
    );
    final TaskSnapshot snap = await task;
    final String downloadUrl = await snap.ref.getDownloadURL();

    final DocumentReference<Map<String, dynamic>> msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    final Timestamp now = Timestamp.now();
    final Map<String, dynamic> attachment = {
      'url': downloadUrl,
      'name': '$invoiceNumber.pdf',
      'mimeType': 'application/pdf',
      'size': pdfBytes.length,
      'isImage': false,
    };
    final Map<String, dynamic> messageData = {
      'id': msgRef.id,
      'conversationId': conversationId,
      'senderId': tutorId,
      'receiverId': receiverId,
      'text': 'Estimate $invoiceNumber',
      'type': 'file',
      'attachments': [attachment],
      'voiceUrl': null,
      'voiceDuration': null,
      'created_at': now,
      'readBy': [tutorId],
    };

    final WriteBatch batch = _firestore.batch();
    batch.set(msgRef, messageData);
    batch.set(
      _firestore.collection('conversations').doc(conversationId),
      {'lastMessage': messageData, 'lastMessageTime': now, 'updatedAt': now},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<String> _getOrCreateConversationId({
    required String tutorId,
    required String studentId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: tutorId)
        .get();

    for (final doc in snapshot.docs) {
      final List<dynamic> participants =
          (doc.data()['participants'] as List<dynamic>?) ?? [];
      final bool isGroup =
          doc.data()['isGroup'] == true ||
          doc.data()['is_group'] == true ||
          participants.length > 2;
      if (!isGroup && participants.contains(studentId)) {
        return doc.id;
      }
    }

    final DocumentReference<Map<String, dynamic>> convRef = _firestore
        .collection('conversations')
        .doc();
    await convRef.set({
      'conversationId': convRef.id,
      'participants': [tutorId, studentId],
      'isGroup': false,
      'createdAt': Timestamp.now(),
      'status': 'active',
      'updatedAt': Timestamp.now(),
    });
    return convRef.id;
  }

  Future<void> _sendQuoteResponseChatMessage({
    required String tutorId,
    required String studentId,
    required QuoteStatus status,
  }) async {
    if (tutorId.isEmpty || studentId.isEmpty) return;

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('conversations')
        .where('participants', arrayContains: tutorId)
        .get();

    String? conversationId;
    for (final doc in snapshot.docs) {
      final List<dynamic> participants =
          (doc.data()['participants'] as List<dynamic>?) ?? [];
      final bool isGroup =
          doc.data()['isGroup'] == true ||
          doc.data()['is_group'] == true ||
          participants.length > 2;
      if (!isGroup && participants.contains(studentId)) {
        conversationId = doc.id;
        break;
      }
    }

    if (conversationId == null) {
      final DocumentReference<Map<String, dynamic>> convRef = _firestore
          .collection('conversations')
          .doc();
      await convRef.set({
        'conversationId': convRef.id,
        'participants': [tutorId, studentId],
        'isGroup': false,
        'createdAt': Timestamp.now(),
        'status': 'active',
        'updatedAt': Timestamp.now(),
      });
      conversationId = convRef.id;
    }

    final String text = status == QuoteStatus.accepted
        ? 'Your quote has been accepted! An estimate has been sent to your email.'
        : 'Your quote request has been declined.';

    final DocumentReference<Map<String, dynamic>> msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    final Timestamp now = Timestamp.now();
    final Map<String, dynamic> messageData = {
      'id': msgRef.id,
      'conversationId': conversationId,
      'senderId': tutorId,
      'receiverId': studentId,
      'text': text,
      'type': 'text',
      'attachments': [],
      'voiceUrl': null,
      'voiceDuration': null,
      'created_at': now,
      'readBy': [tutorId],
    };

    final WriteBatch batch = _firestore.batch();
    batch.set(msgRef, messageData);
    batch.set(
      _firestore.collection('conversations').doc(conversationId),
      {'lastMessage': messageData, 'lastMessageTime': now, 'updatedAt': now},
      SetOptions(merge: true),
    );
    await batch.commit();
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
