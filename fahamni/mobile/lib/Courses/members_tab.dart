import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../models/student_model.dart';
import '../Teacher_Service_Details/service_details_service.dart';

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
            color: Colors.black.withOpacity(0.04),
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
            backgroundColor: const Color(0xFF000080).withOpacity(0.08),
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
                    color: const Color(0xFF000080).withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          // Chat button
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Color(0xFF000080),
              size: 20,
            ),
          ),
          // More button
          const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 20),
        ],
      ),
    );
  }
}