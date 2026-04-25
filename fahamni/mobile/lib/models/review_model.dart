class ReviewModel {
  final String reviewId;
  final String reviewerId;
  final String tutorId;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final bool isHidden;

  ReviewModel({
    required this.reviewId,
    required this.reviewerId,
    required this.tutorId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.isHidden = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'review_id': reviewId,
      'reviewer_id': reviewerId,
      'student_id': reviewerId,
      'tutor_id': tutorId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
      'is_hidden': isHidden,
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    double parseRating(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return ReviewModel(
      reviewId: map['review_id'] ?? '',
      reviewerId: map['reviewer_id'] ?? map['student_id'] ?? '',
      tutorId: map['tutor_id'] ?? '',
      rating: parseRating(map['rating']),
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as dynamic).toDate(),
      isHidden: map['is_hidden'] == true,
    );
  }
}
