import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/session_model.dart';
import '../../models/student_model.dart';
import '../../models/resource_model.dart';

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
    await ref.set({...session.toMap(), 'sessionId': ref.id});
  }

  Future<void> deleteSession(String sessionId) async {
    await _db.collection('sessions').doc(sessionId).delete();
  }

  // ── Resources ─────────────────────────────────────────────
  Future<List<ResourceModel>> getResources(String serviceId) async {
    final snap = await _db
        .collection('resources')
        .where('serviceId', isEqualTo: serviceId)
        .get();
    return snap.docs.map((d) => ResourceModel.fromMap(d.data())).toList();
  }

  Future<void> addResource(ResourceModel resource) async {
    final ref = _db.collection('resources').doc();
    await ref.set({...resource.toMap(), 'resourceId': ref.id});
  }

  Future<void> deleteResource(String resourceId) async {
    await _db.collection('resources').doc(resourceId).delete();
  }

  // ── Members ───────────────────────────────────────────────
  Future<List<StudentModel>> getMembers(List<String> studentIds) async {
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