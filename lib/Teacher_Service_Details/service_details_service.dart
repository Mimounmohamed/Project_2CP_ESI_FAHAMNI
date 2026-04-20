import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/resource_model.dart';
import '../models/session_model.dart';
import '../models/student_model.dart';

class CourseDetailsService {
  final _db = FirebaseFirestore.instance;

  // ── Sessions ──────────────────────────────────────────────
  Future<List<SessionModel>> getSessions(String serviceId) async {
    final snap = await _db
        .collection('sessions')
        .where('service_id', isEqualTo: serviceId)
        .get();
    return snap.docs.map((d) => SessionModel.fromMap(d.data())).toList();
  }

  Future<void> addSession(SessionModel session) async {
    final ref = _db.collection('sessions').doc();
    await ref.set({...session.toMap(), 'session_id': ref.id});
  }

  Future<void> deleteSession(String sessionId) async {
    await _db.collection('sessions').doc(sessionId).delete();
  }

  // ── Resources ─────────────────────────────────────────────
  Future<List<ResourceModel>> getResources(String serviceId) async {
    final QuerySnapshot<Map<String, dynamic>> sessionsSnapshot = await _db
        .collection('sessions')
        .where('service_id', isEqualTo: serviceId)
        .get();

    final List<String> sessionIds = sessionsSnapshot.docs.map((doc) => doc.id).toList();
    if (sessionIds.isEmpty) {
      return <ResourceModel>[];
    }

    final List<ResourceModel> resources = <ResourceModel>[];
    for (int i = 0; i < sessionIds.length; i += 10) {
      final List<String> batch = sessionIds.skip(i).take(10).toList();
      final QuerySnapshot<Map<String, dynamic>> resourcesSnapshot = await _db
          .collection('resources')
          .where('session_id', whereIn: batch)
          .get();
      resources.addAll(
        resourcesSnapshot.docs.map((doc) => ResourceModel.fromMap(doc.data())),
      );
    }

    return resources;
  }

  Future<void> addResource(ResourceModel resource) async {
    final ref = _db.collection('resources').doc();
    await ref.set({...resource.toMap(), 'resource_id': ref.id});
  }

  Future<void> deleteResource(String resourceId) async {
    await _db.collection('resources').doc(resourceId).delete();
  }

  // ── Members ───────────────────────────────────────────────
  Future<List<StudentModel>> getMembers(String serviceId) async {
  // Get all sessions for this service
  final snap = await _db
      .collection('sessions')
      .where('service_id', isEqualTo: serviceId)
      .get();

  // Collect all unique student IDs from all sessions
  final Set<String> studentIds = {};
  for (var doc in snap.docs) {
    final ids = List<String>.from(doc.data()['student_ids'] ?? []);
    studentIds.addAll(ids);
  }

  if (studentIds.isEmpty) return [];

  final docs = await Future.wait(
    studentIds.map((id) => _db.collection('students').doc(id).get()),
  );

  return docs
      .where((d) => d.data() != null)
      .map((d) => StudentModel.fromMap(d.data()!))
      .toList();
}
}
