import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ServicesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> fetchFullCardData(String serviceId, String tutorId) async {
    try {
      // Future.wait runs both requests in parallel
      final results = await Future.wait([
        _db.collection('services').doc(serviceId).get(),
        _db.collection('tutors').doc(tutorId).get(),
      ]);

      return {
        'service': results[0].data(),
        'tutor': results[1].data(),
      };
    } catch (e) {
      debugPrint("Error fetching card details: $e");
      return {
        'service': null,
        'tutor': null,
      };
    }
  }

  // CRUD FOR SERVICES

  /// Get all available services 
  Stream<List<Map<String, dynamic>>> streamAllServices() {
    return _db.collection('services').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  /// Get a single service by ID
  Future<Map<String, dynamic>?> getServiceById(String serviceId) async {
    final doc = await _db.collection('services').doc(serviceId).get();
    return doc.data();
  }

  /// Create or Update a service
  Future<void> upsertService(String serviceId, Map<String, dynamic> data) async {
    await _db.collection('services').doc(serviceId).set(data, SetOptions(merge: true));
  }
}

