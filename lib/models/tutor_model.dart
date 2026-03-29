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
    return TutorModel(
      uid:          map['uid']        ?? '',
      firstName:    map['first_name'] ?? '',
      lastName:     map['last_name']  ?? '',
      email:        map['email']      ?? '',
      phone:        map['phone']      ?? '',
      location:     map['location']   ?? '',
      gender:       Gender.values.byName(map['gender'] ?? 'male'),
      birthday:     (map['birthday'] as Timestamp).toDate(), 
      picture:      map['picture'],
      accountStatus: AccountStatus.values.byName(map['account_status'] ?? 'pending'),
      expertiseDomain:        map['expertise_domain']        ?? '',
      levelsTaught:           List<String>.from(map['levels_taught'] ?? []),
      teachingMode:           map['teaching_mode']           ?? '',
      isAvailable:            map['is_available']            ?? false,
      Certified:              map['certified']               ?? false,
      pedagogicalDescription: map['pedagogical_description'] ?? '',
      averageRating:          (map['average_rating']         ?? 0.0).toDouble(),
      yearsOfExperience:      map['years_of_experience']     ?? 0,
      academicDescription:    map['academic_description']    ?? '',
    );
  }
}