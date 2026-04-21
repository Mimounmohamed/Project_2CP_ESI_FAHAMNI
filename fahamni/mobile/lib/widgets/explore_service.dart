import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/service_model.dart';


class Explore_service {

final FirebaseFirestore _db = FirebaseFirestore.instance;
final FirebaseAuth _auth = FirebaseAuth.instance;


Future<List<TutorModel>> getTutorsFromServices(List<ServiceModel> services) async {
  final tutors = await Future.wait(
      services
          .where((s) => s.tutorId.isNotEmpty)
          .map((s) => _db.collection('tutors').doc(s.tutorId).get())
  );

  return tutors
      .where((doc) => doc.data() != null)
      .map((doc) => TutorModel.fromMap(doc.data()!))
      .toList();
}

Future<List<TutorModel>> getAllTutors() async {
  final snapshot = await _db.collection('tutors').get();
  return snapshot.docs.map((doc) => TutorModel.fromMap(doc.data())).toList();
}

Future<List<ServiceModel>> getAllServices() async {
  final snapshot = await _db.collection('services').get();
  return snapshot.docs.map((doc) => ServiceModel.fromMap(doc.data())).toList();
}
}