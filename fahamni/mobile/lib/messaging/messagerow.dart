import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import 'message_bubble.dart';
import 'package:intl/intl.dart';



class MessageRow extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String senderAvatarUrl;
  String get formattedTime => DateFormat('hh:mm a').format(message.sendingDateTime);

  const MessageRow({
    super.key,
    required this.message,
    required this.isMe,
    required this.senderAvatarUrl,
  });

  @override
Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end, 
      children: isMe ? [
        
        Flexible(
          child: Column(
            
            crossAxisAlignment: CrossAxisAlignment.end, 
            children: [
              MessageBubble(messageModel: message, isme: isMe),
              const SizedBox(height: 2),
              Text(formattedTime, style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundImage: NetworkImage(senderAvatarUrl),
          radius: 16,
        ),
      ] : [
        
        CircleAvatar(
          backgroundImage: NetworkImage(senderAvatarUrl),
          radius: 16,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              MessageBubble(messageModel: message, isme: isMe),
              const SizedBox(height: 2),
              Text(formattedTime, style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ),
      ],
    ),
  );
}
      
}

