import 'package:cloud_firestore/cloud_firestore.dart';

class ChildModel {
  final String id;
  final String name;
  final String gender;
  final String level;
  final String grade;
  final String speciality;
  final List<String> subjects;
  final String picture;
  final String parentUid;

  ChildModel({
    required this.id,
    required this.name,
    required this.gender,
    required this.level,
    required this.grade,
    required this.speciality,
    required this.subjects,
    required this.picture,
    required this.parentUid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id':         id,
      'name':       name,
      'gender':     gender,
      'level':      level,
      'grade':      grade,
      'speciality': speciality,
      'subjects':   subjects,
      'picture':    picture,
      'parentUid':  parentUid,
    };
  }

  factory ChildModel.fromMap(Map<String, dynamic> map) {
    return ChildModel(
      id:         map['id']         ?? '',
      name:       map['name']       ?? '',
      gender:     map['gender']     ?? 'male',
      level:      map['level']      ?? '',
      grade:      map['grade']      ?? '',
      speciality: map['speciality'] ?? '',
      subjects:   List<String>.from(map['subjects'] ?? []),
      picture:    map['picture']    ?? '',
      parentUid:  map['parentUid']  ?? '',
    );
  }

  // Convenience getters used by the dashboard UI
  String get displayName => name;

  String get subtitle {
    if (level.isNotEmpty && speciality.isNotEmpty) return '$level - $speciality';
    if (level.isNotEmpty) return level;
    if (speciality.isNotEmpty) return speciality;
    if (grade.isNotEmpty) return grade;
    return 'Child profile';
  }

  bool get isFemale => gender == 'female';
}