import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportType { session, student, teacher, parent }

enum ReportStatus { pending, reviewed, resolved, dismissed }

class ReportModel {
  final String reportId;
  final String reporterUid;
  final String reporterName;
  final String reportedId;
  final String reportedName;
  final ReportType type;
  final String text;
  final DateTime createdAt;
  final ReportStatus status;

  ReportModel({
    required this.reportId,
    required this.reporterUid,
    required this.reporterName,
    required this.reportedId,
    required this.reportedName,
    required this.type,
    required this.text,
    required this.createdAt,
    this.status = ReportStatus.pending,
  });

  Map<String, dynamic> toMap() {
    return {
      'report_id': reportId,
      'reporter_uid': reporterUid,
      'reporter_name': reporterName,
      'reported_id': reportedId,
      'reported_name': reportedName,
      'type': type.name,
      'text': text,
      'created_at': Timestamp.fromDate(createdAt),
      'status': status.name,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return (value as dynamic).toDate();
    }

    ReportType parseType(dynamic value) {
      try {
        return ReportType.values.byName(value as String);
      } catch (_) {
        return ReportType.session;
      }
    }

    ReportStatus parseStatus(dynamic value) {
      try {
        return ReportStatus.values.byName(value as String);
      } catch (_) {
        return ReportStatus.pending;
      }
    }

    return ReportModel(
      reportId: docId ?? map['report_id'] ?? '',
      reporterUid: map['reporter_uid'] ?? '',
      reporterName: map['reporter_name'] ?? '',
      reportedId: map['reported_id'] ?? '',
      reportedName: map['reported_name'] ?? '',
      type: parseType(map['type']),
      text: map['text'] ?? '',
      createdAt: parseDate(map['created_at']),
      status: parseStatus(map['status']),
    );
  }
}


