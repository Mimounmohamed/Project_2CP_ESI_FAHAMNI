import 'package:flutter/material.dart';
import '../../models/student_model.dart';
import '../../models/service_model.dart';
import '../course_details_service.dart';
import '../widgets/member_item.dart';

class MembersTab extends StatefulWidget {
  final ServiceModel service;

  const MembersTab({super.key, required this.service});

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  final _service = CourseDetailsService();
  List<StudentModel> _members = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getMembers(widget.service.studentIds);
    setState(() {
      _members = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final total = widget.service.studentIds.length;
    final remaining = widget.service.maxStudents - total;

    return Column(
      children: [
        // Stats row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
        // Members list
        Expanded(
          child: _members.isEmpty
              ? const Center(
                  child: Text('No members yet',
                      style: TextStyle(
                          fontFamily: 'Nunito', color: Color(0xFF94A3B8))))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _members.length,
                  itemBuilder: (_, i) => MemberItem(student: _members[i]),
                ),
        ),
      ],
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
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