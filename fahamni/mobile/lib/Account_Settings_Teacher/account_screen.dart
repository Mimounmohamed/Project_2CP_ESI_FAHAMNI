import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';
import 'package:fahamni/Login_Screen/LoginScreen.dart';
import 'package:fahamni/TeacherDashboard/teacher_dashboard.dart';
import 'package:fahamni/TeacherDashboard/teacher_services_dashboard.dart';
import 'package:fahamni/TeacherDashboard/widgets/teacher_navbar.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:fahamni/models/user_model.dart';
import 'personalinfo_screen.dart';
import 'academic_info_screen.dart';
import 'profilesettings.dart';
import 'notification_screen.dart';
import 'helpsupport_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  TutorModel? tutor;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTutor();
  }

  Future<void> _loadTutor() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final snap = await FirebaseFirestore.instance
          .collection('tutors')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      if (snap.exists && snap.data() != null) {
        setState(() => tutor = TutorModel.fromMap({...snap.data()!, 'uid': snap.id}));
      }
    } catch (e) {
      debugPrint('AccountScreen loadTutor error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are you sure you want to logout from Fahamni?',
          style: TextStyle(fontFamily: 'Inter', color: Color(0xFF6B7280)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout',
                style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try { await GoogleSignIn().signOut(); } catch (_) {}
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  ImageProvider _avatarImage() {
    if (tutor == null) return const AssetImage("assets/images/studentmale.png");
    final pic = tutor!.picture;
    if (pic.startsWith('http')) return NetworkImage(pic);
    if (pic.startsWith('assets/')) return AssetImage(pic);
    return tutor!.gender == Gender.female
        ? const AssetImage("assets/images/studentfemale.png")
        : const AssetImage("assets/images/studentmale.png");
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget page,
  ) {
    return InkWell(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        _loadTutor();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF000080)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: "Inter",
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      bottomNavigationBar: TeacherNavbar(
        selectedIndex: 3,
        onTap: (int index) {
          if (index == 3) return;
          if (index == 0) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()));
          } else if (index == 1) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const TeacherServicesDashboardScreen()));
          } else if (index == 2) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const ChatPage()));
          }
        },
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF000080)))
            : RefreshIndicator(
                color: const Color(0xFF000080),
                onRefresh: _loadTutor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const Text(
                        "Account",
                        style: TextStyle(
                          fontFamily: "Inter",
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 24),
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _avatarImage(),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        tutor != null
                            ? '${tutor!.firstName} ${tutor!.lastName}'
                            : '—',
                        style: const TextStyle(
                          fontFamily: "Inter",
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (tutor != null &&
                          tutor!.expertiseDomain.isNotEmpty)
                        Text(
                          tutor!.expertiseDomain,
                          style: const TextStyle(
                            fontFamily: "Inter",
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildMenuItem(context, Icons.person_outline,
                                "Personal Information",
                                const PersonalInfoScreen()),
                            _buildMenuItem(context, Icons.school_outlined,
                                "Academic Information",
                                const AcademicInfoScreen()),
                            _buildMenuItem(context, Icons.settings_outlined,
                                "Profile Settings",
                                const ProfileSettingsScreen()),
                            _buildMenuItem(context, Icons.notifications_none,
                                "Notifications", const NotificationScreen()),
                            _buildMenuItem(context, Icons.help_outline,
                                "Help & Support", const HelpSupportScreen()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 34),
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: TextButton(
                          onPressed: _logout,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout, color: Color(0xFFEF4444)),
                              SizedBox(width: 8),
                              Text(
                                "Logout from Fahamni",
                                style: TextStyle(
                                  fontFamily: "Inter",
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
