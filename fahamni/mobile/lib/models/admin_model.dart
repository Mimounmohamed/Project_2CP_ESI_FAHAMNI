class AdminModel {
  final String adminId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String location;
  final String gender;

  AdminModel({
    required this.adminId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.location,
    required this.gender,
  });

  // Conversion to send data to Firestore
  Map<String, dynamic> toMap() {
    return {
      'admin_id': adminId,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'location': location,
      'gender': gender,
    };
  }

  // Create an instance from a document in Firestore
  factory AdminModel.fromMap(Map<String, dynamic> map) {
    return AdminModel(
      adminId: map['admin_id'] ?? '',
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      location: map['location'] ?? '',
      gender: map['gender'] ?? '',
    );
  }
}

