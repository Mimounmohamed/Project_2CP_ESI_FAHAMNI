import '../models/review_model.dart';
import '../models/service_model.dart';
import '../models/student_model.dart';
import '../models/tutor_model.dart';

abstract class ReviewRepository {
  Future<TutorModel> getTutor(String tutorId);
  Future<List<ServiceModel>> getTutorServices(String tutorId);
  Stream<List<ReviewModel>> getTutorReviews(String tutorId);
  Future<Map<String, StudentModel>> getReviewers(List<String> reviewerIds);
  Future<StudentModel?> getCurrentStudent();
  Future<void> submitReview(ReviewModel review);
}


