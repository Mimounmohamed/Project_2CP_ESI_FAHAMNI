import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/chat_model.dart';

class AttachmentsList extends StatelessWidget {
  final List<AttachmentModel> attachments;

  const AttachmentsList({
    super.key,
    this.attachments = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return Center(
        child: Text(
          'No attachments',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        final attachment = attachments[index];
        final String displaySize = attachment.isLink
            ? 'Link'
            : '${(attachment.size / 1024 / 1024).toStringAsFixed(1)} MB';

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
              if (attachment.isLink) {
                // Open link in browser or handle link click
              } else {
                // Handle file download/open
              }
            },
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EAF6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                attachment.isLink ? Icons.link_outlined : Icons.attach_file,
                color: const Color(0xFF000080),
                size: 22,
              ),
            ),
            title: Text(
              attachment.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: const Color(0xFF1F2937),
              ),
            ),
            subtitle: Text(
              displaySize,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
            trailing: Icon(
              attachment.isLink ? Icons.open_in_new : Icons.file_download_outlined,
              color: const Color(0xFF9CA3AF),
              size: 22,
            ),
          ),
        );
      },
    );
  }
}

