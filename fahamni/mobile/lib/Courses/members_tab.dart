import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../models/student_model.dart';
import '../Services/chat_service.dart';
import '../repositories/firestore_chat_repository.dart';
import '../Teacher_Service_Details/service_details_service.dart';
import '../messaging/conversation_page.dart';

class _ChatRecipient {
  final String userId;
  final String displayName;
  final String imageUrl;

  const _ChatRecipient({
    required this.userId,
    required this.displayName,
    required this.imageUrl,
  });
}

Future<_ChatRecipient> _resolveChatRecipient(StudentModel student) async {
  try {
    final childDoc = await FirebaseFirestore.instance.collection('children').doc(student.uid).get();
    if (!childDoc.exists || childDoc.data() == null) {
      return _ChatRecipient(
        userId: student.uid,
        displayName: '${student.firstName} ${student.lastName}'.trim().isEmpty
            ? 'Student'
            : '${student.firstName} ${student.lastName}'.trim(),
        imageUrl: student.picture.isNotEmpty
            ? student.picture
            : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent('${student.firstName} ${student.lastName}'.trim())}&background=000080&color=ffffff',
      );
    }

    final parentUid = (childDoc.data()?['parentUid'] ?? '').toString();
    if (parentUid.isEmpty) {
      return _ChatRecipient(
        userId: student.uid,
        displayName: '${student.firstName} ${student.lastName}'.trim().isEmpty
            ? 'Student'
            : '${student.firstName} ${student.lastName}'.trim(),
        imageUrl: student.picture.isNotEmpty
            ? student.picture
            : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent('${student.firstName} ${student.lastName}'.trim())}&background=000080&color=ffffff',
      );
    }

    final parentDoc = await FirebaseFirestore.instance.collection('parents').doc(parentUid).get();
    if (!parentDoc.exists || parentDoc.data() == null) {
      return _ChatRecipient(
        userId: student.uid,
        displayName: '${student.firstName} ${student.lastName}'.trim().isEmpty
            ? 'Student'
            : '${student.firstName} ${student.lastName}'.trim(),
        imageUrl: student.picture.isNotEmpty
            ? student.picture
            : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent('${student.firstName} ${student.lastName}'.trim())}&background=000080&color=ffffff',
      );
    }

    final parentData = parentDoc.data()!;
    final parentName = '${parentData['first_name'] ?? ''} ${parentData['last_name'] ?? ''}'.trim();
    final parentPicture = (parentData['picture'] ?? '').toString();

    return _ChatRecipient(
      userId: parentUid,
      displayName: parentName.isNotEmpty ? parentName : 'Parent',
      imageUrl: parentPicture.isNotEmpty
          ? parentPicture
          : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(parentName.isNotEmpty ? parentName : 'Parent')}&background=000080&color=ffffff',
    );
  } catch (_) {
    return _ChatRecipient(
      userId: student.uid,
      displayName: '${student.firstName} ${student.lastName}'.trim().isEmpty
          ? 'Student'
          : '${student.firstName} ${student.lastName}'.trim(),
      imageUrl: student.picture.isNotEmpty
          ? student.picture
          : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent('${student.firstName} ${student.lastName}'.trim())}&background=000080&color=ffffff',
    );
  }
}

class MemberTab extends StatefulWidget {
  final ServiceModel service;

  const MemberTab({super.key, required this.service});

  @override
  State<MemberTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MemberTab> {
  final _service = CourseDetailsService();
  List<StudentModel> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getMembers(widget.service.serviceId);
    setState(() {
      _members = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_members.isEmpty) {
      return const Center(
        child: Text('No members yet',
            style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF94A3B8))),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _members.length,
      itemBuilder: (_, i) => _MemberItem(student: _members[i]),
    );
  }
}

class _MemberItem extends StatelessWidget {
  final StudentModel student;

  const _MemberItem({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF000080).withValues(alpha: 0.08),
            backgroundImage: student.picture.isNotEmpty
                ? NetworkImage(student.picture)
                : null,
            child: student.picture.isEmpty
                ? Text(
              student.firstName.isNotEmpty
                  ? student.firstName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                color: Color(0xFF000080),
                fontSize: 16,
              ),
            )
                : null,
          ),
          const SizedBox(width: 12),
          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${student.firstName} ${student.lastName}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Student',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF000080).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // Chat button
          IconButton(
            onPressed: () async {
              final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
              if (currentUserId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please sign in to chat with members.'),
                  ),
                );
                return;
              }

              try {
                final recipient = await _resolveChatRecipient(student);
                if (recipient.userId != student.uid && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('This child is contacted through their parent.'),
                    ),
                  );
                }

                final chatService = ChatService(FirestoreChatRepository());
                final conversation = await chatService.ensureDirectConversation(
                  currentUserId: currentUserId,
                  otherUserId: recipient.userId,
                );

                if (!context.mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ConversationPage(
                      conversation: conversation,
                      imageUrl: recipient.imageUrl,
                      currentUserId: currentUserId,
                    ),
                  ),
                );
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Unable to open chat: $error')),
                );
              }
            },
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Color(0xFF000080),
              size: 20,
            ),
          ),
          // More button
          PopupMenuButton<_MemberAction>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 20),
            onSelected: (_MemberAction action) async {
              if (action == _MemberAction.report) {
                final TextEditingController reportController = TextEditingController();
                final bool? submitted = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Report member'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Please describe the issue below.'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: reportController,
                            autofocus: true,
                            maxLines: 4,
                            maxLength: 300,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Write your report here...',
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final String text = reportController.text.trim();
                            if (text.isEmpty) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(content: Text('Please write your report before sending.')),
                              );
                              return;
                            }
                            Navigator.of(dialogContext).pop(true);
                          },
                          child: const Text('Send'),
                        ),
                      ],
                    );
                  },
                );

                if (submitted == true) {
                  final String reportText = reportController.text.trim();
                  try {
                    await CourseDetailsService().submitStudentReport(
                      student: student,
                      text: reportText,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report sent to admin successfully.')),
                    );
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to submit report: $error')),
                    );
                  }
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<_MemberAction>(
                value: _MemberAction.report,
                child: Text('Report member'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
enum _MemberAction {
  report,
}
