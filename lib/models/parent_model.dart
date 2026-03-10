import 'user_model.dart';

class ParentModel extends UserModel {

  final List<String> childrenUids;


  ParentModel({
    required super.uid,
    required super.firstName,
    required super.lastName,
    required super.email,
    required super.phone,
    required super.location,
    required super.gender,
    required super.birthday,
    required super.accountStatus,

    required this.childrenUids,

  }) : super(role: UserRole.parent);

  @override
  Map<String, dynamic> toMap() {
    return {
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

      'children_uids': childrenUids,

    };
  }
  factory ParentModel.fromMap(Map<String, dynamic> map) {
    return ParentModel(

      uid: map['uid'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      gender: Gender.values.byName(map['gender'] ?? 'male'),
      birthday: (map['birthday'] as dynamic).toDate(),
      accountStatus: map['account_status'] ?? 'pending',


      childrenUids: List<String>.from(map['children_uids'] ?? []),
    );
  }
}