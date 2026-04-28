import 'package:fahamni/models/quote_model.dart';
import 'package:fahamni/models/service_model.dart';
import 'package:fahamni/models/tutor_model.dart';

enum TeacherServicesFilter { all, active, inactive }

enum TeacherResourceType { document, link }

class TeacherServicesDashboardData {
  const TeacherServicesDashboardData({
    required this.tutor,
    required this.services,
    required this.joinRequests,
  });

  final TutorModel tutor;
  final List<ServiceModel> services;
  final List<TeacherJoinRequestDetail> joinRequests;
}

class TeacherJoinRequestDetail {
  const TeacherJoinRequestDetail({
    required this.quote,
    required this.studentName,
    required this.studentLevel,
    required this.studentAvatar,
    required this.serviceTitle,
    required this.description,
    required this.subject,
    required this.teachingMode,
    required this.sessionsCount,
    required this.sessionDurationLabel,
    required this.createdAtLabel,
  });

  final QuoteModel quote;
  final String studentName;
  final String studentLevel;
  final String studentAvatar;
  final String serviceTitle;
  final String description;
  final String subject;
  final String teachingMode;
  final int sessionsCount;
  final String sessionDurationLabel;
  final String createdAtLabel;
}

class TeacherServiceDraft {
  const TeacherServiceDraft({
    required this.name,
    required this.description,
    required this.domain,
    required this.grade,
    required this.membersCount,
    required this.mode,
    required this.sessionsCount,
    required this.sessionDurationMinutes,
    required this.price,
    required this.imagePath,
  });

  final String name;
  final String description;
  final String domain;
  final String grade;
  final int membersCount;
  final String mode;
  final int sessionsCount;
  final int sessionDurationMinutes;
  final double price;
  final String imagePath;
}

class TeacherQuoteResponseDraft {
  const TeacherQuoteResponseDraft({
    required this.priceLabel,
    required this.sessionsCount,
  });

  final String priceLabel;
  final int sessionsCount;
}

class TeacherSessionDraft {
  const TeacherSessionDraft({
    required this.date,
    required this.startTime,
    required this.durationMinutes,
    required this.sessionType,
    this.meetingLink = '',
  });

  final DateTime date;
  final DateTime startTime;
  final int durationMinutes;
  final String sessionType;
  final String meetingLink;
}

class TeacherResourceDraft {
  const TeacherResourceDraft({
    required this.name,
    required this.type,
    this.filePath = '',
    this.link = '',
  });

  final String name;
  final TeacherResourceType type;
  final String filePath;
  final String link;
}


