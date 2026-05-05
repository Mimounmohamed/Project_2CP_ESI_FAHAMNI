import 'student_model.dart';

enum StudyLevel {
  primary,
  secondary,
  university,
}

class StudentProfile {
  const StudentProfile({
    required this.studentId,
    required this.firstName,
    required this.studyLevel,
    required this.learningObjectives,
    required this.schoolLevelLabel,
  });

  final String studentId;
  final String firstName;
  final StudyLevel studyLevel;
  final String learningObjectives;
  final String schoolLevelLabel;

  factory StudentProfile.fromStudentModel(StudentModel student) {
    return StudentProfile(
      studentId: student.uid,
      firstName: student.firstName,
      studyLevel: _mapStudyLevel(student.schoolLevel),
      learningObjectives: student.learningObjectives,
      schoolLevelLabel: student.schoolLevel,
    );
  }

  static StudyLevel _mapStudyLevel(String schoolLevel) {
    final String normalized = schoolLevel.trim().toLowerCase();
    if (normalized.contains('primary')) {
      return StudyLevel.primary;
    }
    if (normalized.contains('university')) {
      return StudyLevel.university;
    }
    return StudyLevel.secondary;
  }
}


