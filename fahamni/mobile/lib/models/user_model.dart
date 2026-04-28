import 'student_model.dart';
import 'tutor_model.dart';
import 'parent_model.dart';

enum UserRole { student, tutor, parent }
enum Gender { male, female }
enum AccountStatus { pending, validated, rejected }

abstract class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String location;
  final Gender gender;
  final DateTime birthday;
  final String picture;
  final UserRole role;
  AccountStatus accountStatus;
  bool isSuspended;
  DateTime? lastLoginDate;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.location,
    required this.gender,
    required this.birthday,
    required this.role,
    required this.picture,
    required this.accountStatus,
    this.isSuspended = false,
    this.lastLoginDate,
  });

  Map<String, dynamic> toMap();
  UserModel copyWithUid(String uid);

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final roleString = map['role'] ?? 'student';
    final role = UserRole.values.byName(roleString);

    switch (role) {
      case UserRole.student:
        return StudentModel.fromMap(map);
      case UserRole.tutor:
        return TutorModel.fromMap(map);
      case UserRole.parent:
        return ParentModel.fromMap(map);
    }
  }
}

