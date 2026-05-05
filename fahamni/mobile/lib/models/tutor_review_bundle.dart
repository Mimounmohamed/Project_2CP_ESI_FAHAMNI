import 'review_model.dart';
import 'service_model.dart';
import 'student_model.dart';
import 'tutor_model.dart';

class TutorReviewBundle {
  const TutorReviewBundle({
    required this.tutor,
    required this.services,
    required this.reviews,
    required this.reviewers,
    required this.averageRating,
  });

  final TutorModel tutor;
  final List<ServiceModel> services;
  final List<ReviewModel> reviews;
  final Map<String, StudentModel> reviewers;
  final double averageRating;
}


