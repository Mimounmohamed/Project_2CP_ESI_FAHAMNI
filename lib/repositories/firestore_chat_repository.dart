import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat_model.dart';
import '../models/parent_model.dart';
import '../models/student_model.dart';
import '../models/tutor_model.dart';
import '../models/user_model.dart';
import 'chat_repository.dart';

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Map<String, UserRole?> _userRoleCache = <String, UserRole?>{};

  CollectionReference<Map<String, dynamic>> get _conversationsCollection =>
      _firestore.collection('conversations');

  @override
  Stream<List<ConversationModel>> getConversations(
    String userId, {
    Object? filter,
  }) {
    return _conversationsCollection
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap(
          (snapshot) async {
            final List<ConversationModel> conversations = await Future.wait(
              snapshot.docs.map(
                (doc) async => _hydrateConversation(
                  userId: userId,
                  doc: doc,
                ),
              ),
            );

            return conversations
                .where((conversation) => _matchesFilter(conversation, filter))
                .toList();
          },
        );
  }

  @override
  Stream<List<MessageModel>> getMessages(String conversationId) {
    return _conversationsCollection
        .doc(conversationId)
        .collection('messages')
        .orderBy('sendingDateTime')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => MessageModel.fromMap({
                  ...doc.data(),
                  'messageId': doc.data()['messageId'] ?? doc.id,
                  'conversationId': conversationId,
                }),
              )
              .toList(),
        );
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    final DocumentReference<Map<String, dynamic>> conversationRef =
        _conversationsCollection.doc(message.conversationId);
    final DocumentSnapshot<Map<String, dynamic>> conversationSnapshot =
        await conversationRef.get();
    final Map<String, dynamic> existingConversation =
        conversationSnapshot.data() ?? <String, dynamic>{};

    final CollectionReference<Map<String, dynamic>> messagesRef =
        conversationRef.collection('messages');

    final String messageId =
        message.messageId.isNotEmpty ? message.messageId : messagesRef.doc().id;

    final MessageModel messageToSave = message.copyWith(messageId: messageId);

    final WriteBatch batch = _firestore.batch();

    batch.set(
      messagesRef.doc(messageId),
      messageToSave.toMap(),
    );

    batch.set(
      conversationRef,
      {
        'conversationId': messageToSave.conversationId,
        'conversation_id':
            existingConversation['conversation_id'] ?? messageToSave.conversationId,
        'conversationName':
            existingConversation['conversationName'] ??
            existingConversation['conversation_name'] ??
            '',
        'participants': (existingConversation['participants'] as List<dynamic>?)
                ?.map((participant) => participant.toString())
                .toList() ??
            <String>{
              messageToSave.senderId,
              messageToSave.receiverId,
            }.toList(),
        'isGroup':
            existingConversation['isGroup'] ?? existingConversation['is_group'] ?? false,
        'createdAt': existingConversation['createdAt'] ??
            Timestamp.fromDate(messageToSave.sendingDateTime),
        'status': existingConversation['status'] ?? 'active',
        'lastMessage': messageToSave.toMap(),
        'lastMessageTime': messageToSave.sendingDateTime,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<ConversationModel> _hydrateConversation({
    required String userId,
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
  }) async {
    final Map<String, dynamic> data = doc.data();
    final ConversationModel baseConversation = ConversationModel.fromMap({
      ...data,
      'conversationId':
          data['conversationId'] ?? data['conversation_id'] ?? doc.id,
    });

    final bool isGroup =
        baseConversation.isGroup || baseConversation.participants.length > 2;
    final String otherParticipantId = isGroup
        ? ''
        : baseConversation.participants.firstWhere(
            (participantId) => participantId != userId,
            orElse: () => '',
          );
    final UserRole? otherParticipantRole =
        isGroup ? null : await _getUserRole(otherParticipantId);
    final _ParticipantPresentation participantPresentation =
        isGroup || otherParticipantId.isEmpty
        ? _ParticipantPresentation.empty()
        : await _getParticipantPresentation(
            userId: otherParticipantId,
            role: otherParticipantRole,
          );

    return baseConversation.copyWith(
      isGroup: isGroup,
      otherParticipantRole: otherParticipantRole,
      participantDisplayName: participantPresentation.displayName,
      participantAvatarUrl: participantPresentation.avatarUrl,
      participantSubtitle: participantPresentation.subtitle,
      isVerified: participantPresentation.isVerified,
      isOnline: participantPresentation.isOnline,
    );
  }

  Future<UserRole?> _getUserRole(String userId) async {
    if (userId.isEmpty) return null;
    if (_userRoleCache.containsKey(userId)) {
      return _userRoleCache[userId];
    }

    final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await _firestore.collection('users').doc(userId).get();
    final String? roleName = userSnapshot.data()?['role'] as String?;
    UserRole? role;
    if (roleName != null) {
      for (final UserRole candidate in UserRole.values) {
        if (candidate.name == roleName) {
          role = candidate;
          break;
        }
      }
    }

    if (role == null) {
      final List<MapEntry<String, UserRole>> collectionChecks =
          <MapEntry<String, UserRole>>[
        const MapEntry<String, UserRole>('tutors', UserRole.tutor),
        const MapEntry<String, UserRole>('students', UserRole.student),
        const MapEntry<String, UserRole>('parents', UserRole.parent),
      ];

      for (final MapEntry<String, UserRole> check in collectionChecks) {
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await _firestore.collection(check.key).doc(userId).get();
        if (snapshot.exists) {
          role = check.value;
          break;
        }
      }
    }

    _userRoleCache[userId] = role;
    return role;
  }

  Future<_ParticipantPresentation> _getParticipantPresentation({
    required String userId,
    required UserRole? role,
  }) async {
    if (userId.isEmpty || role == null) {
      return _ParticipantPresentation.empty();
    }

    switch (role) {
      case UserRole.tutor:
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await _firestore.collection('tutors').doc(userId).get();
        if (!snapshot.exists || snapshot.data() == null) {
          return _ParticipantPresentation.empty();
        }
        final TutorModel tutor = TutorModel.fromMap(snapshot.data()!);
        final String fullName =
            '${tutor.firstName} ${tutor.lastName.isNotEmpty ? '${tutor.lastName[0]}.' : ''}'
                .trim();
        final String subtitle = [
          if (tutor.levelsTaught.isNotEmpty) tutor.levelsTaught.first,
          if (tutor.expertiseDomain.isNotEmpty) tutor.expertiseDomain,
        ].join(' • ');
        return _ParticipantPresentation(
          displayName: fullName.isNotEmpty ? fullName : 'Tutor',
          avatarUrl: tutor.picture,
          subtitle: subtitle,
          isVerified: tutor.Certified,
          isOnline: tutor.isAvailable,
        );
      case UserRole.student:
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await _firestore.collection('students').doc(userId).get();
        if (!snapshot.exists || snapshot.data() == null) {
          return _ParticipantPresentation.empty();
        }
        final StudentModel student = StudentModel.fromMap(snapshot.data()!);
        final String fullName =
            '${student.firstName} ${student.lastName.isNotEmpty ? '${student.lastName[0]}.' : ''}'
                .trim();
        final String subtitle = [
          if (student.schoolLevel.isNotEmpty) student.schoolLevel,
          if (student.preferredSubjects.isNotEmpty) student.preferredSubjects.first,
        ].join(' • ');
        return _ParticipantPresentation(
          displayName: fullName.isNotEmpty ? fullName : 'Student',
          avatarUrl: student.picture,
          subtitle: subtitle,
          isOnline: false,
        );
      case UserRole.parent:
        final DocumentSnapshot<Map<String, dynamic>> snapshot =
            await _firestore.collection('parents').doc(userId).get();
        if (!snapshot.exists || snapshot.data() == null) {
          return _ParticipantPresentation.empty();
        }
        final ParentModel parent = ParentModel.fromMap(snapshot.data()!);
        final String fullName =
            '${parent.firstName} ${parent.lastName.isNotEmpty ? '${parent.lastName[0]}.' : ''}'
                .trim();
        return _ParticipantPresentation(
          displayName: fullName.isNotEmpty ? fullName : 'Parent',
          avatarUrl: parent.picture,
          subtitle: parent.location,
        );
    }
  }

  bool _matchesFilter(ConversationModel conversation, Object? filter) {
    if (filter == null) return true;

    if (filter is ChatConversationFilter) {
      if (filter == ChatConversationFilter.all) return true;
      if (filter == ChatConversationFilter.group) return conversation.isGroup;
    }

    if (filter is UserRole) {
      return !conversation.isGroup && conversation.otherParticipantRole == filter;
    }

    return true;
  }
}

class _ParticipantPresentation {
  const _ParticipantPresentation({
    required this.displayName,
    required this.avatarUrl,
    required this.subtitle,
    this.isVerified = false,
    this.isOnline = false,
  });

  factory _ParticipantPresentation.empty() => const _ParticipantPresentation(
    displayName: '',
    avatarUrl: '',
    subtitle: '',
  );

  final String displayName;
  final String avatarUrl;
  final String subtitle;
  final bool isVerified;
  final bool isOnline;
}
