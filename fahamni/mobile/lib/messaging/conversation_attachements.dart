import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AttachmentsList extends StatelessWidget {
  const AttachmentsList({super.key});

  final List<Map<String, String>> attachments = const [
    {
      'title': 'Lecture_04_Linked_Lists.pdf',
      'subtitle': 'Sep 15 • 1.8 MB',
      'type': 'file'
    },
    {
      'title': 'Assignment_1_Guidelines.docx',
      'subtitle': 'Sep 15 • 820 KB',
      'type': 'file'
    },
    {
      'title': 'Guide for Z language',
      'subtitle': 'Sep 15 • DriveAlsdd/',
      'type': 'link'
    },
  ];

  @override
  Widget build(BuildContext context) {

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16,8,16,8),
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        final item = attachments[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            onTap: () {
              if (item['type'] == 'link') {
              } 
              else {
              }
            },
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.attach_file, 
                color: Color(0xFF000080),
                size: 22,
              ),
            ),
            title: Text(
              item['title']!,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: const Color(0xFF1F2937),
              ),
            ),
            subtitle: Text(
              item['subtitle']!,
              style: GoogleFonts.inter(
                fontSize: 12, 
                color: const Color(0xFF6B7280),
              ),
            ),
            trailing: Icon(
              item['type'] == 'link' ? Icons.open_in_new : Icons.file_download_outlined,
              color: const Color(0xFF9CA3AF),
              size: 22,
            ),
          ),
        );
      },
    );
  }
}

