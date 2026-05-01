import 'package:fahamni/models/chat_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.messageModel,
    required this.isme,
  });

  final MessageModel messageModel;
  final bool isme;

  @override
  Widget build(BuildContext context) {
    final bool hasAttachments = messageModel.attachments.isNotEmpty;
    final bool isVoiceMessage = messageModel.voiceUrl != null;
    
    return Align(
      alignment: isme ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: Color(isme ? 0xFF000080 : 0xFFFFFFFF),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.only(
            topRight: const Radius.circular(16),
            topLeft: const Radius.circular(16),
            bottomLeft: Radius.circular(isme ? 16 : 0),
            bottomRight: Radius.circular(isme ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text message
            if ((messageModel.content).isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  messageModel.content,
                  style: GoogleFonts.inter(
                    color: Color(isme ? 0xFFFFFFFF : 0xFF1F2937),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            // Attachments
            if (hasAttachments)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: messageModel.attachments
                      .map((attachment) => _buildAttachmentWidget(attachment, isme))
                      .toList(),
                ),
              ),
            // Voice message
            if (isVoiceMessage)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mic,
                      color: isme ? Colors.white : const Color(0xFF000080),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Voice message',
                      style: GoogleFonts.inter(
                        color: isme ? Colors.white : const Color(0xFF1F2937),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentWidget(AttachmentModel attachment, bool isMe) {
    if (attachment.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          attachment.url,
          width: 200,
          height: 150,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 200,
            height: 150,
            color: const Color(0xFFE2E8F0),
            child: const Icon(Icons.image_not_supported),
          ),
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isMe
                ? Colors.white.withValues(alpha: 0.3)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 18,
              color: isMe ? Colors.white : const Color(0xFF000080),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attachment.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isMe ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    '${(attachment.size / 1024 / 1024).toStringAsFixed(1)} MB',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isMe
                          ? Colors.white.withValues(alpha: 0.7)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.download_outlined,
              size: 16,
              color: isMe ? Colors.white : const Color(0xFF000080),
            ),
          ],
        ),
      );
    }
  }
}


