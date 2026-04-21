import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fahamni/Services/notification_service.dart';
import 'package:fahamni/StudentHomePage/Student_homepage.dart';
import 'package:fahamni/Courses/courses_page.dart';
import 'package:fahamni/feedback/feedback_pages.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/messaging/conversation_page.dart';
import 'package:fahamni/models/chat_model.dart';
import 'package:fahamni/Account_Settings_Student/account_screen.dart';
import 'package:fahamni/widgets/customnavbar.dart';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../widgets/notification_item.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  int _selectedTab = 0;
  int _navIndex = 0;

  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    final String notificationDocId =
        notification.id ?? notification.notificationId;
    if (notificationDocId.isNotEmpty && !notification.isRead) {
      await _notificationService.markAsRead(notificationDocId);
    }

    if (!mounted) {
      return;
    }

    if (notification.type == 'message' && notification.conversationId.isNotEmpty) {
      final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
          .collection('conversations')
          .doc(notification.conversationId)
          .get();
      if (!mounted) {
        return;
      }
      if (snapshot.exists && snapshot.data() != null) {
        final ConversationModel conversation = ConversationModel.fromMap({
          ...snapshot.data()!,
          'conversationId': snapshot.data()!['conversationId'] ??
              snapshot.data()!['conversation_id'] ??
              snapshot.id,
        });
        final String imageUrl = conversation.participantAvatarUrl.isNotEmpty
            ? conversation.participantAvatarUrl
            : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(conversation.conversationName.isEmpty ? 'Chat' : conversation.conversationName)}&background=000080&color=ffffff';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConversationPage(
              conversation: conversation,
              imageUrl: imageUrl,
              currentUserId: _currentUserId ?? '',
            ),
          ),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatPage()),
      );
      return;
    }

    if (notification.tutorId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TutorProfilePage(tutorId: notification.tutorId),
        ),
      );
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const Color accentBlue = Color(0xFF000080);

    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black,size: 35,),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification',
          style: GoogleFonts.inter(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w800,
            fontSize: 40,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 15),
          _buildToggle(accentBlue),

          Expanded(
            // Retrieve the notification from database in real time
            child: _currentUserId == null
                ? const Center(child: Text('Sign in to view notifications'))
                : StreamBuilder<List<NotificationModel>>(
              stream: _notificationService.streamNotifications(_currentUserId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allNotifications = snapshot.data ?? [];

                if (allNotifications.isEmpty) {
                  return const Center(child: Text('No notifications'));
                }

                // Display depends on which tab is selected
                final visibleNotifications = _selectedTab == 0
                    ? allNotifications.where((n) => !n.isRead).toList()
                    : allNotifications;

                if (visibleNotifications.isEmpty) {
                  return const Center(child: Text('No new notifications'));
                }

                return ListView.builder(
                  itemCount: visibleNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = visibleNotifications[index];
                    return NotificationItem(
                      notification: notification,
                      onTap: () => _handleNotificationTap(notification),
                    );
                  },
                );
              },
            ),
          ),

          // Mark as Read Button logic
          if (_currentUserId != null)
          StreamBuilder<List<NotificationModel>>(
            stream: _notificationService.streamNotifications(_currentUserId!),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.where((n) => !n.isRead).length ?? 0;
              
              if (_selectedTab == 0 && unreadCount > 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 110.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      await _notificationService.markAllAsRead(_currentUserId!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('Mark as read', 
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavbar(
        selectedIndex: _navIndex,
        onTap: _handleBottomNavigation,
      ),


    );
  }


  Widget _buildToggle(Color accentBlue) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 80),
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF94A3B8),
        borderRadius: BorderRadius.circular(30),

      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          spacing: 7,
          children: [
            _buildToggleTab(label: 'Unread', index: 0, accentBlue: accentBlue),
            _buildToggleTab(label: 'All',    index: 1, accentBlue: accentBlue),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTab({
    required String label,
    required int index,
    required Color accentBlue,
  }) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? accentBlue : Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.nunito(
              color: isSelected ? Colors.white : const Color(0xFF000080),
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),

            ),
          ),
        ),
      );
  }
  void _handleBottomNavigation(int index) {
    if (index == _navIndex) {
      return;
    }

    setState(() => _navIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Studentpage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ChatPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CoursesPage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This section is coming soon.')),
        );
    }
  }

}
