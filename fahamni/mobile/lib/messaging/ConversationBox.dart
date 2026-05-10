import 'package:flutter/material.dart';
import '../utils/image_utils.dart';

import '../models/chat_model.dart';
import 'conversation_page.dart';

class Conversationbox extends StatelessWidget {
  const Conversationbox({
    super.key,
    required this.conversation,
    required this.imageUrl,
    required this.currentUserId,
    this.onLongPress,
  });

  final ConversationModel conversation;
  final String imageUrl;
  final String currentUserId;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final MessageModel? lastMessage =
        conversation.lastMessage ??
        (conversation.messages.isNotEmpty ? conversation.messages.last : null);
    final bool isMe = lastMessage?.senderId == currentUserId;
    final String displayName = conversation.participantDisplayName.isNotEmpty
        ? conversation.participantDisplayName
        : conversation.conversationName;
    final String subtitle = conversation.participantSubtitle;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationPage(
              conversation: conversation,
              imageUrl: imageUrl,
              currentUserId: currentUserId,
            ),
          ),
        );
      },
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundImage: safeImage(
                    imageUrl,
                    defaultAsset: 'assets/images/studentmale.png',
                  ),
                  radius: 28,
                ),
                if (conversation.isOnline)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: Color(0xFF253046),
                          ),
                        ),
                      ),
                      if (conversation.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.verified_outlined,
                            color: Color(0xFF000080),
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8A9AB5),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    "${isMe ? 'You: ' : ''}${conversation.lastMessageText}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF5F6C84),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _displayTime(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A9AB5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),

                if (conversation.unreadCount > 0)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF000080),
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(height: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _displayTime() {
    final DateTime timestamp =
        conversation.lastMessage?.sendingDateTime ?? conversation.createdAt;
    final Duration difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) return 'now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return conversation.lastMessageTime;
  }
}
