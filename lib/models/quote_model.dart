enum QuoteStatus { pending, accepted, rejected, expired }

class QuoteModel {
  final String quoteId;
  final String studentId;
  final String tutorId;
  final String serviceId;
  final String serviceName;
  final String subject;
  final String level;
  final String objective;
  final String description;
  final String teachingMode;
  final String frequency;
  final String duration;
  final String budget;
  final int sessionsCount;
  final String responsePrice;
  final int responseSessionsCount;
  final QuoteStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  QuoteModel({
    required this.quoteId,
    required this.studentId,
    required this.tutorId,
    this.serviceId = '',
    this.serviceName = '',
    required this.subject,
    required this.level,
    required this.objective,
    this.description = '',
    this.teachingMode = '',
    required this.frequency,
    required this.duration,
    required this.budget,
    this.sessionsCount = 0,
    this.responsePrice = '',
    this.responseSessionsCount = 0,
    this.status = QuoteStatus.pending,
    this.createdAt,
    this.updatedAt,
  });


  Map<String, dynamic> toMap() {
    return {
      'quote_id': quoteId,
      'student_id': studentId,
      'tutor_id': tutorId,
      'service_id': serviceId,
      'service_name': serviceName,
      'subject': subject,
      'level': level,
      'objective': objective,
      'description': description,
      'teaching_mode': teachingMode,
      'frequency': frequency,
      'duration': duration,
      'budget': budget,
      'sessions_count': sessionsCount,
      'response_price': responsePrice,
      'response_sessions_count': responseSessionsCount,
      'status': status.name,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }


  factory QuoteModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is DateTime) {
        return value;
      }
      return (value as dynamic).toDate();
    }

    return QuoteModel(
      quoteId: map['quote_id'] ?? '',
      studentId: map['student_id'] ?? '',
      tutorId: map['tutor_id'] ?? '',
      serviceId: map['service_id'] ?? '',
      serviceName: map['service_name'] ?? '',
      subject: map['subject'] ?? '',
      level: map['level'] ?? '',
      objective: map['objective'] ?? '',
      description: map['description'] ?? map['objective'] ?? '',
      teachingMode: map['teaching_mode'] ?? '',
      frequency: map['frequency'] ?? '',
      duration: map['duration'] ?? '',
      budget: map['budget'] ?? '',
      sessionsCount: map['sessions_count'] ?? 0,
      responsePrice: map['response_price'] ?? '',
      responseSessionsCount: map['response_sessions_count'] ?? 0,
      status: QuoteStatus.values.byName(map['status'] ?? 'pending'),
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }
}
