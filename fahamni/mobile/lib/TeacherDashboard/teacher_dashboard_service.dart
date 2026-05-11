import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/quote_model.dart';
import '../models/resource_model.dart';
import '../models/service_model.dart';
import '../models/session_model.dart';
import '../models/student_model.dart';
import '../models/teacher_dashboard_model.dart';
import '../models/teacher_schedule_model.dart';
import '../models/tutor_model.dart';
import '../models/user_model.dart';
import '../Services/notification_service.dart';

class CreateServicePayload {
  const CreateServicePayload({
    required this.name,
    required this.description,
    required this.domain,
    required this.grade,
    required this.subject,
    required this.price,
    required this.membersNumber,
    required this.mode,
    required this.sessionsNumber,
    required this.session_duration,
    required this.picture,
  });

  final String name;
  final String description;
  final String domain;
  final String grade;
  final String subject;
  final double price;
  final int membersNumber;
  final String mode;
  final int sessionsNumber;
  final int session_duration;
  final String picture;
}

class TeacherDashboardService {
  TeacherDashboardService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final NotificationService _notificationService = NotificationService();

  Future<TeacherDashboardModel> loadDashboard() async {
    final TutorModel tutor = await _loadCurrentTutor();

    final Future<List<ServiceModel>> servicesFuture = _loadServices(tutor.uid);
    final Future<List<SessionModel>> sessionsFuture = _loadSessions(tutor.uid);
    final Future<List<QuoteModel>> quotesFuture = _loadQuotes(
      tutor.uid,
      onlyPending: true,
    );

    final List<dynamic> payload = await Future.wait<dynamic>([
      servicesFuture,
      sessionsFuture,
      quotesFuture,
    ]);

    final List<ServiceModel> services = payload[0] as List<ServiceModel>;
    final List<SessionModel> sessions = payload[1] as List<SessionModel>;
    final List<QuoteModel> quotes = payload[2] as List<QuoteModel>;
    final Map<String, StudentModel> students = await _loadStudentsForQuotes(
      quotes,
    );

    return TeacherDashboardModel(
      tutorProfile: tutor,
      serviceRecords: services,
      teacherName: '${tutor.firstName} ${tutor.lastName}'.trim(),
      teacherRoleLabel: 'Teacher',
      profileImage: tutor.picture,
      performanceTitle: 'Performance Overview',
      todaySessionsTitle: "Today's Sessions",
      myServicesTitle: 'Services',
      quoteRequestsTitle: 'Quote Requests',
      seeAllLabel: 'See All',
      emptySessionsLabel: 'No sessions planned for today.',
      emptyServicesLabel: 'No active services yet.',
      emptyQuotesLabel: 'No quote requests yet.',
      stats: _buildStats(tutor, services, sessions),
      nextSession: _buildNextSession(sessions, services),
      services: services.map(_toDashboardService).toList(),
      quoteRequests: quotes
          .map((quote) => _toQuoteRequestCard(quote, students[quote.studentId]))
          .toList(),
    );
  }

  Future<TeacherScheduleModel> loadSchedule({int days = 7}) async {
    final TutorModel tutor = await _loadCurrentTutor();
    final List<ServiceModel> services = await _loadServices(tutor.uid);
    final List<SessionModel> sessions = await _loadSessions(tutor.uid);
    final Map<String, StudentModel> students = await _loadStudentsForSessions(
      sessions,
    );
    final Map<String, ServiceModel> servicesById = {
      for (final ServiceModel service in services) service.serviceId: service,
    };

    final DateTime now = DateTime.now();
    final DateTime startDay = DateTime(now.year, now.month, now.day);
    final List<TeacherScheduleDay> scheduleDays =
        List<TeacherScheduleDay>.generate(days, (index) {
          final DateTime day = startDay.add(Duration(days: index));
          final List<TeacherScheduleSession> daySessions =
              sessions
                  .where((session) => _isSameDay(session.date, day))
                  .map(
                    (session) => _toScheduleSession(
                      session,
                      servicesById[session.serviceId],
                      students,
                    ),
                  )
                  .toList()
                ..sort((a, b) => a.startTimeLabel.compareTo(b.startTimeLabel));

          return TeacherScheduleDay(
            date: day,
            label: DateFormat('EEEE, dd MMM').format(day),
            shortLabel: DateFormat('EEE').format(day),
            sessions: daySessions,
          );
        });

    return TeacherScheduleModel(
      title: 'My Schedule',
      teacherName: '${tutor.firstName} ${tutor.lastName}'.trim(),
      days: scheduleDays,
    );
  }

