import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report_model.dart';
import '../models/resource_model.dart';
import '../models/session_model.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';

class CourseDetailsService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Sessions ──────────────────────────────────────────────
  Future<List<SessionModel>> getSessions(String serviceId) async {
    final snap = await _db
        .collection('sessions')
        .where('service_id', isEqualTo: serviceId)
        .get();
    final sessions = snap.docs
        .map((d) => SessionModel.fromMap({...d.data(), 'session_id': d.id}))
        .toList();
    sessions.sort((a, b) => a.startTime.compareTo(b.startTime));
    return sessions;
  }

  Future<void> addSession(SessionModel session) async {
    final ref = _db.collection('sessions').doc();
    await ref.set({...session.toMap(), 'session_id': ref.id});
  }

  Future<void> deleteSession(String sessionId) async {
    await _db.collection('sessions').doc(sessionId).delete();
  }

  Future<void> updateSession(SessionModel session) async {
    await _db
        .collection('sessions')
        .doc(session.sessionId)
        .set(session.toMap(), SetOptions(merge: true));
  }

  Future<void> cancelSession(String sessionId) async {
    await _db.collection('sessions').doc(sessionId).set({
      'status': SessionStatus.Canceled.name,
    }, SetOptions(merge: true));
  }

  // ── Resources ─────────────────────────────────────────────
  Future<List<ResourceModel>> getResources(String serviceId) async {
    final QuerySnapshot<Map<String, dynamic>> sessionsSnapshot = await _db
        .collection('sessions')
        .where('service_id', isEqualTo: serviceId)
        .get();

    final List<String> sessionIds = sessionsSnapshot.docs
        .map((doc) => doc.id)
        .toList();
    final List<ResourceModel> resources = <ResourceModel>[];
    final Set<String> seenResourceIds = <String>{};

    final QuerySnapshot<Map<String, dynamic>> serviceResourcesSnapshot =
        await _db
            .collection('resources')
            .where('service_id', isEqualTo: serviceId)
            .get();

    for (final doc in serviceResourcesSnapshot.docs) {
      final resource = ResourceModel.fromMap(doc.data());
      resources.add(resource);
      seenResourceIds.add(resource.resourceId);
    }

    if (sessionIds.isNotEmpty) {
      for (int i = 0; i < sessionIds.length; i += 10) {
        final List<String> batch = sessionIds.skip(i).take(10).toList();
        final QuerySnapshot<Map<String, dynamic>> resourcesSnapshot = await _db
            .collection('resources')
            .where('session_id', whereIn: batch)
            .get();
        for (final doc in resourcesSnapshot.docs) {
          final resource = ResourceModel.fromMap(doc.data());
          if (!seenResourceIds.contains(resource.resourceId)) {
            resources.add(resource);
            seenResourceIds.add(resource.resourceId);
          }
        }
      }
    }

    resources.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return resources;
  }

  Future<void> addResource(ResourceModel resource, {String? serviceId}) async {
    final ref = _db.collection('resources').doc();
    final Map<String, dynamic> data = {
      ...resource.toMap(),
      'resource_id': ref.id,
    };
    if (serviceId != null && serviceId.isNotEmpty) {
      data['service_id'] = serviceId;
    }
    await ref.set(data);
  }

  Future<void> deleteResource(String resourceId) async {
    await _db.collection('resources').doc(resourceId).delete();
  }

  // ── Members ───────────────────────────────────────────────
  Future<List<StudentModel>> getMembers(String serviceId) async {
    // Get the service doc to get student_ids directly
    final serviceDoc = await _db.collection('services').doc(serviceId).get();
    if (!serviceDoc.exists) return [];

    final List<String> studentIds = List<String>.from(
      serviceDoc.data()?['student_ids'] ?? [],
    );

    if (studentIds.isEmpty) return [];

    final docs = await Future.wait(studentIds.map(_loadStudentOrChild));

    return docs.whereType<StudentModel>().toList();
  }

  Future<List<StudentModel>> getPendingRequests(String serviceId) async {
    final serviceDoc = await _db.collection('services').doc(serviceId).get();
    if (!serviceDoc.exists) return [];

    final List<String> pendingIds = List<String>.from(
      serviceDoc.data()?['pending_ids'] ?? [],
    );

    if (pendingIds.isEmpty) return [];

    final docs = await Future.wait(pendingIds.map(_loadStudentOrChild));

    return docs.whereType<StudentModel>().toList();
  }

  Future<StudentModel?> _loadStudentOrChild(String id) async {
    final studentDoc = await _db.collection('students').doc(id).get();
    if (studentDoc.exists && studentDoc.data() != null) {
      return StudentModel.fromMap({
        ...studentDoc.data()!,
        'uid': studentDoc.id,
      });
    }

    final childDoc = await _db.collection('children').doc(id).get();
    if (!childDoc.exists || childDoc.data() == null) {
      return null;
    }

    final data = childDoc.data()!;
    final String name = (data['name'] ?? '').toString().trim();
    final List<String> parts = name.split(RegExp(r'\s+'));
    return StudentModel(
      uid: childDoc.id,
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

  Future<void> handleJoinRequest(
    String serviceId,
    String studentId,
    bool accept,
  ) async {
    final serviceRef = _db.collection('services').doc(serviceId);

    if (accept) {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(serviceRef);
        if (!snapshot.exists) return;

        final List studentIds = List.from(
          snapshot.data()?['student_ids'] ?? [],
        );
        final List pendingIds = List.from(
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
        });
      });
    } else {
      await serviceRef.update({
        'pending_ids': FieldValue.arrayRemove([studentId]),
      });
    }
  }

  Future<void> submitStudentReport({
    required StudentModel student,
    required String text,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('You need to be signed in to submit a report.');
    }

    final reporterName = await _loadReporterName(currentUser.uid);
    final reportRef = _db.collection('reports').doc();
    final report = ReportModel(
      reportId: reportRef.id,
      reporterUid: currentUser.uid,
      reporterName: reporterName,
      reportedId: student.uid,
      reportedName: '${student.firstName} ${student.lastName}'.trim(),
      type: ReportType.student,
      text: text,
      createdAt: DateTime.now(),
    );

    await reportRef.set(report.toMap());
  }

  Future<String> _loadReporterName(String uid) async {
    final userDoc = await _db.collection('users').doc(uid).get();
    final userData = userDoc.data();
    final String userName = _nameFromMap(userData);
    if (userName.isNotEmpty) {
      return userName;
    }

    final tutorDoc = await _db.collection('tutors').doc(uid).get();
    final tutorName = _nameFromMap(tutorDoc.data());
    return tutorName.isNotEmpty ? tutorName : 'Teacher';
  }

  String _nameFromMap(Map<String, dynamic>? data) {
    if (data == null) {
      return '';
    }
    return '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
  }
}
