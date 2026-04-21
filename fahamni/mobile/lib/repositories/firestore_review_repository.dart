import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/review_model.dart';
import '../models/service_model.dart';
import '../models/student_model.dart';
import '../models/tutor_model.dart';
import 'review_repository.dart';

class FirestoreReviewRepository implements ReviewRepository {
  FirestoreReviewRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  @override
  Future<TutorModel> getTutor(String tutorId) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore.collection('tutors').doc(tutorId).get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Tutor profile not found.');
    }

    return TutorModel.fromMap({
      ...snapshot.data()!,
      'uid': snapshot.id,
    });
  }

  @override
  Future<List<ServiceModel>> getTutorServices(String tutorId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('services')
        .where('tutor_id', isEqualTo: tutorId)
        .get();

    return snapshot.docs.map((doc) {
      return ServiceModel.fromMap({
        ...doc.data(),
        'service_id': doc.data()['service_id'] ?? doc.id,
      });
    }).toList();
  }

  @override
  Stream<List<ReviewModel>> getTutorReviews(String tutorId) {
    return _firestore
        .collection('reviews')
        .where('tutor_id', isEqualTo: tutorId)
        .snapshots()
        .map((snapshot) {
      final List<ReviewModel> reviews = snapshot.docs.map((doc) {
        return ReviewModel.fromMap({
          ...doc.data(),
          'review_id': doc.data()['review_id'] ?? doc.id,
        });
      }).toList();
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    });
  }

  @override
  Future<Map<String, StudentModel>> getReviewers(List<String> reviewerIds) async {
    final Map<String, StudentModel> reviewers = <String, StudentModel>{};
    final Set<String> distinctIds =
        reviewerIds.where((id) => id.trim().isNotEmpty).toSet();

    await Future.wait(
      distinctIds.map((reviewerId) async {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await _firestore.collection('students').doc(reviewerId).get();
        if (!snapshot.exists || snapshot.data() == null) {
          return;
        }

        reviewers[reviewerId] = StudentModel.fromMap({
          ...snapshot.data()!,
          'uid': snapshot.id,
        });
      }),
    );

    return reviewers;
  }

  @override
  Future<StudentModel?> getCurrentStudent() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore.collection('students').doc(user.uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return StudentModel.fromMap({
      ...snapshot.data()!,
      'uid': snapshot.id,
    });
  }

  @override
  Future<void> submitReview(ReviewModel review) async {
    final CollectionReference<Map<String, dynamic>> reviewsCollection =
        _firestore.collection('reviews');
    final String reviewId = review.reviewId.isNotEmpty
        ? review.reviewId
        : '${review.tutorId}_${review.reviewerId}';

    await reviewsCollection.doc(reviewId).set({
      ...review.toMap(),
      'review_id': reviewId,
    });

    final QuerySnapshot<Map<String, dynamic>> reviewsSnapshot = await reviewsCollection
        .where('tutor_id', isEqualTo: review.tutorId)
        .get();

    final List<ReviewModel> reviews = reviewsSnapshot.docs.map((doc) {
      return ReviewModel.fromMap({
        ...doc.data(),
        'review_id': doc.data()['review_id'] ?? doc.id,
      });
    }).toList();

    final double average = reviews.isEmpty
        ? 0
        : reviews
                .map((item) => item.rating)
                .reduce((value, element) => value + element) /
            reviews.length;

    await _firestore.collection('tutors').doc(review.tutorId).set(
      <String, dynamic>{
        'average_rating': double.parse(average.toStringAsFixed(1)),
      },
      SetOptions(merge: true),
    );
  }
}