  Future<String> createService(CreateServicePayload payload) async {
    final TutorModel tutor = await _loadCurrentTutor();
    final DocumentReference<Map<String, dynamic>> ref = _firestore
        .collection('services')
        .doc();

    final ServiceModel service = ServiceModel(
      serviceId: ref.id,
      tutorId: tutor.uid,
      name: payload.name,
      area: payload.domain,
      level: payload.grade,
      subject: payload.subject,
      mode: payload.mode,
      description: payload.description,
      price: payload.price,
      duration: payload.session_duration,
      isActive: true,
      maxStudents: payload.membersNumber,
      enrollednum: 0,
      sessionsnum: payload.sessionsNumber,
      picture: payload.picture,
    );

    await ref.set(service.toMap());
    return ref.id;
  }

  Future<void> setServiceStatus({
    required String serviceId,
    required bool isActive,
  }) async {
    await _firestore.collection('services').doc(serviceId).set({
      'is_active': isActive,
    }, SetOptions(merge: true));
  }

  Future<void> respondToQuote({
    required String quoteId,
    required bool accepted,
    double? price,
    int? sessionsNumber,
    int? sessionDurationMinutes,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'status': accepted
          ? QuoteStatus.accepted.name
          : QuoteStatus.rejected.name,
      'responded_at': Timestamp.fromDate(DateTime.now()),
      'updated_at': Timestamp.now(),
    };
    if (price != null) payload['teacher_price'] = price;
    if (sessionsNumber != null)
      payload['teacher_sessions_num'] = sessionsNumber;
    if (sessionDurationMinutes != null)
      payload['teacher_session_duration'] = sessionDurationMinutes;

    bool updated = false;
    Map<String, dynamic>? quoteData;
    for (final String collectionName in <String>['quote_requests', 'quotes']) {
      final DocumentReference<Map<String, dynamic>> quoteRef = _firestore
          .collection(collectionName)
          .doc(quoteId);
      final DocumentSnapshot<Map<String, dynamic>> quoteSnapshot =
          await quoteRef.get();
      if (quoteSnapshot.exists) {
        quoteData = quoteSnapshot.data();
        await quoteRef.set(payload, SetOptions(merge: true));
        updated = true;
      }
    }

    if (!updated) {
      throw Exception('Quote request not found.');
    }

    if (quoteData != null) {
      await _notificationService.sendStudentRequestResponseNotification(
        studentId: (quoteData!['student_id'] ?? '').toString(),
        tutorId: (quoteData!['tutor_id'] ?? '').toString(),
        accepted: accepted,
        serviceId: (quoteData!['service_id'] ?? '').toString(),
        subject: (quoteData!['subject'] ?? '').toString(),
      );
    }
  }

  Future<String> createSession({
    required String serviceId,
    required DateTime date,
    required TimeOfDay startTime,
    required int durationMinutes,
    required String sessionType,
    required String modality,
    String onlineLink = '',
    List<String> studentIds = const <String>[],
  }) async {
    final TutorModel tutor = await _loadCurrentTutor();
    final DateTime start = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    final DateTime end = start.add(Duration(minutes: durationMinutes));

    final DocumentReference<Map<String, dynamic>> ref = _firestore
        .collection('sessions')
        .doc();
    await ref.set({
      'session_id': ref.id,
      'service_id': serviceId,
      'student_ids': studentIds,
      'tutor_id': tutor.uid,
      'status': SessionStatus.Planned.name,
      'type': sessionType.toLowerCase(),
      'modality': modality.toLowerCase(),
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'start_time': Timestamp.fromDate(start),
      'end_time': Timestamp.fromDate(end),
      if (onlineLink.isNotEmpty) 'online_link': onlineLink,
    });

    await _notificationService.sendSessionScheduledNotifications(
      sessionId: ref.id,
      tutorId: tutor.uid,
      serviceId: serviceId,
      studentIds: studentIds,
      startTime: start,
    );

    return ref.id;
  }

