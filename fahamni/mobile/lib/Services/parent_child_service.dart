import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/child_model.dart';

class ParentChildService {
  ParentChildService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String _requireUid() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('You need to be signed in first.');
    }
    return user.uid;
  }

  Future<List<ChildModel>> fetchLinkedChildren() async {
    final String parentUid = _requireUid();
    final QuerySnapshot<Map<String, dynamic>> query = await _firestore
        .collection('children')
        .where('parentUid', isEqualTo: parentUid)
        .get();

    final List<ChildModel> children = query.docs
        .map((doc) => ChildModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    children.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return children;
  }

  Future<void> createChild({
    required String firstName,
    required String lastName,
    required String level,
    required String grade,
    required List<String> subjects,
    String speciality = '',
    String gender = 'male',
  }) async {
    final String parentUid = _requireUid();
    final String childName = '$firstName $lastName'.trim();
    final DocumentReference<Map<String, dynamic>> childRef =
        _firestore.collection('children').doc();

    final String picture = gender == 'female'
        ? 'assets/images/childgirl.png'
        : 'assets/images/chidboy.png';

    await childRef.set({
      'id': childRef.id,
      'parentUid': parentUid,
      'name': childName,
      'gender': gender,
      'level': level,
      'grade': grade,
      'speciality': speciality,
      'subjects': subjects,
      'picture': picture,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('parents').doc(parentUid).set({
      'children_uids': FieldValue.arrayUnion(<String>[childRef.id]),
    }, SetOptions(merge: true));
  }

  Future<void> updateChild({
    required String childId,
    required String firstName,
    required String lastName,
    required String level,
    required String grade,
    required List<String> subjects,
    String speciality = '',
  }) async {
    final String parentUid = _requireUid();
    final DocumentReference<Map<String, dynamic>> childRef =
        _firestore.collection('children').doc(childId);

    final DocumentSnapshot<Map<String, dynamic>> snap = await childRef.get();
    if (!snap.exists || snap.data() == null) {
      throw Exception('Child profile not found.');
    }

    final String ownerUid = (snap.data()!['parentUid'] as String?) ?? '';
    if (ownerUid != parentUid) {
      throw Exception('You are not allowed to edit this child.');
    }

    await childRef.update({
      'name': '$firstName $lastName'.trim(),
      'level': level,
      'grade': grade,
      'speciality': speciality,
      'subjects': subjects,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteChild(String childId) async {
    final String parentUid = _requireUid();
    final DocumentReference<Map<String, dynamic>> childRef =
        _firestore.collection('children').doc(childId);

    final DocumentSnapshot<Map<String, dynamic>> snap = await childRef.get();
    if (!snap.exists || snap.data() == null) {
      return;
    }

    final String ownerUid = (snap.data()!['parentUid'] as String?) ?? '';
    if (ownerUid != parentUid) {
      throw Exception('You are not allowed to delete this child.');
    }

    await childRef.delete();

    await _firestore.collection('parents').doc(parentUid).set({
      'children_uids': FieldValue.arrayRemove(<String>[childId]),
    }, SetOptions(merge: true));
  }
}