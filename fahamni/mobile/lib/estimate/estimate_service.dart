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

  /// Returns the invoice number of an already-sent estimate for [quoteId],
  /// or null if no estimate has been sent yet.
  ///
  /// [senderUid] is required to satisfy the Firestore security rule that
  /// restricts estimate reads to the sender. We query only by sender_uid
  /// (single-field — no composite index needed) and filter by quote_id
  /// client-side.
  Future<String?> fetchExistingInvoiceNumber(
    String quoteId,
    String senderUid,
  ) async {
    if (quoteId.isEmpty ||
        senderUid.isEmpty ||
        quoteId.startsWith('pending_') ||
        quoteId.startsWith('notif_')) {
      return null;
    }
    try {
      final snap = await _db
          .collection('estimates')
          .where('sender_uid', isEqualTo: senderUid)
          .get();
      for (final doc in snap.docs) {
        if ((doc.data()['quote_id'] ?? '') == quoteId) {
          final invoice = doc.data()['invoice_number'];
          if (invoice is String && invoice.isNotEmpty) return invoice;
        }
      }
    } catch (_) {
      // Any Firestore error (permission, index missing, etc.) is non-fatal;
      // a fresh invoice number will be generated instead.
    }
    return null;
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

  /// Fetches teacher name and phone from users + tutors collections.
  Future<Map<String, String>> fetchTeacherInfo(String tutorUid) async {
    if (tutorUid.isEmpty) return {};
    final results = await Future.wait([
      _db.collection('users').doc(tutorUid).get(),
      _db.collection('tutors').doc(tutorUid).get(),
    ]);
    final userData = results[0].data() ?? {};
    final tutorData = results[1].data() ?? {};
    final merged = {...userData, ...tutorData};
    final firstName = (merged['first_name'] ?? '').toString().trim();
    final lastName = (merged['last_name'] ?? '').toString().trim();
    final name = '$firstName $lastName'.trim();
    return {
      'name': name,
      'phone': (merged['phone'] ?? '').toString(),
    };
  }
}
