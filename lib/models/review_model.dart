class ReviewModel {
  final String reviewId;
  final String reviewerId;
  final String tutorId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.reviewId,
    required this.reviewerId,
    required this.tutorId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'review_id': reviewId,
      'student_id': reviewerId,
      'tutor_id': tutorId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      reviewId: map['review_id'] ?? '',
      reviewerId: map['reviewer_id'] ?? '',
      tutorId: map['tutor_id'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as dynamic).toDate(),
    );
  }
}