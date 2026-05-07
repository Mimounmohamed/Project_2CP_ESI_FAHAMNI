import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'estimate_model.dart';
import 'estimate_pdf_generator.dart';

class EstimateService {
  EstimateService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Future<String> generateInvoiceNumber() async {
    final counterRef = _db.collection('config').doc('invoice_counter');
    int newCount = 0;

    await _db.runTransaction((tx) async {
      final snap = await tx.get(counterRef);
      newCount = ((snap.data()?['count'] ?? 0) as int) + 1;
      tx.set(counterRef, {'count': newCount}, SetOptions(merge: true));
    });

    final year = DateTime.now().year;
    return 'EST-$year-${newCount.toString().padLeft(4, '0')}';
  }

  /// Generates the PDF, encodes it as base64, and calls the Firebase Function
  /// to send the estimate email with the PDF attached.
  Future<void> sendEstimate(EstimateData data) async {
    final pdfBytes = await EstimatePdfGenerator.generate(data);
    final pdfBase64 = base64Encode(pdfBytes);

    final callable = _functions.httpsCallable('sendEstimate');
    await callable.call({
      'pdfBase64': pdfBase64,
      'recipientEmail': data.studentEmail,
      'studentName': data.studentName,
      'teacherName': data.teacherName,
      'invoiceNumber': data.invoiceNumber,
      'subject': data.subject,
      'invoiceData': data.toFirestoreMap(),
    });
  }

  /// Fetches contact info (email, phone) for a student or child by ID.
  Future<Map<String, String>> fetchStudentContact(String studentId) async {
    if (studentId.isEmpty) return {};

    final studentSnap =
        await _db.collection('students').doc(studentId).get();
    if (studentSnap.exists) {
      final d = studentSnap.data()!;
      return {
        'email': (d['email'] ?? '').toString(),
        'phone': (d['phone'] ?? '').toString(),
      };
    }

    final childSnap =
        await _db.collection('children').doc(studentId).get();
    if (childSnap.exists) {
      final d = childSnap.data()!;
      final parentUid = (d['parentUid'] ?? '').toString();
      if (parentUid.isNotEmpty) {
        final parentSnap =
            await _db.collection('users').doc(parentUid).get();
        if (parentSnap.exists) {
          final pd = parentSnap.data()!;
          return {
            'email': (pd['email'] ?? '').toString(),
            'phone': (pd['phone'] ?? '').toString(),
          };
        }
      }
    }

    return {};
  }

  /// Fetches the current teacher's phone number from Firestore.
  Future<String> fetchTeacherPhone(String tutorUid) async {
    if (tutorUid.isEmpty) return '';
    final snap = await _db.collection('tutors').doc(tutorUid).get();
    return (snap.data()?['phone'] ?? '').toString();
  }
}
