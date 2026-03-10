class SessionModel {
  final String sessionId;
  final String serviceId;
  final List<String> studentIds;
  final String tutorId;
  final String status;
  final String type;
  final String modality;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;

  SessionModel({
    required this.sessionId,
    required this.serviceId,
    required this.studentIds,
    required this.tutorId,
    required this.status,
    required this.type,
    required this.modality,
    required this.date,
    required this.startTime,
    required this.endTime,
  });


  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'service_id': serviceId,
      'student_ids': studentIds,
      'tutor_id': tutorId,
      'status': status,
      'type': type,
      'modality': modality,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
    };
  }


  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      sessionId: map['session_id'] ?? '',
      serviceId: map['service_id'] ?? '',
      studentIds: List<String>.from(map['student_ids'] ?? []),
      tutorId: map['tutor_id'] ?? '',
      status: map['status'] ?? '',
      type: map['type'] ?? '',
      modality: map['modality'] ?? '',
      date: (map['date'] as dynamic).toDate(),
      startTime: (map['start_time'] as dynamic).toDate(),
      endTime: (map['end_time'] as dynamic).toDate(),
    );
  }
}