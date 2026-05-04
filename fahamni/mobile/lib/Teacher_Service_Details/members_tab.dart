import 'package:fahamni/TeacherDashboard/models/teacher_portal_models.dart';
import 'package:fahamni/TeacherDashboard/widgets/teacher_portal_modals.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fahamni/Services/chat_service.dart';
import 'package:fahamni/messaging/conversation_page.dart';
import 'package:fahamni/models/quote_model.dart';
import 'package:fahamni/repositories/firestore_chat_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../models/student_model.dart';
import 'member_item.dart';
import 'service_details_service.dart';

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

class MembersTab extends StatefulWidget {
  final ServiceModel service;

  const MembersTab({super.key, required this.service});

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  final _service = CourseDetailsService();
  final _chatService = ChatService(FirestoreChatRepository());
  final _auth = FirebaseAuth.instance;
  List<StudentModel> _members = [];
  List<StudentModel> _pendingRequests = [];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final membersData = await _service.getMembers(widget.service.serviceId);
    final pendingData = await _service.getPendingRequests(
      widget.service.serviceId,
    );
    setState(() {
      _members = membersData;
      _pendingRequests = pendingData;
      _loading = false;
    });
  }

  Future<void> _handleRequest(StudentModel student, bool accept) async {
    if (accept) {
      final requestDetail = TeacherJoinRequestDetail(
        quote: QuoteModel(
          quoteId: '',
          studentId: student.uid,
          tutorId: widget.service.tutorId,
          subject: widget.service.subject,
          level: student.schoolLevel,
          objective: '',
          frequency: '',
          duration: '',
          budget: '',
        ),
        studentName: '${student.firstName} ${student.lastName}',
        studentLevel: student.schoolLevel,
        studentAvatar: student.picture,
        serviceTitle: widget.service.name,
        description: '',
        subject: widget.service.subject,
        teachingMode: widget.service.mode,
        sessionsCount: widget.service.sessionsnum,
        sessionDurationLabel: '${widget.service.duration} min',
        createdAtLabel: 'Now',
        isChild: student.email.isEmpty && student.phone.isEmpty,
      );

      final response = await QuoteResponseModal.show(context, requestDetail);
      if (response == null) return;
    }

    await _service.handleJoinRequest(
      widget.service.serviceId,
      student.uid,
      accept,
    );
    await _load();
  }

  Future<void> _openChat(StudentModel student) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be signed in to chat.')),
      );
      return;
    }

    if (student.uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open chat for this student.')),
      );
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      final recipient = await _resolveChatRecipient(student);
      if (recipient.userId != student.uid && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This child is contacted through their parent.'),
          ),
        );
      }

      final conversation = await _chatService.ensureDirectConversation(
        currentUserId: currentUser.uid,
        otherUserId: recipient.userId,
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationPage(
            conversation: conversation.copyWith(
              conversationName: recipient.displayName,
              participantDisplayName: recipient.displayName,
              participantAvatarUrl: recipient.imageUrl,
              participantSubtitle: recipient.displayName,
            ),
            imageUrl: recipient.imageUrl,
            currentUserId: currentUser.uid,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
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

  String _studentName(StudentModel student) {
    final name = '${student.firstName} ${student.lastName}'.trim();
    return name.isEmpty ? 'Student' : name;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final total = _members.length;
    final remaining = widget.service.maxStudents - total;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                margin: const EdgeInsets.fromLTRB(38, 0, 38, 0),
                child: Row(
                  children: [
                    _StatBox(label: 'TOTAL', value: total.toString()),
                    const SizedBox(width: 12),
                    _StatBox(
                      label: 'REMAINING',
                      value: remaining < 0 ? '0' : remaining.toString(),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (_pendingRequests.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Join Requests',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    ..._pendingRequests.map(
                      (student) => _PendingRequestItem(
                        student: student,
                        service: widget.service,
                        onAccept: () => _handleRequest(student, true),
                        onReject: () => _handleRequest(student, false),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_members.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Members',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    ..._members.map(
                      (m) => MemberItem(
                        student: m,
                        onChat: () => _openChat(m),
                        onReport: () => _showReportDialog(m),
                      ),
                    ),
                  ],
                  if (_members.isEmpty && _pendingRequests.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Text(
                          'No members or requests yet',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (_busy)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _PendingRequestItem extends StatelessWidget {
  final StudentModel student;
  final ServiceModel service;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _PendingRequestItem({
    required this.student,
    required this.service,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFDBEAFE),
                backgroundImage: student.picture.isNotEmpty
                    ? NetworkImage(student.picture)
                    : null,
                child: student.picture.isEmpty
                    ? Text(student.firstName[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${student.firstName} ${student.lastName}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '${service.subject} · ${student.schoolLevel}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'Now',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000080),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(99),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(99),
                    ),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF000080).withValues(alpha: 0.2),
              blurRadius: 2,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Lexend',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Color(0xFF000080),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
