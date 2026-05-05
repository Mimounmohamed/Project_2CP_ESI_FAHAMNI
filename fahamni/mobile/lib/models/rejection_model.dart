import 'package:cloud_firestore/cloud_firestore.dart';

enum RejectionCause {
  invalidOrFakeIdentityDocuments,
  nameMismatchBetweenProfileAndDocuments,
  unclearOrUnreadableUploadedFiles,
  qualificationsNotRelevantToSubjectTaught,
  insufficientAcademicLevel,
}

extension RejectionCauseLabel on RejectionCause {
  String get label {
    switch (this) {
      case RejectionCause.invalidOrFakeIdentityDocuments:
        return 'Invalid or fake identity documents';
      case RejectionCause.nameMismatchBetweenProfileAndDocuments:
        return 'Name mismatch between profile and documents';
      case RejectionCause.unclearOrUnreadableUploadedFiles:
        return 'Unclear / unreadable uploaded files';
      case RejectionCause.qualificationsNotRelevantToSubjectTaught:
        return 'Qualifications not relevant to the subject taught';
      case RejectionCause.insufficientAcademicLevel:
        return 'Insufficient academic level';
    }
  }

  static RejectionCause fromString(String value) {
    return RejectionCause.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RejectionCause.invalidOrFakeIdentityDocuments,
    );
  }
}

class RejectionModel {
  final String id;
  final String teacherId;
  final String adminId;
  final RejectionCause cause;
  final DateTime rejectedAt;

  RejectionModel({
    required this.id,
    required this.teacherId,
    required this.adminId,
    required this.cause,
    required this.rejectedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'teacher_id': teacherId,
      'admin_id': adminId,
      'cause': cause.name,
      'rejected_at': Timestamp.fromDate(rejectedAt),
    };
  }

  factory RejectionModel.fromMap(Map<String, dynamic> map, {required String docId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return (value as dynamic).toDate();
    }

    return RejectionModel(
      id: docId,
      teacherId: map['teacher_id'] ?? '',
      adminId: map['admin_id'] ?? '',
      cause: RejectionCauseLabel.fromString(map['cause'] ?? ''),
      rejectedAt: parseDate(map['rejected_at']),
    );
  }
}


