import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fahamni/models/session_model.dart';
import 'package:fahamni/models/service_model.dart';
import 'package:fahamni/models/parent_model.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/student_model.dart';

class studenthomepage_service {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic> _withDocId(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String idKey,
    String? uidKey,
  }) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return <String, dynamic>{
      ...data,
      idKey: data[idKey] ?? doc.id,
      ?uidKey: data[uidKey] ?? doc.id,
    };
  }

  Future<StudentModel> getStudentData() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final DocumentSnapshot<Map<String, dynamic>> doc = await _db
        .collection('students')
        .doc(user.uid)
        .get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Student document not found for ${user.uid}');
    }

    return StudentModel.fromMap(_withDocId(doc, idKey: 'uid', uidKey: 'uid'));
  }

  Future<StudentModel?> getStudentDataById(String id) async {
    final String studentId = id.trim();
    if (studentId.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> doc = await _db
        .collection('students')
        .doc(studentId)
        .get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return StudentModel.fromMap(_withDocId(doc, idKey: 'uid', uidKey: 'uid'));
  }

  Future<ParentModel> getParentData() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    final DocumentSnapshot<Map<String, dynamic>> doc = await _db
        .collection('parents')
        .doc(user.uid)
        .get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Parent document not found for ${user.uid}');
    }

    final Map<String, dynamic> parentMap =
        _withDocId(doc, idKey: 'uid', uidKey: 'uid');

    if (parentMap['children_uids'] == null && parentMap['childrenUids'] is List) {
      parentMap['children_uids'] = List<String>.from(parentMap['childrenUids']);
    }

    return ParentModel.fromMap(parentMap);
  }

  Future<List<StudentModel>> getLinkedChildren(List<String> ids) async {
    final List<String> childIds = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (childIds.isEmpty) {
      return <StudentModel>[];
    }

    final List<DocumentSnapshot<Map<String, dynamic>>> docs = await Future.wait(
      childIds.map((id) => _db.collection('students').doc(id).get()),
    );

    return docs
        .where((doc) => doc.exists && doc.data() != null)
        .map(
          (doc) =>
              StudentModel.fromMap(_withDocId(doc, idKey: 'uid', uidKey: 'uid')),
        )
        .toList();
  }

  Future<TutorModel> getTutorData(String id) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _db
        .collection('tutors')
        .doc(id)
        .get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Tutor document not found for $id');
    }

    return TutorModel.fromMap(_withDocId(doc, idKey: 'uid', uidKey: 'uid'));
  }

  Future<List<TutorModel>> getFavoriteTeachers(List<String> ids) async {
    final Set<String> tutorIds = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (tutorIds.isEmpty) {
      return <TutorModel>[];
    }

    final List<DocumentSnapshot<Map<String, dynamic>>> docs = await Future.wait(
      tutorIds.map((id) => _db.collection('tutors').doc(id).get()),
    );

    return docs
        .where((doc) => doc.exists && doc.data() != null)
        .map(
          (doc) =>
              TutorModel.fromMap(_withDocId(doc, idKey: 'uid', uidKey: 'uid')),
        )
        .toList();
  }

  Future<List<SessionModel>> getCourses(List<String> ids, {String? studentId}) async {
    final User? user = _auth.currentUser;
    final String uid = studentId ?? user?.uid ?? '';
    if (uid.isEmpty) {
      return <SessionModel>[];
    }

    // Always query by student_ids — the most reliable source of truth.
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _db
        .collection('sessions')
        .where('student_ids', arrayContains: uid)
        .get();

    final Map<String, SessionModel> sessionsById = {
      for (final doc in snapshot.docs.where((d) => d.data() != null))
        doc.id: SessionModel.fromMap(_withDocId(doc, idKey: 'session_id')),
    };

    // Also fetch any sessions explicitly listed in the student's courses field,
    // in case student_ids wasn't populated on older documents.
    final Set<String> extraIds = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && !sessionsById.containsKey(id))
        .toSet();

    if (extraIds.isNotEmpty) {
      final List<DocumentSnapshot<Map<String, dynamic>>> docs =
          await Future.wait(
            extraIds.map((id) => _db.collection('sessions').doc(id).get()),
          );

      for (final doc in docs.where((d) => d.exists && d.data() != null)) {
        sessionsById[doc.id] =
            SessionModel.fromMap(_withDocId(doc, idKey: 'session_id'));
      }
    }

    return sessionsById.values.toList();
  }

  Future<ServiceModel?> getServiceData(String id) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _db
        .collection('services')
        .doc(id)
        .get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return ServiceModel.fromMap(_withDocId(doc, idKey: 'service_id'));
  }
}
