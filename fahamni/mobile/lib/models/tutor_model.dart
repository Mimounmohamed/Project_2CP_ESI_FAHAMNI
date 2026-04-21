import 'package:cloud_firestore/cloud_firestore.dart'; // ADDED
import 'user_model.dart';

class TutorModel extends UserModel {

  final String expertiseDomain;
  final List<String> levelsTaught;
  final String teachingMode;
  final bool isAvailable;
  final bool Certified;
  final String pedagogicalDescription;
  final double averageRating;
  final int yearsOfExperience;
  final String academicDescription;

  TutorModel({
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
    required this.expertiseDomain,
    required this.levelsTaught,
    required this.teachingMode,
    required this.isAvailable,
    required this.Certified,
    required this.pedagogicalDescription,
    required this.averageRating,
    required this.yearsOfExperience,
    required this.academicDescription,
  }) : super(role: UserRole.tutor);

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
      'birthday':     Timestamp.fromDate(birthday), 
      'picture':      picture,
      'role':         role.name,
      'account_status': accountStatus.name,
      'expertise_domain':        expertiseDomain,
      'levels_taught':           levelsTaught,
      'teaching_mode':           teachingMode,
      'is_available':            isAvailable,
      'certified':               Certified,
      'pedagogical_description': pedagogicalDescription,
      'average_rating':          averageRating,
      'years_of_experience':     yearsOfExperience,
      'academic_description':    academicDescription,
    };
  }

  @override
  TutorModel copyWithUid(String uid) => TutorModel(
    uid: uid,
    firstName: firstName, lastName: lastName,
    email: email, phone: phone,
    location: location, gender: gender,
    birthday: birthday, picture: picture,
    accountStatus: accountStatus,
    expertiseDomain: expertiseDomain,
    levelsTaught: levelsTaught,
    teachingMode: teachingMode,
    isAvailable: isAvailable,
    Certified: Certified,
    pedagogicalDescription: pedagogicalDescription,
    averageRating: averageRating,
    yearsOfExperience: yearsOfExperience,
    academicDescription: academicDescription,
  );

  factory TutorModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is String && value.trim().isNotEmpty) {
        return DateTime.tryParse(value.trim()) ?? DateTime(2000, 1, 1);
      }
      return DateTime(2000, 1, 1);
    }

    Gender parseGender(dynamic value) {
      final String normalized = (value ?? 'male').toString().trim().toLowerCase();
      for (final Gender gender in Gender.values) {
        if (gender.name == normalized) {
          return gender;
        }
      }
      return Gender.male;
    }

    AccountStatus parseAccountStatus(dynamic value) {
      final String normalized = (value ?? 'pending').toString().trim().toLowerCase();
      for (final AccountStatus status in AccountStatus.values) {
        if (status.name == normalized) {
          return status;
        }
      }
      return AccountStatus.pending;
    }

    double parseDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    int parseInt(dynamic value) {
      if (value is num) {
        return value.toInt();
      }
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return TutorModel(
      uid: map['uid'] ?? '',
      firstName: map['first_name'] ?? map['firstName'] ?? '',
      lastName: map['last_name'] ?? map['lastName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? map['city'] ?? '',
      gender: parseGender(map['gender']),
      birthday: parseDate(map['birthday']),
      picture: (map['picture'] ?? map['avatar'] ?? '').toString(),
      accountStatus: parseAccountStatus(map['account_status']),
      expertiseDomain:
          (map['expertise_domain'] ?? map['expertiseDomain'] ?? '').toString(),
      levelsTaught: List<String>.from(map['levels_taught'] ?? const <String>[]),
      teachingMode:
          (map['teaching_mode'] ?? map['teachingMode'] ?? '').toString(),
      isAvailable: map['is_available'] ?? false,
      Certified: map['certified'] ?? false,
      pedagogicalDescription:
          (map['pedagogical_description'] ?? '').toString(),
      averageRating: parseDouble(map['average_rating']),
      yearsOfExperience: parseInt(map['years_of_experience']),
      academicDescription: (map['academic_description'] ?? '').toString(),
    );
  }
}
