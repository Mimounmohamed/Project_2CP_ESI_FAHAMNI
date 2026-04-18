import 'service_model.dart';
import 'tutor_model.dart';

class TeacherDashboardModel {
  const TeacherDashboardModel({
    required this.tutorProfile,
    required this.serviceRecords,
    required this.teacherName,
    required this.teacherRoleLabel,
    required this.profileImage,
    required this.performanceTitle,
    required this.todaySessionsTitle,
    required this.myServicesTitle,
    required this.quoteRequestsTitle,
    required this.seeAllLabel,
    required this.emptySessionsLabel,
    required this.emptyServicesLabel,
    required this.emptyQuotesLabel,
    required this.stats,
    required this.nextSession,
    required this.services,
    required this.quoteRequests,
  });

  final TutorModel tutorProfile;
  final List<ServiceModel> serviceRecords;
  final String teacherName;
  final String teacherRoleLabel;
  final String profileImage;
  final String performanceTitle;
  final String todaySessionsTitle;
  final String myServicesTitle;
  final String quoteRequestsTitle;
  final String seeAllLabel;
  final String emptySessionsLabel;
  final String emptyServicesLabel;
  final String emptyQuotesLabel;
  final List<TeacherDashboardStat> stats;
  final TeacherDashboardSession? nextSession;
  final List<TeacherDashboardServiceCard> services;
  final List<TeacherDashboardQuoteRequest> quoteRequests;
}

class TeacherDashboardStat {
  const TeacherDashboardStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class TeacherDashboardSession {
  const TeacherDashboardSession({
    required this.badgeLabel,
    required this.title,
    required this.subject,
    required this.timeRange,
    required this.modalityLabel,
  });

  final String badgeLabel;
  final String title;
  final String subject;
  final String timeRange;
  final String modalityLabel;
}

class TeacherDashboardServiceCard {
  const TeacherDashboardServiceCard({
    required this.id,
    required this.category,
    required this.statusLabel,
    required this.title,
    required this.sessionsLabel,
    required this.priceLabel,
    required this.imagePath,
  });

  final String id;
  final String category;
  final String statusLabel;
  final String title;
  final String sessionsLabel;
  final String priceLabel;
  final String imagePath;
}

class TeacherDashboardQuoteRequest {
  const TeacherDashboardQuoteRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentLevel,
    required this.subtitle,
    required this.subject,
    required this.objective,
    required this.frequency,
    required this.duration,
    required this.budget,
    required this.createdAtLabel,
    required this.status,
    required this.avatarPath,
    required this.actionLabel,
  });

  final String id;
  final String studentId;
  final String studentName;
  final String studentLevel;
  final String subtitle;
  final String subject;
  final String objective;
  final String frequency;
  final String duration;
  final String budget;
  final String createdAtLabel;
  final String status;
  final String avatarPath;
  final String actionLabel;
}
