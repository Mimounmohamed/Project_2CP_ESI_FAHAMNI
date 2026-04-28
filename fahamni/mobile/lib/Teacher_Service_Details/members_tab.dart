import 'package:fahamni/TeacherDashboard/models/teacher_portal_models.dart';
import 'package:fahamni/TeacherDashboard/widgets/teacher_portal_modals.dart';
import 'package:fahamni/models/quote_model.dart';
import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../models/student_model.dart';
import 'member_item.dart';
import 'service_details_service.dart';

class MembersTab extends StatefulWidget {
  final ServiceModel service;

  const MembersTab({super.key, required this.service});

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  final _service = CourseDetailsService();
  List<StudentModel> _members = [];
  List<StudentModel> _pendingRequests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final membersData = await _service.getMembers(widget.service.serviceId);
    final pendingData = await _service.getPendingRequests(widget.service.serviceId);
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
      );

      final response = await QuoteResponseModal.show(context, requestDetail);
      if (response == null) return;
    }

    await _service.handleJoinRequest(widget.service.serviceId, student.uid, accept);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final total = _members.length;
    final remaining = widget.service.maxStudents - total;

    return Column(
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
                    value: remaining < 0 ? '0' : remaining.toString()),
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
                ..._pendingRequests.map((student) => _PendingRequestItem(
                      student: student,
                      service: widget.service,
                      onAccept: () => _handleRequest(student, true),
                      onReject: () => _handleRequest(student, false),
                    )),
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
                ..._members.map((m) => MemberItem(student: m)),
              ],
              if (_members.isEmpty && _pendingRequests.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text('No members or requests yet',
                        style: TextStyle(
                            fontFamily: 'Nunito', color: Color(0xFF94A3B8))),
                  ),
                ),
            ],
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
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
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
                        borderRadius: BorderRadius.circular(99)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Accept',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(99)),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: const Text('Reject',
                      style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w700)),
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
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: Color(0xFF000080))),
          ],
        ),
      ),
    );
  }
}


