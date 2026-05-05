import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool sessionReminder    = true;
  bool newMessages        = true;
  bool teacherResponses   = true;
  bool announcements      = false;
  bool emailNotifications = true;

  bool _isLoading = true;
  String? _uid;

  static const _prefFields = {
    'session_reminder':    true,
    'new_messages':        true,
    'teacher_responses':   true,
    'announcements':       false,
    'email_notifications': true,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { setState(() => _isLoading = false); return; }
    _uid = user.uid;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(_uid).get();
      final role = userDoc.data()?['role'] ?? 'student';
      final collection = _collectionForRole(role);

      final doc = await FirebaseFirestore.instance
          .collection(collection).doc(_uid).get();
      final prefs = (doc.data()?['notification_prefs'] as Map<String, dynamic>?) ?? {};

      setState(() {
        sessionReminder    = prefs['session_reminder']    ?? _prefFields['session_reminder']!;
        newMessages        = prefs['new_messages']        ?? _prefFields['new_messages']!;
        teacherResponses   = prefs['teacher_responses']   ?? _prefFields['teacher_responses']!;
        announcements      = prefs['announcements']       ?? _prefFields['announcements']!;
        emailNotifications = prefs['email_notifications'] ?? _prefFields['email_notifications']!;
      });
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    if (_uid == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(_uid).get();
      final role = userDoc.data()?['role'] ?? 'student';
      await FirebaseFirestore.instance
          .collection(_collectionForRole(role)).doc(_uid)
          .update({
        'notification_prefs': {
          'session_reminder':    sessionReminder,
          'new_messages':        newMessages,
          'teacher_responses':   teacherResponses,
          'announcements':       announcements,
          'email_notifications': emailNotifications,
        },
      });
    } catch (_) {}
  }

  String _collectionForRole(String role) {
    switch (role) {
      case 'tutor':  return 'tutors';
      case 'parent': return 'parents';
      default:       return 'students';
    }
  }

  void _toggle(void Function() update) {
    setState(update);
    _save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 30, color: Colors.black),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF000080)))
          : Padding(
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
                    onChanged: (v) => _toggle(() => sessionReminder = v),
                  ),
                  const SizedBox(height: 12),
                  _notificationTile(
                    icon: "assets/icons/icon2.svg",
                    title: "New messages",
                    subtitle: "Direct messages from peers",
                    value: newMessages,
                    onChanged: (v) => _toggle(() => newMessages = v),
                  ),
                  const SizedBox(height: 12),
                  _notificationTile(
                    icon: "assets/icons/icon3.svg",
                    title: "Teacher responses",
                    subtitle: "Feedback and answer alerts",
                    value: teacherResponses,
                    onChanged: (v) => _toggle(() => teacherResponses = v),
                  ),
                  const SizedBox(height: 12),
                  _notificationTile(
                    icon: "assets/icons/icon4.svg",
                    title: "Platform announcements",
                    subtitle: "Updates and community news",
                    value: announcements,
                    onChanged: (v) => _toggle(() => announcements = v),
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
                  _notificationTile(
                    icon: "assets/icons/icon1.svg",
                    title: "Email Notifications",
                    subtitle: "Receive updates via email",
                    value: emailNotifications,
                    onChanged: (v) => _toggle(() => emailNotifications = v),
                  ),
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
}


