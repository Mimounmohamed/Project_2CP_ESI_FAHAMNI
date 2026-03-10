enum QuoteStatus { pending, accepted, rejected, expired }

class QuoteModel {
  final String quoteId;
  final String studentId;
  final String tutorId;
  final String subject;
  final String level;
  final String objective;
  final String frequency;
  final String duration;
  final String budget;
  final QuoteStatus status;

  QuoteModel({
    required this.quoteId,
    required this.studentId,
    required this.tutorId,
    required this.subject,
    required this.level,
    required this.objective,
    required this.frequency,
    required this.duration,
    required this.budget,
    this.status = QuoteStatus.pending,
  });


  Map<String, dynamic> toMap() {
    return {
      'quote_id': quoteId,
      'student_id': studentId,
      'tutor_id': tutorId,
      'subject': subject,
      'level': level,
      'objective': objective,
      'frequency': frequency,
      'duration': duration,
      'budget': budget,
      'status': status.name,
    };
  }


  factory QuoteModel.fromMap(Map<String, dynamic> map) {
    return QuoteModel(
      quoteId: map['quote_id'] ?? '',
      studentId: map['student_id'] ?? '',
      tutorId: map['tutor_id'] ?? '',
      subject: map['subject'] ?? '',
      level: map['level'] ?? '',
      objective: map['objective'] ?? '',
      frequency: map['frequency'] ?? '',
      duration: map['duration'] ?? '',
      budget: map['budget'] ?? '',
      status: QuoteStatus.values.byName(map['status'] ?? 'pending'),
    );
  }
}