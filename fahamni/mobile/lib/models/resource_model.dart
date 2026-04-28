enum ResourceType { pdf, docx, image, link }

abstract class ResourceModel {
  final String resourceId;
  final String tutorId;
  final String sessionId;
  final String title;
  final String subject;
  final String level;
  final String description;
  final String contentType;
  final String accessLevel;
  final List<String> allowedUsers;
  final bool isPublic;
  final DateTime addedAt;



  ResourceModel({
    required this.resourceId,
    required this.tutorId,
    required this.sessionId,
    required this.title,
    required this.subject,
    required this.level,
    required this.description,
    required this.contentType,
    required this.accessLevel,
    required this.allowedUsers,
    required this.isPublic,
    required this.addedAt,
  });

  Map<String, dynamic> toMap();


  factory ResourceModel.fromMap(Map<String, dynamic> map) {
    final type = map['content_type'] ?? 'document';
    if (type == 'media') {
      return MediaResource.fromMap(map);
    } else if (type == 'link') {
      return LinkResource.fromMap(map);
    } else {
      return DocumentResource.fromMap(map);
    }
  }
}

class DocumentResource extends ResourceModel {
  final String fileUrl;
  final String docType;

  DocumentResource({
    required super.resourceId,
    required super.tutorId,
    required super.sessionId,
    required super.title,
    required super.subject,
    required super.level,
    required super.description,
    required super.accessLevel,
    required super.allowedUsers,
    required super.isPublic,
    required super.addedAt,
    required this.fileUrl,
    required this.docType,
  }) : super(contentType: 'document');

  @override
  Map<String, dynamic> toMap() {
    return {
      'resource_id': resourceId,
      'tutor_id': tutorId,
      'session_id': sessionId,
      'title': title,
      'subject': subject,
      'level': level,
      'description': description,
      'content_type': 'document',
      'access_level': accessLevel,
      'allowed_users': allowedUsers,
      'is_public': isPublic,
      'added_at': addedAt,
      'file_url': fileUrl,
      'doc_type': docType,
    };
  }

  factory DocumentResource.fromMap(Map<String, dynamic> map) {
    return DocumentResource(
      resourceId: map['resource_id'] ?? '',
      tutorId: map['tutor_id'] ?? '',
      sessionId: map['session_id'] ?? '',
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      level: map['level'] ?? '',
      description: map['description'] ?? '',
      accessLevel: map['access_level'] ?? '',
      allowedUsers: List<String>.from(map['allowed_users'] ?? []),
      isPublic: map['is_public'] ?? false,
      addedAt: (map['added_at'] as dynamic).toDate(),
      fileUrl: map['file_url'] ?? '',
      docType: map['doc_type'] ?? 'pdf',
    );
  }
}

class MediaResource extends ResourceModel {
  final String mediaUrl;
  final String platform;

  MediaResource({
    required super.resourceId,
    required super.tutorId,
    required super.sessionId,
    required super.title,
    required super.subject,
    required super.level,
    required super.description,
    required super.accessLevel,
    required super.allowedUsers,
    required super.isPublic,
    required super.addedAt,
    required this.mediaUrl,
    required this.platform,
  }) : super(contentType: 'media');

  @override
  Map<String, dynamic> toMap() {
    return {
      'resource_id': resourceId,
      'tutor_id': tutorId,
      'session_id': sessionId,
      'title': title,
      'subject': subject,
      'level': level,
      'description': description,
      'content_type': 'media',
      'access_level': accessLevel,
      'allowed_users': allowedUsers,
      'is_public': isPublic,
      'added_at': addedAt,
      'media_url': mediaUrl,
      'platform': platform,
    };
  }

  factory MediaResource.fromMap(Map<String, dynamic> map) {
    return MediaResource(
      resourceId: map['resource_id'] ?? '',
      tutorId: map['tutor_id'] ?? '',
      sessionId: map['session_id'] ?? '',
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      level: map['level'] ?? '',
      description: map['description'] ?? '',
      accessLevel: map['access_level'] ?? '',
      allowedUsers: List<String>.from(map['allowed_users'] ?? []),
      isPublic: map['is_public'] ?? false,
      addedAt: (map['added_at'] as dynamic).toDate(),
      mediaUrl: map['media_url'] ?? '',
      platform: map['platform'] ?? '',
    );
  }
}

class LinkResource extends ResourceModel {
  final String linkUrl;

  LinkResource({
    required super.resourceId,
    required super.tutorId,
    required super.sessionId,
    required super.title,
    required super.subject,
    required super.level,
    required super.description,
    required super.accessLevel,
    required super.allowedUsers,
    required super.isPublic,
    required super.addedAt,
    required this.linkUrl,
  }) : super(contentType: 'link');

  @override
  Map<String, dynamic> toMap() {
    return {
      'resource_id': resourceId,
      'tutor_id': tutorId,
      'session_id': sessionId,
      'title': title,
      'subject': subject,
      'level': level,
      'description': description,
      'content_type': 'link',
      'access_level': accessLevel,
      'allowed_users': allowedUsers,
      'is_public': isPublic,
      'added_at': addedAt,
      'link_url': linkUrl,
    };
  }

  factory LinkResource.fromMap(Map<String, dynamic> map) {
    return LinkResource(
      resourceId: map['resource_id'] ?? '',
      tutorId: map['tutor_id'] ?? '',
      sessionId: map['session_id'] ?? '',
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      level: map['level'] ?? '',
      description: map['description'] ?? '',
      accessLevel: map['access_level'] ?? '',
      allowedUsers: List<String>.from(map['allowed_users'] ?? []),
      isPublic: map['is_public'] ?? false,
      addedAt: (map['added_at'] as dynamic).toDate(),
      linkUrl: map['link_url'] ?? '',
    );
  }
}


