import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus { Planned, Canceled, Ongoing, Completed }

class SessionModel {
  final String sessionId;
  final String serviceId;
  final List<String> studentIds;
  final String tutorId;
  final SessionStatus status;
  final String type;
  final String modality;
  final String mode;
  final String meetingLink;
  final String notes;
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
    this.mode = '',
    this.meetingLink = '',
    this.notes = '',
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      sessionId: map['session_id'] ?? '',
      serviceId: map['service_id'] ?? '',
      studentIds: List<String>.from(map['student_ids'] ?? []),
      tutorId: map['tutor_id'] ?? '',
      status: SessionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SessionStatus.Planned,
      ),
      type: map['type'] ?? '',
      modality: map['modality'] ?? '',
      mode: map['mode'] ?? map['modality'] ?? '',
      meetingLink: map['meeting_link'] ?? '',
      notes: map['notes'] ?? '',
      // .toLocal() is crucial for Algiers (UTC+1) alignment
      date: (map['date'] as Timestamp).toDate().toLocal(),
      startTime: (map['start_time'] as Timestamp).toDate().toLocal(),
      endTime: (map['end_time'] as Timestamp).toDate().toLocal(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'service_id': serviceId,
      'student_ids': studentIds,
      'tutor_id': tutorId,
      'status': status.name,
      'type': type,
      'modality': modality,
      'mode': mode,
      'meeting_link': meetingLink,
      'notes': notes,
      'date': Timestamp.fromDate(date),
      'start_time': Timestamp.fromDate(startTime),
      'end_time': Timestamp.fromDate(endTime),
    };
  }
}