  Future<void> rescheduleSession({
    required String sessionId,
    required DateTime date,
    required TimeOfDay startTime,
    required int durationMinutes,
    required String modality,
    String onlineLink = '',
  }) async {
    final sessionDoc = await _firestore
        .collection('sessions')
        .doc(sessionId)
        .get();
    final DateTime start = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    final DateTime end = start.add(Duration(minutes: durationMinutes));

    await _firestore.collection('sessions').doc(sessionId).set({
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'start_time': Timestamp.fromDate(start),
      'end_time': Timestamp.fromDate(end),
      'modality': modality.toLowerCase(),
      if (onlineLink.isNotEmpty) 'online_link': onlineLink,
    }, SetOptions(merge: true));

    if (sessionDoc.exists && sessionDoc.data() != null) {
      final session = SessionModel.fromMap({
        ...sessionDoc.data()!,
        'session_id': sessionDoc.id,
        'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        'start_time': Timestamp.fromDate(start),
        'end_time': Timestamp.fromDate(end),
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

  Future<String> addResource({
    required String sessionId,
    required String name,
    required String type,
    required String value,
    String subject = '',
    String level = '',
    String serviceId = '',
  }) async {
    final TutorModel tutor = await _loadCurrentTutor();
    final DocumentReference<Map<String, dynamic>> ref = _firestore
        .collection('resources')
        .doc();
    final bool isLink = type.toLowerCase() == 'link';

    final ResourceModel resource = isLink
        ? LinkResource(
            resourceId: ref.id,
            tutorId: tutor.uid,
            sessionId: sessionId,
            title: name,
            subject: subject,
            level: level,
            description: '',
            accessLevel: 'session',
            allowedUsers: const <String>[],
            isPublic: false,
            addedAt: DateTime.now(),
            linkUrl: value,
          )
        : DocumentResource(
            resourceId: ref.id,
            tutorId: tutor.uid,
            sessionId: sessionId,
            title: name,
            subject: subject,
            level: level,
            description: '',
            accessLevel: 'session',
            allowedUsers: const <String>[],
            isPublic: false,
            addedAt: DateTime.now(),
            fileUrl: value,
            docType: 'file',
          );

    final Map<String, dynamic> data = {
      ...resource.toMap(),
      if (serviceId.isNotEmpty) 'service_id': serviceId,
    };

    await ref.set(data);
    await _notificationService.sendStudyResourceNotifications(
      resourceId: ref.id,
      tutorId: tutor.uid,
      title: name,
      serviceId: serviceId,
      sessionId: sessionId,
    );
    return ref.id;
  }

  Future<TutorModel> _loadCurrentTutor() async {
    final User? currentUser = await _auth.authStateChanges().first;
    if (currentUser == null) {
      throw Exception(
        'You need to be signed in to open the teacher dashboard.',
      );
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
      final Map<String, dynamic> data = {
        ...doc.data(),
        'service_id': doc.data()['service_id'] ?? doc.id,
      };
      return ServiceModel.fromMap(data);
    }).toList();

    services.sort(
      (a, b) => b.isActive.toString().compareTo(a.isActive.toString()),
    );
    return services;
  }

  Future<List<SessionModel>> _loadSessions(String tutorId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('sessions')
        .where('tutor_id', isEqualTo: tutorId)
        .get();

    final List<SessionModel> sessions = snapshot.docs.map((doc) {
      final Map<String, dynamic> data = {
        ...doc.data(),
        'session_id': doc.data()['session_id'] ?? doc.id,
      };
      return SessionModel.fromMap(data);
    }).toList();

    sessions.sort((a, b) {
      final DateTime aDateTime = DateTime(
        a.date.year,
        a.date.month,
        a.date.day,
        a.startTime.hour,
        a.startTime.minute,
      );
      final DateTime bDateTime = DateTime(
        b.date.year,
        b.date.month,
        b.date.day,
        b.startTime.hour,
        b.startTime.minute,
      );
      return aDateTime.compareTo(bDateTime);
    });
    return sessions;
  }

  Future<List<QuoteModel>> _loadQuotes(
    String tutorId, {
    bool onlyPending = false,
  }) async {
    Future<List<QuoteModel>> fetchFrom(String collectionName) async {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(collectionName)
          .where('tutor_id', isEqualTo: tutorId)
          .get();

      return snapshot.docs.map((doc) {
        final Map<String, dynamic> data = {
          ...doc.data(),
          'quote_id': doc.data()['quote_id'] ?? doc.id,
        };
        return QuoteModel.fromMap(data);
      }).toList();
    }

    final List<QuoteModel> requests = await fetchFrom('quote_requests');
    final Map<String, QuoteModel> byRequestKey = <String, QuoteModel>{};

    for (final QuoteModel quote in requests) {
      if (onlyPending && quote.status != QuoteStatus.pending) {
        continue;
      }
      final String requestKey = _quoteRequestKey(quote);
      final QuoteModel? existing = byRequestKey[requestKey];
      if (existing == null || _isNewerQuote(quote, existing)) {
        byRequestKey[requestKey] = quote;
      }
    }

    final List<QuoteModel> combined = byRequestKey.values.toList();
    combined.sort((a, b) {
      final DateTime aDate =
          a.createdAt ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bDate =
          b.createdAt ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return combined;
  }

  String _quoteRequestKey(QuoteModel quote) {
    if (quote.studentId.isNotEmpty && quote.tutorId.isNotEmpty) {
      final String servicePart = quote.serviceId.isNotEmpty
          ? quote.serviceId
          : 'custom';
      return '${quote.studentId}|${quote.tutorId}|$servicePart';
    }
    return quote.quoteId;
  }

  bool _isNewerQuote(QuoteModel candidate, QuoteModel existing) {
    final DateTime candidateDate =
        candidate.createdAt ??
        candidate.updatedAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final DateTime existingDate =
        existing.createdAt ??
        existing.updatedAt ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return candidateDate.isAfter(existingDate);
  }

  Future<Map<String, StudentModel>> _loadStudentsForQuotes(
    List<QuoteModel> quotes,
  ) async {
    final Set<String> studentIds = quotes
        .map((quote) => quote.studentId)
        .where((id) => id.isNotEmpty)
        .toSet();
    final Map<String, StudentModel> students = <String, StudentModel>{};

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

  Future<Map<String, StudentModel>> _loadStudentsForSessions(
    List<SessionModel> sessions,
  ) async {
    final Set<String> studentIds = sessions
        .expand((session) => session.studentIds)
        .where((studentId) => studentId.isNotEmpty)
        .toSet();
    final Map<String, StudentModel> students = <String, StudentModel>{};

    await Future.wait(
      studentIds.map((studentId) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
            .collection('students')
            .doc(studentId)
            .get();
        if (!snapshot.exists || snapshot.data() == null) {
          return;
        }

        students[studentId] = StudentModel.fromMap({
          ...snapshot.data()!,
          'uid': snapshot.id,
        });
      }),
    );

    return students;
  }

  List<TeacherDashboardStat> _buildStats(
    TutorModel tutor,
    List<ServiceModel> services,
    List<SessionModel> sessions,
  ) {
    final Set<String> uniqueStudents = sessions
        .expand((session) => session.studentIds)
        .where((studentId) => studentId.isNotEmpty)
        .toSet();

    return <TeacherDashboardStat>[
      TeacherDashboardStat(
        label: 'RATING',
        value: tutor.averageRating > 0
            ? '${tutor.averageRating.toStringAsFixed(1)} '
            : 'New',
      ),
      TeacherDashboardStat(
        label: 'STUDENTS',
        value: uniqueStudents.length.toString(),
      ),
      TeacherDashboardStat(label: 'COURSES', value: services.length.toString()),
    ];
  }

  TeacherDashboardSession? _buildNextSession(
    List<SessionModel> sessions,
    List<ServiceModel> services,
  ) {
    final DateTime now = DateTime.now();
    final Map<String, ServiceModel> servicesById = {
      for (final ServiceModel service in services) service.serviceId: service,
    };

    for (final SessionModel session in sessions) {
      final DateTime startsAt = DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
        session.startTime.hour,
        session.startTime.minute,
      );
      if (startsAt.isBefore(now)) {
        continue;
      }

      final ServiceModel? service = servicesById[session.serviceId];
      final String title = service?.name.trim().isNotEmpty == true
          ? service!.name
          : '${_capitalize(session.type)} Session';

      return TeacherDashboardSession(
        badgeLabel: 'NEXT COURSE',
        title: title,
        subject: service?.subject.isNotEmpty == true
            ? service!.subject
            : _capitalize(session.type),
        timeRange: _formatSessionTime(session),
        modalityLabel: _capitalize(session.modality),
      );
    }
    return null;
  }

  TeacherDashboardServiceCard _toDashboardService(ServiceModel service) {
    return TeacherDashboardServiceCard(
      id: service.serviceId,
      category: service.subject.toUpperCase(),
      statusLabel: service.isActive ? 'ACTIVE' : 'INACTIVE',
      title: service.name,
      sessionsLabel:
          '${service.sessionsnum} ${service.sessionsnum == 1 ? 'Session' : 'Sessions'}',
      priceLabel: '${service.price.toStringAsFixed(0)} DA',
      imagePath: service.picture,
    );
  }

  TeacherDashboardQuoteRequest _toQuoteRequestCard(
    QuoteModel quote,
    StudentModel? student,
  ) {
    final String studentName = student == null
        ? 'Student Request'
        : '${student.firstName} ${student.lastName}'.trim();
    final String level = student?.schoolLevel.isNotEmpty == true
        ? student!.schoolLevel
        : quote.level;

    return TeacherDashboardQuoteRequest(
      quote: quote,
      id: quote.quoteId,
      studentId: quote.studentId,
      studentName: studentName,
      studentLevel: level,
      subtitle: quote.subject,
      subject: quote.subject,
      objective: quote.description.isNotEmpty
          ? quote.description
          : quote.objective,
      frequency: quote.frequency,
      duration: quote.duration,
      budget: quote.budget,
      createdAtLabel: _formatQuoteDate(quote),
      status: quote.status.name,
      avatarPath: student?.picture ?? '',
      actionLabel: 'See details',
    );
  }

  String _formatQuoteDate(QuoteModel quote) {
    final DateTime? createdAt = quote.createdAt ?? quote.updatedAt;
    if (createdAt == null) {
      return 'Now';
    }
    return DateFormat('dd MMM | HH:mm').format(createdAt);
  }

  String _formatSessionTime(SessionModel session) {
    final DateFormat dateFormat = DateFormat('dd MMM');
    final DateFormat timeFormat = DateFormat('HH:mm');
    final int duration = session.endTime
        .difference(session.startTime)
        .inMinutes;

    return '${dateFormat.format(session.date)} | '
        '${timeFormat.format(session.startTime)} - ${timeFormat.format(session.endTime)} '
        '($duration min)';
  }

  TeacherScheduleSession _toScheduleSession(
    SessionModel session,
    ServiceModel? service,
    Map<String, StudentModel> studentsById,
  ) {
    final DateFormat timeFormat = DateFormat('HH:mm');
    final int duration = session.endTime
        .difference(session.startTime)
        .inMinutes;
    final List<String> studentNames = session.studentIds
        .map((studentId) => studentsById[studentId])
        .whereType<StudentModel>()
        .map((student) => '${student.firstName} ${student.lastName}'.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    return TeacherScheduleSession(
      id: session.sessionId,
      date: session.date,
      startTime: session.startTime,
      endTime: session.endTime,
      title: service?.name.trim().isNotEmpty == true
          ? service!.name
          : '${_capitalize(session.type)} Session',
      subject: service?.subject.isNotEmpty == true
          ? service!.subject
          : _capitalize(session.type),
      startTimeLabel: timeFormat.format(session.startTime),
      endTimeLabel: timeFormat.format(session.endTime),
      durationLabel: '$duration min',
      modalityLabel: _capitalize(session.modality),
      statusLabel: session.status.name,
      studentSummary: _studentSummary(studentNames, session.studentIds.length),
    );
  }

  String _studentSummary(List<String> names, int fallbackCount) {
    if (names.isEmpty) {
      return fallbackCount <= 1 ? '1 student' : '$fallbackCount students';
    }
    if (names.length == 1) {
      return names.first;
    }
    if (names.length == 2) {
      return '${names[0]} & ${names[1]}';
    }
    return '${names[0]}, ${names[1]} +${names.length - 2}';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  Future<List<QuoteModel>> loadAllQuotes() async {
    final TutorModel tutor = await _loadCurrentTutor();
    return _loadQuotes(tutor.uid, onlyPending: false);
  }

  /// Loads all quotes (all statuses, both collections) with student details.
  Future<List<TeacherDashboardQuoteRequest>> loadAllQuoteDetails() async {
    final TutorModel tutor = await _loadCurrentTutor();

    Future<List<QuoteModel>> fetchFrom(String col) async {
      final snap = await _firestore
          .collection(col)
          .where('tutor_id', isEqualTo: tutor.uid)
          .get();
      return snap.docs.map((doc) {
        return QuoteModel.fromMap({
          ...doc.data(),
          'quote_id': doc.data()['quote_id'] ?? doc.id,
        });
      }).toList();
    }

    final List<QuoteModel> fromRequests = await fetchFrom('quote_requests');
    final List<QuoteModel> fromQuotes = await fetchFrom('quotes');

    // Deduplicate: prefer quote_requests entry; key by studentId+tutorId+serviceId
    final Map<String, QuoteModel> byKey = {};
    for (final q in [...fromRequests, ...fromQuotes]) {
      final key = _quoteRequestKey(q);
      final existing = byKey[key];
      if (existing == null || _isNewerQuote(q, existing)) {
        byKey[key] = q;
      }
    }

    final List<QuoteModel> all = byKey.values.toList()
      ..sort((a, b) {
        final aDate =
            a.createdAt ??
            a.updatedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            b.createdAt ??
            b.updatedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

    final Map<String, StudentModel> students = await _loadStudentsForQuotes(
      all,
    );
    return all
        .map((q) => _toQuoteRequestCard(q, students[q.studentId]))
        .toList();
  }
}
