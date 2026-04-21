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
                (doc) async => _hydrateConversationFromData(
                  userId: userId,
                  docId: doc.id,
                  data: doc.data(),
                ),
              ),
            );

            final List<ConversationModel> filteredConversations = conversations
                .where((conversation) => _matchesFilter(conversation, filter))
                .toList();

            return _deduplicateConversations(filteredConversations);
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

  @override
  Future<ConversationModel> ensureDirectConversation({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _conversationsCollection
            .where('participants', arrayContains: currentUserId)
            .get();

    QueryDocumentSnapshot<Map<String, dynamic>>? bestMatch;
    DateTime? bestMatchTime;

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc in snapshot.docs) {
      final List<String> participants =
          (doc.data()['participants'] as List<dynamic>? ?? <dynamic>[])
              .map((participant) => participant.toString())
              .toList();
      final bool isGroup = doc.data()['isGroup'] == true ||
          doc.data()['is_group'] == true ||
          participants.length > 2;

      if (!isGroup &&
          participants.contains(otherUserId) &&
          participants.toSet().length == 2) {
        final ConversationModel hydrated = await _hydrateConversationFromData(
          userId: currentUserId,
          docId: doc.id,
          data: doc.data(),
        );
        final DateTime hydratedTime = _conversationTime(hydrated);

        if (bestMatch == null ||
            bestMatchTime == null ||
            hydratedTime.isAfter(bestMatchTime)) {
          bestMatch = doc;
          bestMatchTime = hydratedTime;
        }
      }
    }

    if (bestMatch != null) {
      return _hydrateConversationFromData(
        userId: currentUserId,
        docId: bestMatch.id,
        data: bestMatch.data(),
      );
    }

    final DocumentReference<Map<String, dynamic>> conversationRef =
        _conversationsCollection.doc();
    final DateTime now = DateTime.now();
    final List<String> participants = <String>{currentUserId, otherUserId}.toList()
      ..sort();

    await conversationRef.set({
      'conversationId': conversationRef.id,
      'conversation_id': conversationRef.id,
      'participants': participants,
      'conversationName': '',
      'isGroup': false,
      'createdAt': Timestamp.fromDate(now),
      'status': 'active',
    });

    final DocumentSnapshot<Map<String, dynamic>> createdSnapshot =
        await conversationRef.get();

    return _hydrateConversationFromData(
      userId: currentUserId,
      docId: conversationRef.id,
      data: createdSnapshot.data() ?? <String, dynamic>{},
    );
  }

  Future<ConversationModel> _hydrateConversationFromData({
    required String userId,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final ConversationModel baseConversation = ConversationModel.fromMap({
      ...data,
      'conversationId':
          data['conversationId'] ?? data['conversation_id'] ?? docId,
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
    final _ParticipantPresentation participantPresentation = isGroup
        ? await _getGroupPresentation(
            currentUserId: userId,
            conversation: baseConversation,
          )
        : otherParticipantId.isEmpty
            ? _ParticipantPresentation.empty()
            : await _getParticipantPresentation(
                userId: otherParticipantId,
                role: otherParticipantRole,
              );

    final String resolvedConversationName =
        baseConversation.conversationName.trim().isNotEmpty
            ? baseConversation.conversationName.trim()
            : participantPresentation.displayName;

    return baseConversation.copyWith(
      conversationName: resolvedConversationName,
      isGroup: isGroup,
      otherParticipantRole: otherParticipantRole,
      participantDisplayName: participantPresentation.displayName,
      participantAvatarUrl: participantPresentation.avatarUrl,
      participantSubtitle: participantPresentation.subtitle,
      isVerified: participantPresentation.isVerified,
      isOnline: participantPresentation.isOnline,
    );
  }

  Future<_ParticipantPresentation> _getGroupPresentation({
    required String currentUserId,
    required ConversationModel conversation,
  }) async {
    final List<String> otherParticipantIds = conversation.participants
        .where((participantId) => participantId != currentUserId)
        .toList();

    if (otherParticipantIds.isEmpty) {
      return _ParticipantPresentation(
        displayName: conversation.conversationName.trim().isNotEmpty
            ? conversation.conversationName.trim()
            : 'Group Conversation',
        avatarUrl: '',
        subtitle: '',
      );
    }

    final List<_ParticipantPresentation> members = (await Future.wait(
      otherParticipantIds.map((participantId) async {
        final UserRole? role = await _getUserRole(participantId);
        return _getParticipantPresentation(
          userId: participantId,
          role: role,
        );
      }),
    ))
        .where((member) => member.displayName.trim().isNotEmpty)
        .toList();

    final List<String> memberNames = members
        .map((member) => member.displayName.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    final String subtitle = _formatGroupMembers(memberNames);
    final String displayName = conversation.conversationName.trim().isNotEmpty
        ? conversation.conversationName.trim()
        : subtitle.isNotEmpty
            ? subtitle
            : 'Group Conversation';

    return _ParticipantPresentation(
      displayName: displayName,
      avatarUrl: '',
      subtitle: subtitle,
    );
  }

  String _formatGroupMembers(List<String> memberNames) {
    if (memberNames.isEmpty) {
      return '';
    }

    if (memberNames.length <= 3) {
      return memberNames.join(', ');
    }

    final List<String> visibleNames = memberNames.take(3).toList();
    return '${visibleNames.join(', ')} +${memberNames.length - 3} more';
  }

  List<ConversationModel> _deduplicateConversations(
    List<ConversationModel> conversations,
  ) {
    final Map<String, ConversationModel> deduplicated =
        <String, ConversationModel>{};

    for (final ConversationModel conversation in conversations) {
      final String key = conversation.isGroup
          ? conversation.conversationId
          : (List<String>.from(conversation.participants)..sort()).join('::');

      final ConversationModel? existing = deduplicated[key];
      if (existing == null || _conversationTime(conversation).isAfter(_conversationTime(existing))) {
        deduplicated[key] = conversation;
      }
    }

    return deduplicated.values.toList();
  }

  DateTime _conversationTime(ConversationModel conversation) {
    return conversation.lastMessage?.sendingDateTime ??
        conversation.createdAt;
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
