import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fahamni/models/session_model.dart';
import 'package:fahamni/models/service_model.dart';
import 'package:fahamni/models/parent_model.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
    if (id.isEmpty) throw Exception('Tutor id is empty');

    final DocumentSnapshot<Map<String, dynamic>> tutorDoc =
        await _db.collection('tutors').doc(id).get();
    if (tutorDoc.exists && tutorDoc.data() != null) {
      return TutorModel.fromMap(_withDocId(tutorDoc, idKey: 'uid', uidKey: 'uid'));
    }

    // Some tutors are registered only in the users collection.
    final DocumentSnapshot<Map<String, dynamic>> userDoc =
        await _db.collection('users').doc(id).get();
    if (userDoc.exists && userDoc.data() != null) {
      return TutorModel.fromMap(_withDocId(userDoc, idKey: 'uid', uidKey: 'uid'));
    }

    throw Exception('Tutor document not found for $id');
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

    final Map<String, SessionModel> sessionsById = {};

    // Path 1: sessions where student is directly listed in student_ids.
    final QuerySnapshot<Map<String, dynamic>> byStudentId = await _db
        .collection('sessions')
        .where('student_ids', arrayContains: uid)
        .get();
    for (final doc in byStudentId.docs) {
      sessionsById[doc.id] =
          SessionModel.fromMap(_withDocId(doc, idKey: 'session_id'));
    }

    // Path 2: sessions belonging to services the student is enrolled in.
    // When a teacher accepts a quote, the student is added to the SERVICE's
    // student_ids — but the session may have been created with an empty list.
    final QuerySnapshot<Map<String, dynamic>> enrolledServices = await _db
        .collection('services')
        .where('student_ids', arrayContains: uid)
        .get();

    if (enrolledServices.docs.isNotEmpty) {
      final List<String> serviceIds =
          enrolledServices.docs.map((d) => d.id).toList();

      // Firestore 'whereIn' limit is 30.
      for (var i = 0; i < serviceIds.length; i += 30) {
        final List<String> chunk =
            serviceIds.sublist(i, (i + 30).clamp(0, serviceIds.length));
        final QuerySnapshot<Map<String, dynamic>> snap = await _db
            .collection('sessions')
            .where('service_id', whereIn: chunk)
            .get();
        for (final doc in snap.docs) {
          sessionsById.putIfAbsent(
            doc.id,
            () => SessionModel.fromMap(_withDocId(doc, idKey: 'session_id')),
          );
        }
      }
    }

    // Path 3: sessions explicitly listed in the student document's courses field.
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

    debugPrint('[getCourses] uid=$uid | found ${sessionsById.length} sessions '
        '(${byStudentId.docs.length} by studentId, '
        '${enrolledServices.docs.length} enrolled services)');
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


