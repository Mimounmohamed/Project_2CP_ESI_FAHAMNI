enum Gender { male, female }
class ChildModel {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime birthday;
  final String schoolLevel;
  final String picture;
  final Gender gender;
  
  
  ChildModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthday,
    required this.schoolLevel,
    required this.picture,
    required this.gender,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'birthday': birthday,
      'school_level': schoolLevel,
      'picture':      picture,
      'gender':       gender.name,
      
    };
  }

  factory ChildModel.fromMap(Map<String, dynamic> map) {
    return ChildModel(
      id: map['id'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      birthday: (map['birthday'] as dynamic).toDate(),
      schoolLevel: map['school_level'] ?? '',
      picture: map['picture'] ?? '',
      gender:            Gender.values.byName(map['gender'] ?? 'male'),
    );
  }
}