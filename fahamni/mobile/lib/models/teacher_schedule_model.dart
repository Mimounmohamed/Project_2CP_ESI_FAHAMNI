class TeacherScheduleModel {
  const TeacherScheduleModel({
    required this.title,
    required this.teacherName,
    required this.days,
  });

  final String title;
  final String teacherName;
  final List<TeacherScheduleDay> days;
}

class TeacherScheduleDay {
  const TeacherScheduleDay({
    required this.date,
    required this.label,
    required this.shortLabel,
    required this.sessions,
  });

  final DateTime date;
  final String label;
  final String shortLabel;
  final List<TeacherScheduleSession> sessions;
}

class TeacherScheduleSession {
  const TeacherScheduleSession({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.title,
    required this.subject,
    required this.startTimeLabel,
    required this.endTimeLabel,
    required this.durationLabel,
    required this.modalityLabel,
    required this.statusLabel,
    required this.studentSummary,
  });

  final String id;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String title;
  final String subject;
  final String startTimeLabel;
  final String endTimeLabel;
  final String durationLabel;
  final String modalityLabel;
  final String statusLabel;
  final String studentSummary;
}
