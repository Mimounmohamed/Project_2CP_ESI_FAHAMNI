import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/student_model.dart';

class MemberItem extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onChat;
  final VoidCallback onReport;

  const MemberItem({
    super.key,
    required this.student,
    required this.onChat,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF000080).withValues(alpha: 0.1),
            backgroundImage: student.picture.isNotEmpty
                ? NetworkImage(student.picture)
                : null,
            child: student.picture.isEmpty
                ? Text(
                    student.firstName[0].toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF000080),
                    ),
                  )
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
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Student',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: const Color(0xFF000080).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onChat,
            icon: SvgPicture.asset(
              'assets/images/chat.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Color(0xFF000080),
                BlendMode.srcIn,
              ),
            ),
          ),
          PopupMenuButton<_MemberAction>(
            icon: const Icon(
              Icons.more_vert,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            color: Colors.white,
            onSelected: (action) {
              switch (action) {
                case _MemberAction.report:
                  onReport();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<_MemberAction>(
                value: _MemberAction.report,
                child: Row(
                  children: [
                    Icon(
                      Icons.outlined_flag_rounded,
                      size: 18,
                      color: Color(0xFF1F2937),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Report',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _MemberAction { report }
