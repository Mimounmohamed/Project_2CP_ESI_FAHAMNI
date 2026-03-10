import 'user_model.dart';

class StudentModel extends UserModel {

  final String schoolLevel;
  final String learningObjectives;
  final List<String> preferredSubjects;

  StudentModel({

    required super.uid,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.phone,
    required super.location,
    required super.gender,
    required super.birthday,
    required super.accountStatus,

    required this.schoolLevel,
    required this.learningObjectives,
    required this.preferredSubjects
  }) : super(role: UserRole.student);

  @override
  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {
      'uid': uid,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'location': location,
      'gender': gender.name,
      'birthday': birthday,
      'role': role.name,
      'account_status':accountStatus,

      'school_level': schoolLevel,
      'learning_objectives': learningObjectives,
      'preferred_subjects' : preferredSubjects,
    };
    return map;
  }
  factory StudentModel.fromMap(Map<String, dynamic> map) {
    return StudentModel(

      uid: map['uid'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      gender: Gender.values.byName(map['gender'] ?? 'male'),
      birthday: (map['birthday'] as dynamic).toDate(),
      schoolLevel: map['school_level'] ?? '',
      learningObjectives: map['learning_objectives'] ?? '',
      preferredSubjects: List<String>.from(map['preferred_subjects'] ?? []),
      accountStatus: map['account_status'] ?? 'pending',
    );
  }
}