import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'models/teacher_portal_models.dart';
import '../models/quote_model.dart';
import '../models/service_model.dart';
import '../models/session_model.dart';
import '../models/student_model.dart';
import '../models/tutor_model.dart';

class TeacherPortalService {
  TeacherPortalService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<TeacherServicesDashboardData> loadDashboard() async {
    final TutorModel tutor = await _loadCurrentTutor();
    final List<ServiceModel> services = await _loadServices(tutor.uid);
    final List<QuoteModel> quotes = await _loadQuotes(tutor.uid);
    final Map<String, StudentModel> students = await _loadStudents(quotes);

    final List<TeacherJoinRequestDetail> joinRequests = quotes.map((quote) {
      final StudentModel? student = students[quote.studentId];
      final String studentName = _studentName(student);
      final String studentLevel = student?.schoolLevel.isNotEmpty == true
          ? student!.schoolLevel
          : (quote.level.isNotEmpty ? quote.level : 'Student');
      final String serviceTitle = quote.serviceName.isNotEmpty
          ? quote.serviceName
          : (quote.subject.isNotEmpty ? quote.subject : 'Custom Quote');
      return TeacherJoinRequestDetail(
        quote: quote,
        studentName: studentName,
        studentLevel: studentLevel,
        studentAvatar: student?.picture ?? '',
        serviceTitle: serviceTitle,
        description: quote.description.isNotEmpty ? quote.description : quote.objective,
        subject: quote.subject,
        teachingMode: quote.teachingMode.isNotEmpty ? quote.teachingMode : 'Hybrid',
        sessionsCount: quote.sessionsCount > 0 ? quote.sessionsCount : _parseSessions(quote.frequency),
        sessionDurationLabel: _normalizeDuration(quote.duration),
        createdAtLabel: quote.createdAt != null
            ? DateFormat('hh:mm a').format(quote.createdAt!)
            : 'Now',
      );
    }).toList();

    joinRequests.sort((a, b) {
      final DateTime aDate = a.quote.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bDate = b.quote.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
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
    final DocumentReference<Map<String, dynamic>> doc =
        _firestore.collection('services').doc();
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
      createdAt: now.toDate(),
      updatedAt: now.toDate(),
    );

    await doc.set({
      ...model.toMap(),
      'created_at': now,
      'updated_at': now,
    });

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
    final _QuoteDocumentLocation location =
        await _locateQuoteDocument(request.quote.quoteId);

    await location.reference.update({
      'status': status.name,
      'response_price': response?.priceLabel ?? '',
      'response_sessions_count': response?.sessionsCount ?? 0,
      'updated_at': Timestamp.now(),
    });
  }

  Future<void> createSession({
    required TeacherJoinRequestDetail request,
    required TeacherSessionDraft draft,
  }) async {
    final TutorModel tutor = await _loadCurrentTutor();
    final DocumentReference<Map<String, dynamic>> doc =
        _firestore.collection('sessions').doc();
    final DateTime startTime = DateTime(
      draft.date.year,
      draft.date.month,
      draft.date.day,
      draft.startTime.hour,
      draft.startTime.minute,
    );
    final DateTime endTime =
        startTime.add(Duration(minutes: draft.durationMinutes));

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
    final DateTime endTime =
        startTime.add(Duration(minutes: draft.durationMinutes));

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
      return (bDate?.millisecondsSinceEpoch ?? 0)
          .compareTo(aDate?.millisecondsSinceEpoch ?? 0);
    });

    return snapshot.docs.first.id;
  }

  Future<void> addResource({
    required TeacherJoinRequestDetail request,
    required TeacherResourceDraft draft,
  }) async {
    final TutorModel tutor = await _loadCurrentTutor();
    final DocumentReference<Map<String, dynamic>> doc =
        _firestore.collection('resources').doc();

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
      'content_type': draft.type == TeacherResourceType.link ? 'link' : 'document',
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
      return ServiceModel.fromMap({
        ...doc.data(),
        'service_id': doc.data()['service_id'] ?? doc.id,
      });
    }).toList();

    services.sort((a, b) {
      if (a.isActive == b.isActive) {
        final DateTime aDate = a.updatedAt ?? a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bDate = b.updatedAt ?? b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      }
      return a.isActive ? -1 : 1;
    });
    return services;
  }

  Future<List<QuoteModel>> _loadQuotes(String tutorId) async {
    Future<List<QuoteModel>> fetch(String collectionName) async {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection(collectionName)
          .where('tutor_id', isEqualTo: tutorId)
          .get();
      return snapshot.docs.map((doc) {
        return QuoteModel.fromMap({
          ...doc.data(),
          'quote_id': doc.data()['quote_id'] ?? doc.id,
        });
      }).toList();
    }

    final List<QuoteModel> quoteRequests = await fetch('quote_requests');
    final List<QuoteModel> quotes = await fetch('quotes');
    final Map<String, QuoteModel> merged = <String, QuoteModel>{};

    for (final QuoteModel quote in [...quoteRequests, ...quotes]) {
      merged[quote.quoteId] = quote;
    }

    return merged.values
        .where((quote) => quote.status == QuoteStatus.pending)
        .toList();
  }

  Future<Map<String, StudentModel>> _loadStudents(List<QuoteModel> quotes) async {
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

  Future<_QuoteDocumentLocation> _locateQuoteDocument(String quoteId) async {
    for (final String collection in <String>['quote_requests', 'quotes']) {
      final DocumentReference<Map<String, dynamic>> reference =
          _firestore.collection(collection).doc(quoteId);
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await reference.get();
      if (snapshot.exists) {
        return _QuoteDocumentLocation(collection: collection, reference: reference);
      }
    }
    throw Exception('Quote request not found.');
  }

  int _parseSessions(String frequency) {
    final RegExpMatch? match = RegExp(r'(\d+)').firstMatch(frequency);
    return int.tryParse(match?.group(1) ?? '') ?? 12;
  }

  String _normalizeDuration(String duration) {
    if (duration.trim().isEmpty) {
      return '90 min';
    }
    return duration.toLowerCase().contains('min') ? duration : '$duration min';
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
