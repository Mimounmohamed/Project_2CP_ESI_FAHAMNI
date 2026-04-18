import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool sessionReminder = true;
  bool newMessages = true;
  bool teacherResponses = true;
  bool announcements = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 30,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Notification",
          style: TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w700,
            fontSize: 32,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ALERT PREFERENCES",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _notificationTile(
              icon: "assets/icons/icon1.svg",
              title: "Session reminders",
              subtitle: "Get notified 15m before class",
              value: sessionReminder,
              onChanged: (v) => setState(() => sessionReminder = v),
            ),
            const SizedBox(height: 12),
            _notificationTile(
              icon: "assets/icons/icon2.svg",
              title: "New messages",
              subtitle: "Direct messages from peers",
              value: newMessages,
              onChanged: (v) => setState(() => newMessages = v),
            ),
            const SizedBox(height: 12),
            _notificationTile(
              icon: "assets/icons/icon3.svg",
              title: "Teacher responses",
              subtitle: "Feedback and answer alerts",
              value: teacherResponses,
              onChanged: (v) => setState(() => teacherResponses = v),
            ),
            const SizedBox(height: 12),
            _notificationTile(
              icon: "assets/icons/icon4.svg",
              title: "Platform announcements",
              subtitle: "Updates and community news",
              value: announcements,
              onChanged: (v) => setState(() => announcements = v),
            ),
            const SizedBox(height: 24),
            const Text(
              "OTHER SETTINGS",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            _otherTile("Email Notifications"),
          ],
        ),
      ),
    );
  }

  Widget _notificationTile({
    required String icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            offset: Offset(0, 1),
            blurRadius: 2,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: SvgPicture.asset(
                icon,
                width: 20,
                height: 20,
                // ✅ Fixed: colorFilter instead of deprecated color param
                colorFilter: const ColorFilter.mode(
                  Color(0xFF000080),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          _customToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _customToggle({
    required bool value,
    required Function(bool) onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        width: 51,
        height: 31,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF000080) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 27,
            height: 27,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _otherTile(String text) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        debugPrint("Email Notifications tapped");
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              offset: Offset(0, 1),
              blurRadius: 2,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}