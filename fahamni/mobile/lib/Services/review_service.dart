import '../Services/notification_service.dart';
import '../models/notification_model.dart';
import '../models/review_model.dart';
import '../models/service_model.dart';
import '../models/student_model.dart';
import '../models/tutor_review_bundle.dart';
import '../repositories/firestore_review_repository.dart';
import '../repositories/review_repository.dart';

class ReviewService {
  ReviewService({
    ReviewRepository? repository,
    NotificationService? notificationService,
  })  : _repository = repository ?? FirestoreReviewRepository(),
        _notificationService = notificationService ?? NotificationService();

  final ReviewRepository _repository;
  final NotificationService _notificationService;

  Future<TutorReviewBundle> loadTutorReviewBundle(String tutorId) async {
    final tutor = await _repository.getTutor(tutorId);
    final services = await _repository.getTutorServices(tutorId);
    final reviews = await _repository.getTutorReviews(tutorId).first;
    final reviewers = await _repository
        .getReviewers(reviews.map((review) => review.reviewerId).toList());

    final double averageRating = reviews.isEmpty
        ? tutor.averageRating
        : reviews
                .map((review) => review.rating)
                .reduce((value, element) => value + element) /
            reviews.length;

    return TutorReviewBundle(
      tutor: tutor,
      services: services,
      reviews: reviews,
      reviewers: reviewers,
      averageRating: averageRating,
    );
  }

  Stream<List<ReviewModel>> getTutorReviews(String tutorId) {
    return _repository.getTutorReviews(tutorId);
  }

  Future<Map<String, StudentModel>> getReviewers(List<String> reviewerIds) {
    return _repository.getReviewers(reviewerIds);
  }

  Future<StudentModel?> getCurrentStudent() {
    return _repository.getCurrentStudent();
  }

  Future<void> submitReview({
    required String tutorId,
    required double rating,
    required String comment,
  }) async {
    final StudentModel? student = await _repository.getCurrentStudent();
    if (student == null) {
      throw Exception('Only signed-in students can leave feedback.');
    }

    final ReviewModel review = ReviewModel(
      reviewId: '${tutorId}_${student.uid}',
      reviewerId: student.uid,
      tutorId: tutorId,
      rating: rating,
      comment: comment.trim(),
      createdAt: DateTime.now(),
    );

    await _repository.submitReview(review);
    await _notificationService.sendNotification(
      NotificationModel(
        title: 'New review received',
        content: '${student.firstName} left you a ${rating.toStringAsFixed(1)} star review.',
        dateTime: DateTime.now(),
        isRead: false,
        notificationId: '',
        receiverId: tutorId,
        type: 'review',
        senderId: student.uid,
        tutorId: tutorId,
      ),
    );
  }

  String formatShortDate(DateTime date) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(date);
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes.clamp(1, 59)} min ago';
      }
      return '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) {
      return '1 day ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    return '${_monthLabel(date.month)} ${date.day}, ${date.year}';
  }

  String experienceLabel(int years) {
    return years == 1 ? '1 Year Experience' : '$years Years Experience';
  }

  String availabilityLabel(bool isAvailable) {
    return isAvailable ? 'Available' : 'Busy';
  }

  String priceLabel(ServiceModel service) {
    return '${service.price.toInt()} DA';
  }

  String _monthLabel(int month) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}


