class EstimateData {
  EstimateData({
    required this.invoiceNumber,
    required this.date,
    required this.studentName,
    required this.studentEmail,
    required this.studentPhone,
    required this.studentLevel,
    required this.teacherName,
    required this.teacherEmail,
    required this.teacherPhone,
    required this.subject,
    required this.description,
    required this.teachingMode,
    required this.sessionsCount,
    required this.sessionDuration,
    required this.pricePerSession,
    this.quoteId = '',
    this.studentId = '',
  });

  final String invoiceNumber;
  final DateTime date;
  final String quoteId;
  final String studentId;

  final String studentName;
  final String studentEmail;
  final String studentPhone;
  final String studentLevel;

  final String teacherName;
  final String teacherEmail;
  final String teacherPhone;
  final String subject;

  final String description;
  final String teachingMode;
  final int sessionsCount;
  final String sessionDuration;
  final double pricePerSession;

  double get total => sessionsCount * pricePerSession;

  String get formattedTotal {
    final t = total.toInt();
    final s = t.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()} DA';
  }

  String get formattedPrice {
    final p = pricePerSession.toInt();
    final s = p.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '${buf.toString()} DA';
  }

  Map<String, dynamic> toFirestoreMap() => {
    'invoice_number': invoiceNumber,
    'quote_id': quoteId,
    'student_id': studentId,
    'student_name': studentName,
    'student_email': studentEmail,
    'teacher_name': teacherName,
    'teacher_email': teacherEmail,
    'subject': subject,
    'sessions_count': sessionsCount,
    'session_duration': sessionDuration,
    'price_per_session': pricePerSession,
    'total': total,
    'teaching_mode': teachingMode,
    'issued_at': date.toIso8601String(),
  };
}
