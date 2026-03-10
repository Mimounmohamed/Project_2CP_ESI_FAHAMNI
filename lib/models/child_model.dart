class ChildModel {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime birthday;
  final String schoolLevel;


  ChildModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.birthday,
    required this.schoolLevel,

  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'birthday': birthday,
      'school_level': schoolLevel,

    };
  }

  factory ChildModel.fromMap(Map<String, dynamic> map) {
    return ChildModel(
      id: map['id'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      birthday: (map['birthday'] as dynamic).toDate(),
      schoolLevel: map['school_level'] ?? '',

    );
  }
}