import 'package:cloud_firestore/cloud_firestore.dart'; // ADDED
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
    required super.picture,
    required super.accountStatus,
    super.isSuspended = false,
    required this.childrenUids,
    super.lastLoginDate,
  }) : super(role: UserRole.parent);

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
      'children_uids':  childrenUids,
      'last_login_date': lastLoginDate != null ? Timestamp.fromDate(lastLoginDate!) : null,
    };
  }

  @override
  ParentModel copyWithUid(String uid) => ParentModel(
    uid: uid,
    firstName: firstName, lastName: lastName,
    email: email, phone: phone,
    location: location, gender: gender,
    birthday: birthday, picture: picture,
    accountStatus: accountStatus,
    isSuspended: isSuspended,
    childrenUids: childrenUids,
    lastLoginDate: lastLoginDate,
  );

  factory ParentModel.fromMap(Map<String, dynamic> map) {
    return ParentModel(
      uid:          map['uid']        ?? '',
      firstName:    map['first_name'] ?? '',
      lastName:     map['last_name']  ?? '',
      email:        map['email']      ?? '',
      phone:        map['phone']      ?? '',
      location:     map['location']   ?? '',
      gender:       Gender.values.byName(map['gender'] ?? 'male'),
      birthday:     (map['birthday'] as Timestamp).toDate(), // FIXED
      picture:      map['picture'],
      accountStatus: AccountStatus.values.byName(map['account_status'] ?? 'pending'),
      isSuspended:   map['is_suspended'] ?? false,
      childrenUids:  List<String>.from(map['children_uids'] ?? []),
      lastLoginDate: map['last_login_date'] != null ? (map['last_login_date'] as Timestamp).toDate() : null,
    );
  }
}