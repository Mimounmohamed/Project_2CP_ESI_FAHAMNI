import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/quote_model.dart';
import '../models/service_model.dart';
import '../models/session_model.dart';
import '../models/student_model.dart';
import '../models/teacher_dashboard_model.dart';
import '../models/teacher_schedule_model.dart';
import '../models/tutor_model.dart';

class TeacherDashboardService {
  TeacherDashboardService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<TeacherDashboardModel> loadDashboard() async {
    final TutorModel tutor = await _loadCurrentTutor();

    final Future<List<ServiceModel>> servicesFuture = _loadServices(tutor.uid);
    final Future<List<SessionModel>> sessionsFuture = _loadSessions(tutor.uid);
    final Future<List<QuoteModel>> quotesFuture = _loadQuotes(tutor.uid);

    final List<dynamic> payload = await Future.wait<dynamic>([
      servicesFuture,
      sessionsFuture,
      quotesFuture,
    ]);

    final List<ServiceModel> services = payload[0] as List<ServiceModel>;
    final List<SessionModel> sessions = payload[1] as List<SessionModel>;
    final List<QuoteModel> quotes = payload[2] as List<QuoteModel>;
    final Map<String, StudentModel> students = await _loadStudentsForQuotes(quotes);

    return TeacherDashboardModel(
      teacherName: '${tutor.firstName} ${tutor.lastName}'.trim(),
      teacherRoleLabel: 'Teacher',
      profileImage: tutor.picture,
      performanceTitle: 'Performance Overview',
      todaySessionsTitle: "Today's Sessions",
      myServicesTitle: 'My Services',
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
    final Map<String, StudentModel> students = await _loadStudentsForSessions(sessions);
    final Map<String, ServiceModel> servicesById = {
      for (final ServiceModel service in services) service.serviceId: service,
    };

    final DateTime now = DateTime.now();
    final DateTime startDay = DateTime(now.year, now.month, now.day);
    final List<TeacherScheduleDay> scheduleDays = List<TeacherScheduleDay>.generate(
      days,
      (index) {
        final DateTime day = startDay.add(Duration(days: index));
        final List<TeacherScheduleSession> daySessions = sessions
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
      },
    );

    return TeacherScheduleModel(
      title: 'My Schedule',
      teacherName: '${tutor.firstName} ${tutor.lastName}'.trim(),
      days: scheduleDays,
    );
  }

  Future<TutorModel> _loadCurrentTutor() async {
    final User? currentUser = await _auth.authStateChanges().first;
    if (currentUser == null) {
      throw Exception('You need to be signed in to open the teacher dashboard.');
    }

    final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await _firestore.collection('users').doc(currentUser.uid).get();

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

    return TutorModel.fromMap({
      ...mergedData,
      'uid': userSnapshot.id,
    });
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

    services.sort((a, b) => b.isActive.toString().compareTo(a.isActive.toString()));
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

  Future<List<QuoteModel>> _loadQuotes(String tutorId) async {
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

    final List<QuoteModel> quotes = await fetchFrom('quotes');
    if (quotes.isNotEmpty) {
      return quotes;
    }
    return fetchFrom('quote_requests');
  }

  Future<Map<String, StudentModel>> _loadStudentsForQuotes(
    List<QuoteModel> quotes,
  ) async {
    final Set<String> studentIds =
        quotes.map((quote) => quote.studentId).where((id) => id.isNotEmpty).toSet();
    final Map<String, StudentModel> students = <String, StudentModel>{};

    await Future.wait(
      studentIds.map((studentId) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await _firestore.collection('students').doc(studentId).get();
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
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await _firestore.collection('students').doc(studentId).get();
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
            ? '${tutor.averageRating.toStringAsFixed(1)} ★'
            : 'New',
      ),
      TeacherDashboardStat(
        label: 'STUDENTS',
        value: uniqueStudents.length.toString(),
      ),
      TeacherDashboardStat(
        label: 'COURSES',
        value: services.length.toString(),
      ),
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
      statusLabel: service.isActive ? 'ACTIVE' : 'PAUSED',
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
      id: quote.quoteId,
      studentName: studentName,
      studentLevel: level,
      subtitle: quote.subject,
      avatarPath: student?.picture ?? '',
      actionLabel: 'See details',
    );
  }

  String _formatSessionTime(SessionModel session) {
    final DateFormat dateFormat = DateFormat('dd MMM');
    final DateFormat timeFormat = DateFormat('HH:mm');
    final int duration = session.endTime.difference(session.startTime).inMinutes;

    return '${dateFormat.format(session.date)} • '
        '${timeFormat.format(session.startTime)} - ${timeFormat.format(session.endTime)} '
        '($duration min)';
  }

  TeacherScheduleSession _toScheduleSession(
    SessionModel session,
    ServiceModel? service,
    Map<String, StudentModel> studentsById,
  ) {
    final DateFormat timeFormat = DateFormat('HH:mm');
    final int duration = session.endTime.difference(session.startTime).inMinutes;
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
}
