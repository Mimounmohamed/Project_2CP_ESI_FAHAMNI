import 'package:flutter/material.dart';
import '../models/student_model.dart';

class MemberItem extends StatelessWidget {
  final StudentModel student;

  const MemberItem({super.key, required this.student});

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
          )
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
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: const Color(0xFF000080).withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.chat_bubble_outline_rounded,
                color: Color(0xFF000080), size: 20),
          ),
          const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 20),
        ],
      ),
    );
  }
}


