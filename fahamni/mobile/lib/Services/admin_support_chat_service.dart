import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fahamni/models/chat_model.dart';
import 'package:fahamni/models/user_model.dart';

class AdminSupportChatService {
  AdminSupportChatService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<ConversationModel> ensureSupportConversation() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please login to contact support.');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final role = UserModel.parseRole(userDoc.data()?['role']);
    final profileDoc = await _firestore
        .collection(_collectionForRole(role))
        .doc(user.uid)
        .get();
    final profile = profileDoc.data() ?? <String, dynamic>{};

    final String firstName = (profile['first_name'] ?? '').toString();
    final String lastName = (profile['last_name'] ?? '').toString();
    final String userName = [
      firstName,
      lastName,
    ].where((String part) => part.trim().isNotEmpty).join(' ').trim();
    final String docId = 'support_${user.uid}';
    final docRef = _firestore.collection('conversations').doc(docId);
    final now = Timestamp.now();
    final participants = <String>{
      user.uid,
      'admin',
      ...await _adminParticipantIds(),
    }.toList();

    await docRef.set({
      'conversationId': docId,
      'conversation_id': docId,
      'conversationName': 'App Support',
      'participants': participants,
      'isGroup': false,
      'is_support': true,
      'user_uid': user.uid,
      'user_name': userName.isNotEmpty ? userName : (user.email ?? 'User'),
      'user_role': _adminRoleName(role),
      'user_picture': (profile['picture'] ?? '').toString(),
      'unread_admin': 0,
      'is_closed': false,
      'createdAt': now,
      'last_message_at': now,
      'updatedAt': now,
    }, SetOptions(merge: true));

    return ConversationModel(
      conversationId: docId,
      conversationName: 'App Support',
      participants: participants,
      participantDisplayName: 'App Support',
      participantAvatarUrl:
          'https://ui-avatars.com/api/?name=App%20Support&background=000080&color=ffffff',
      participantSubtitle: 'En ligne',
      isOnline: true,
    );
  }

  String _collectionForRole(UserRole role) {
    switch (role) {
      case UserRole.student:
        return 'students';
      case UserRole.tutor:
        return 'tutors';
      case UserRole.parent:
        return 'parents';
    }
  }

  String _adminRoleName(UserRole role) {
    switch (role) {
      case UserRole.tutor:
        return 'teacher';
      case UserRole.parent:
        return 'parent';
      case UserRole.student:
        return 'student';
    }
  }

  Future<List<String>> _adminParticipantIds() async {
    final snapshot = await _firestore.collection('admins').get();
    return snapshot.docs
        .expand(
          (doc) => <String>[
            doc.id,
            (doc.data()['uid'] ?? '').toString(),
            (doc.data()['admin_id'] ?? '').toString(),
          ],
        )
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
  }
}
