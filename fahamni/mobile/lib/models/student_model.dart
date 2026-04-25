import 'package:cloud_firestore/cloud_firestore.dart'; // ADDED
import 'user_model.dart';

class StudentModel extends UserModel {

  final String schoolLevel;
  final String learningObjectives;
  final List<String> preferredSubjects;
  final List<String> favoriteTeachers;
  final List<String> Courses;
  final String grade;
  final String speciality;

  StudentModel({
    required super.uid,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.phone,
    required super.location,
    required super.gender,
    required super.birthday,
    required super.picture,
    required super.accountStatus,
    super.isSuspended = false,
    required this.schoolLevel,
    required this.learningObjectives,
    required this.preferredSubjects,
    required this.favoriteTeachers,
    required this.Courses,
    required this.grade,
    required this.speciality,
    super.lastLoginDate,
  }) : super(role: UserRole.student);

  @override
  Map<String, dynamic> toMap() {
    return {
      'uid':          uid,
      'first_name':   firstName,
      'last_name':    lastName,
      'email':        email,
      'phone':        phone,
      'location':     location,
      'gender':       gender.name,
      'birthday':     Timestamp.fromDate(birthday), // FIXED
      'picture':      picture,
      'role':         role.name,
      'account_status': accountStatus.name,
      'is_suspended':   isSuspended,
      'school_level':        schoolLevel,
      'learning_objectives': learningObjectives,
      'preferred_subjects':  preferredSubjects,
      'favorite_teachers': favoriteTeachers,
      'courses': Courses,
      'grade': grade,
      'speciality': speciality,
      'last_login_date': lastLoginDate != null ? Timestamp.fromDate(lastLoginDate!) : null,
    };
  }

  @override
  StudentModel copyWithUid(String uid) => StudentModel(
    uid: uid,
    firstName: firstName, lastName: lastName,
    email: email, phone: phone,
    location: location, gender: gender,
    birthday: birthday, picture: picture,
    accountStatus: accountStatus,
    isSuspended: isSuspended,
    schoolLevel: schoolLevel,
    learningObjectives: learningObjectives,
    preferredSubjects: preferredSubjects,
    favoriteTeachers: favoriteTeachers,
    Courses: Courses,
    grade: grade,
    speciality: speciality,
    lastLoginDate: lastLoginDate,
  );

  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(
      uid:               map['uid']          ?? '',
      firstName:         map['first_name']   ?? '',
      lastName:          map['last_name']    ?? '',
      email:             map['email']        ?? '',
      phone:             map['phone']        ?? '',
      location:          map['location']     ?? '',
      gender:            Gender.values.byName(map['gender'] ?? 'male'),
      birthday:          (map['birthday'] as Timestamp).toDate(), 
      picture:           map['picture'],
      accountStatus:     AccountStatus.values.byName(map['account_status'] ?? 'pending'),
      isSuspended:       map['is_suspended'] ?? false,
      schoolLevel:       map['school_level']        ?? '',
      learningObjectives: map['learning_objectives'] ?? '',
      preferredSubjects: List<String>.from(map['preferred_subjects'] ?? []),
      favoriteTeachers: List<String>.from(map['favorite_teachers'] ?? []),
      Courses: List<String>.from(map['courses'] ?? []),
      grade: map['grade'] ?? '',
      speciality: map['speciality'] ?? '',
      lastLoginDate: map['last_login_date'] != null ? (map['last_login_date'] as Timestamp).toDate() : null,
    );
  }
}