import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/notification_model.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const Color navyBlue = Color(0xFF1D263B);
    final _NotificationIconConfig iconConfig = _notificationIconForType(
      notification.type,
    );

    return Column(
      children: [
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black12,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              vertical: 15.0,
              horizontal: 20.0,
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 6.0),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: iconConfig.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  iconConfig.icon,
                  size: 26,
                  color: iconConfig.iconColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: navyBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.content,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!notification.isRead)
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Color(0xFF000080),
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 9),
                    const SizedBox(height: 12),
                    Text(
                      DateFormat('hh:mm a').format(notification.dateTime),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 0.8,
          indent: 75,
          endIndent: 16,
          color: Colors.grey.shade300,
        ),
      ],
    );
  }
}

class _NotificationIconConfig {
  const _NotificationIconConfig({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
}

_NotificationIconConfig _notificationIconForType(String type) {
  switch (type.trim().toLowerCase()) {
    case 'message':
      return const _NotificationIconConfig(
        icon: Icons.chat_bubble_outline_rounded,
        iconColor: Color(0xFF000080),
        backgroundColor: Color(0xFFE0E7FF),
      );
    case 'review':
      return const _NotificationIconConfig(
        icon: Icons.star_outline_rounded,
        iconColor: Color(0xFFF59E0B),
        backgroundColor: Color(0xFFFEF3C7),
      );
    case 'join_request':
      return const _NotificationIconConfig(
        icon: Icons.how_to_reg_outlined,
        iconColor: Color(0xFF2563EB),
        backgroundColor: Color(0xFFDBEAFE),
      );
    case 'quote_request':
      return const _NotificationIconConfig(
        icon: Icons.request_quote_outlined,
        iconColor: Color(0xFF0F766E),
        backgroundColor: Color(0xFFCCFBF1),
      );
    case 'password_reset':
      return const _NotificationIconConfig(
        icon: Icons.lock_reset_rounded,
        iconColor: Color(0xFF7C3AED),
        backgroundColor: Color(0xFFEDE9FE),
      );
    default:
      return const _NotificationIconConfig(
        icon: Icons.notifications_none_rounded,
        iconColor: Color(0xFF1D263B),
        backgroundColor: Color(0xFFE5E7EB),
      );
  }
}
