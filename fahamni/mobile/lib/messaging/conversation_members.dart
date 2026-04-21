import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConversationMembers extends StatelessWidget {
  final List<String> participants;

  const ConversationMembers({super.key, required this.participants});

  Future<List<_ConversationMember>> _loadMembers() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Future.wait(
      participants.map((participantId) async {
        if (participantId.trim().isEmpty) {
          return _ConversationMember.unknown(participantId);
        }

        const List<String> collections = <String>[
          'users',
          'students',
          'tutors',
          'parents',
        ];

        for (final String collection in collections) {
          final DocumentSnapshot<Map<String, dynamic>> snapshot =
              await firestore.collection(collection).doc(participantId).get();
          final Map<String, dynamic>? data = snapshot.data();
          if (!snapshot.exists || data == null) {
            continue;
          }

          final String firstName =
              (data['first_name'] ?? data['firstName'] ?? '').toString().trim();
          final String lastName = (data['last_name'] ?? data['lastName'] ?? '')
              .toString()
              .trim();
          final String displayName = '$firstName $lastName'.trim();
          final String picture = (data['picture'] ?? data['avatar'] ?? '')
              .toString()
              .trim();
          final String role = (data['role'] ?? collection).toString().trim();
          final bool hasReadableName = displayName.isNotEmpty;
          final bool isFallbackUsersDoc =
              collection == 'users' &&
              !hasReadableName &&
              (role.isNotEmpty || picture.isNotEmpty);

          if (isFallbackUsersDoc) {
            continue;
          }

          return _ConversationMember(
            id: participantId,
            displayName: hasReadableName ? displayName : participantId,
            roleLabel: _toRoleLabel(role),
            photoUrl: picture,
          );
        }

        return _ConversationMember.unknown(participantId);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ConversationMember>>(
      future: _loadMembers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<_ConversationMember> members =
            snapshot.data ?? <_ConversationMember>[];

        return ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final _ConversationMember member = members[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22.0,
                    backgroundColor: const Color(0xFFE5E7EB),
                    backgroundImage: member.photoUrl.isNotEmpty
                        ? NetworkImage(member.photoUrl)
                        : null,
                    child: member.photoUrl.isEmpty
                        ? const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF64748B),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.displayName,
                          style: GoogleFonts.inter(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          member.roleLabel,
                          style: GoogleFonts.inter(
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF000080),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF000080),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ConversationMember {
  const _ConversationMember({
    required this.id,
    required this.displayName,
    required this.roleLabel,
    required this.photoUrl,
  });

  factory _ConversationMember.unknown(String id) => _ConversationMember(
    id: id,
    displayName: id,
    roleLabel: 'Member',
    photoUrl: '',
  );

  final String id;
  final String displayName;
  final String roleLabel;
  final String photoUrl;
}

String _toRoleLabel(String role) {
  final String normalized = role.trim().toLowerCase();
  switch (normalized) {
    case 'student':
    case 'students':
      return 'Student';
    case 'tutor':
    case 'tutors':
      return 'Tutor';
    case 'parent':
    case 'parents':
      return 'Parent';
    case 'user':
    case 'users':
      return 'Member';
    default:
      if (normalized.isEmpty) {
        return 'Member';
      }
      return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }
}
