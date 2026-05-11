import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../models/service_model.dart';
import '../models/student_model.dart';
import '../Services/chat_service.dart';
import '../repositories/firestore_chat_repository.dart';
import '../Teacher_Service_Details/service_details_service.dart';
import '../messaging/conversation_page.dart';
import '../utils/image_utils.dart';

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

  Future<void> _showReportDialog(StudentModel student) async {
    final reportController = TextEditingController();
    final pageContext = context;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 22),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Report',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your Report',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reportController,
                      maxLength: 200,
                      maxLines: 5,
                      minLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Write something ...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontFamily: 'Nunito',
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF000080),
                          ),
                        ),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${reportController.text.length}/200',
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: SizedBox(
                        width: 108,
                        height: 42,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                            final text = reportController.text.trim();
                            if (text.isEmpty) {
                              ScaffoldMessenger.of(
                                pageContext,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please write your report before sending.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setDialogState(() {
                              isSubmitting = true;
                            });

                            try {
                              await _service.submitStudentReport(
                                student: student,
                                text: text,
                              );
                              if (!mounted || !pageContext.mounted) {
                                return;
                              }
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(
                                pageContext,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Report submitted successfully.',
                                  ),
                                ),
                              );
                            } catch (error) {
                              if (!mounted || !pageContext.mounted) {
                                return;
                              }
                              setDialogState(() {
                                isSubmitting = false;
                              });
                              ScaffoldMessenger.of(
                                pageContext,
                              ).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF000080),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            elevation: 0,
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Send',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
      itemBuilder: (_, i) => _MemberItem(
        student: _members[i],
        onReport: () => _showReportDialog(_members[i]),
      ),
    );
  }
}

class _MemberItem extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onReport;

  const _MemberItem({
    required this.student,
    required this.onReport,
  });

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
            backgroundImage: safeImage(
              student.picture,
              defaultAsset: student.gender.name == 'female'
                  ? 'assets/images/studentfemale.png'
                  : 'assets/images/studentmale.png',
            ),
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
            icon:SvgPicture.asset(
              'assets/images/chat.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Color(0xFF000080),
                BlendMode.srcIn,
              ),
            ),
          ),
          // More button
          PopupMenuButton<_MemberAction>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 20),
            onSelected: (_MemberAction action) {
              if (action == _MemberAction.report) {
                onReport();
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
