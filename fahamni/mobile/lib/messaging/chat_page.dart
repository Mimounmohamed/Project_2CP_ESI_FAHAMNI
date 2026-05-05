import 'package:fahamni/ParentDashboread/ParentCoursePage/parent_courses_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fahamni/Account_Settings_Student/account_screen.dart';
import 'package:fahamni/Courses/courses_page.dart';
import 'package:fahamni/Explore_map_pages/explorepage.dart';
import 'package:fahamni/StudentHomePage/Student_homepage.dart';
import 'package:fahamni/StudentHomePage/studenthome_service.dart';
import 'package:fahamni/Account_Settings_Parent/account_screen.dart';
import 'package:fahamni/ParentDashboread/ParentHomePage/home_page.dart';
import 'package:fahamni/ParentDashboread/ParentExplorePage/parent_explore_page.dart';
import 'package:fahamni/ParentDashboread/ParentSchedulePage/parent_schedule_page.dart';
import 'package:fahamni/widgets/customnavbar.dart';

import '../Services/chat_service.dart';
import '../models/user_model.dart';
import '../models/student_model.dart';
import 'chat_buttons.dart';
import 'ConversationBox.dart';
import '../models/chat_model.dart';
import '../repositories/firestore_chat_repository.dart';
import 'ai_study_chat_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService(FirestoreChatRepository());
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final studenthomepage_service _studentService = studenthomepage_service();
  int _selectedTabIndex = 0;
  bool _didResolveInitialTab = false;
  UserRole? _currentRole;
  StudentModel? _student;

  String? get _currentUserId => _auth.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _resolveInitialTab();
  }

  Future<void> _loadUserDataForNavigation() async {
    try {
      if (_currentRole == UserRole.student) {
        final StudentModel student = await _studentService.getStudentData();
        if (!mounted) {
          return;
        }
        setState(() {
          _student = student;
        });
      }
      // Parent users don't need additional data loading for navigation
    } catch (_) {
      // Non-student users can still use chat without bottom navbar navigation.
    }
  }

  Object? get _conversationFilter {
    switch (_selectedTabIndex) {
      case 0:
        return UserRole.tutor;
      case 1:
        return UserRole.student;
      case 2:
        return ChatConversationFilter.group;
      default:
        return null;
    }
  }

  Future<void> _resolveInitialTab() async {
    final String? userId = _currentUserId;
    if (userId == null || _didResolveInitialTab) return;

    UserRole? currentRole;
    final DocumentSnapshot<Map<String, dynamic>> userSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .get();
    final String? roleName = userSnapshot.data()?['role'] as String?;

    if (roleName != null) {
      for (final UserRole role in UserRole.values) {
        if (role.name == roleName) {
          currentRole = role;
          break;
        }
      }
    }

    if (currentRole == null) {
      final List<MapEntry<String, UserRole>> checks =
          <MapEntry<String, UserRole>>[
            const MapEntry<String, UserRole>('tutors', UserRole.tutor),
            const MapEntry<String, UserRole>('students', UserRole.student),
            const MapEntry<String, UserRole>('parents', UserRole.parent),
          ];

      for (final MapEntry<String, UserRole> check in checks) {
        final DocumentSnapshot<Map<String, dynamic>> snapshot = await _firestore
            .collection(check.key)
            .doc(userId)
            .get();
        if (snapshot.exists) {
          currentRole = check.value;
          break;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _didResolveInitialTab = true;
      _currentRole = currentRole;
      _selectedTabIndex = currentRole == UserRole.tutor ? 1 : 0;
    });

    // Load user data after role is resolved
    await _loadUserDataForNavigation();
  }

  void _handleBottomNavigation(int index) {
    // Don't handle navigation on the Chat tab itself
    if (index == 3) {
      return;
    }

    if (_currentRole == UserRole.student) {
      if (index == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Studenthomepage()),
        );
        return;
      }

      if (index == 1 && _student != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => Explorepage(student: _student!)),
        );
        return;
      }

      if (index == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CoursesPage()),
        );
        return;
      }

      if (index == 4) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        );
      }
    } else if (_currentRole == UserRole.parent) {
      if (index == 0) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Parenthomepage()),
        );
        return;
      }

      if (index == 1) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ParentExplorePage()),
        );
        return;
      }

      if (index == 2) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ParentCoursesPage()),
        );
        return;
      }

      if (index == 4) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ParentAccountScreen()),
        );
      }
    }
  }

  String _conversationName(ConversationModel conversation) {
    if (conversation.participantDisplayName.trim().isNotEmpty) {
      return conversation.participantDisplayName.trim();
    }

    if (conversation.conversationName.trim().isNotEmpty) {
      return conversation.conversationName.trim();
    }

    final Iterable<String> otherParticipants = conversation.participants.where(
      (participantId) => participantId != _currentUserId,
    );

    if (conversation.isGroup) {
      return 'Group Conversation';
    }

    return otherParticipants.isNotEmpty
        ? 'Direct Conversation'
        : 'Conversation';
  }

  String _conversationAvatar(ConversationModel conversation) {
    if (conversation.participantAvatarUrl.trim().isNotEmpty) {
      return conversation.participantAvatarUrl.trim();
    }

    final String name = _conversationName(conversation);
    final String encodedName = Uri.encodeComponent(name);
    return 'https://ui-avatars.com/api/?name=$encodedName&background=000080&color=ffffff';
  }

  void _openStudyAiPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AIStudyChatPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = _currentUserId;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
          child: Text(
            'Messages',
            style: GoogleFonts.inter(
              color: const Color(0xFF1F2937),
              fontSize: 32.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(140, 0, 0, 128),
                    blurRadius: 4,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Icon(
                      Icons.search,
                      color: Color.fromARGB(179, 31, 41, 55),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      style: GoogleFonts.inter(fontSize: 16.0),
                      decoration: const InputDecoration(
                        hintText: 'Search Conversations...',
                        hintStyle: TextStyle(
                          color: Color.fromARGB(179, 31, 41, 55),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tabs
          ChatButtons(
            selectedIndex: _selectedTabIndex,
            onChanged: (int index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
          ),

          // Conversation list
          Expanded(
            child: currentUserId == null
                ? const Center(
                    child: Text('Sign in to view your conversations.'),
                  )
                : StreamBuilder<List<ConversationModel>>(
                    stream: _chatService.getConversations(
                      currentUserId,
                      filter: _conversationFilter,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Failed to load conversations.'),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final List<ConversationModel> conversations =
                          snapshot.data ?? const <ConversationModel>[];

                      if (conversations.isEmpty) {
                        return const Center(
                          child: Text('No conversations yet.'),
                        );
                      }

                      return ListView.separated(
                        itemCount: conversations.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, indent: 80),
                        itemBuilder: (context, index) {
                          final ConversationModel conversation =
                              conversations[index].copyWith(
                                conversationName: _conversationName(
                                  conversations[index],
                                ),
                              );

                          return Conversationbox(
                            conversation: conversation,
                            imageUrl: _conversationAvatar(conversation),
                            currentUserId: currentUserId,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: currentUserId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _openStudyAiPage,
              backgroundColor: const Color(0xFFF5F7FF),
              foregroundColor: const Color(0xFF000080),
              elevation: 4,
              highlightElevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: Color.fromARGB(40, 0, 0, 128)),
              ),
              icon: const Icon(Icons.auto_awesome_rounded, size: 20),
              label: Text(
                'AI Study Help',
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF000080),
                ),
              ),
            ),
      bottomNavigationBar:
          _currentRole == UserRole.student || _currentRole == UserRole.parent
          ? CustomBottomNavbar(selectedIndex: 3, onTap: _handleBottomNavigation)
          : null,
    );
  }
}
