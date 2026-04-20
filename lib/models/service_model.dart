class ServiceModel {
  final String serviceId;
  final String tutorId;
  final String name;
  final String area;
  final String level;
  final String subject;
  final String mode;
  final String description;
  final double price;
  final int duration;
  final int sessionsnum;
  final int maxStudents;
  final int enrollednum;
  final bool isActive;
  final String picture;
  final List<String> studentIds;
  final List<String> pendingIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceModel({
    required this.serviceId,
    required this.tutorId,
    required this.name,
    required this.area,
    required this.level,
    required this.subject,
    this.mode = '',
    required this.description,
    required this.price,
    required this.duration,
    required this.isActive,
    required this.maxStudents,
    required this.enrollednum,
    required this.sessionsnum,
    required this.picture,
    List<String>? studentIds,
    List<String>? pendingIds,
    this.createdAt,
    this.updatedAt,
  })  : studentIds = studentIds ?? const [],
        pendingIds = pendingIds ?? const [];

  int get maxnum => maxStudents;

  Map<String, dynamic> toMap() {
    return {
      'service_id': serviceId,
      'tutor_id': tutorId,
      'name': name,
      'area': area,
      'level': level,
      'subject': subject,
      'mode': mode,
      'description': description,
      'price': price,
      'duration': duration,
      'is_active': isActive,
      'sessions_num': sessionsnum,
      'enrolled_num': enrollednum,
      'maxstudents': maxStudents,
      'student_ids': studentIds,
      'pending_ids': pendingIds,
      'picture': picture,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) {
        return null;
      }
      if (value is DateTime) {
        return value;
      }
      return (value as dynamic).toDate();
    }

    return ServiceModel(
      serviceId: map['service_id'] ?? '',
      tutorId: map['tutor_id'] ?? '',
      name: map['name'] ?? '',
      area: map['area'] ?? '',
      level: map['level'] ?? '',
      subject: map['subject'] ?? '',
      mode: map['mode'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      duration: map['duration'] ?? 0,
      maxStudents: map['maxstudents'] ?? map['maxnum'] ?? 0,
      studentIds: List<String>.from(map['student_ids'] ?? []),
      pendingIds: List<String>.from(map['pending_ids'] ?? []),
      enrollednum: map['enrolled_num'] ?? 0,
      sessionsnum: map['sessions_num'] ?? 0,
      isActive: map['is_active'] ?? false,
      picture: map['picture'] ?? '',
      createdAt: parseDate(map['created_at']),
      updatedAt: parseDate(map['updated_at']),
    );
  }
}
