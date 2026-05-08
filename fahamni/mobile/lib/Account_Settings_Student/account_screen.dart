import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fahamni/Login_Screen/LoginScreen.dart';
import 'package:fahamni/widgets/customnavbar.dart';
import 'package:fahamni/Account_Settings_Student/studyinfo_screen.dart';
import 'package:fahamni/Account_Settings_Student/profilesettings.dart';
import 'package:fahamni/Account_Settings_Student/notification_screen.dart';
import 'package:fahamni/Account_Settings_Student/helpsupport_screen.dart';
import 'package:fahamni/Account_Settings_Student/personalinfo_screen.dart';
import 'package:fahamni/Explore_map_pages/explorepage.dart';
import 'package:fahamni/Courses/courses_page.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/models/student_model.dart';
import 'package:fahamni/models/user_model.dart';
import 'package:fahamni/StudentHomePage/studenthome_service.dart';
import 'package:fahamni/StudentHomePage/Student_homepage.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, this.suspendedMode = false});

  final bool suspendedMode;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int _selectedIndex = 4;
  StudentModel? student;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStudent();
  }

  Future<void> _loadStudent() async {
    setState(() => _isLoading = true);
    try {
      final data = await studenthomepage_service().getStudentData();
      if (!mounted) return;
      setState(() => student = data);
    } catch (e) {
      debugPrint('AccountScreen loadStudent error: $e');
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  // ── Subtitle under name: "Grade · Level · Speciality" ───────────────────
  String _studySubtitle() {
    final grade = student?.grade ?? '';
    final level = student?.schoolLevel ?? '';
    final speciality = student?.speciality ?? '';
    final base = [grade, level].where((s) => s.isNotEmpty).join(' · ');
    if (base.isNotEmpty && speciality.isNotEmpty) return '$base · $speciality';
    return base;
  }

  ImageProvider _avatarImage() {
    if (student == null) {
      return const AssetImage("assets/images/studentmale.png");
    }
    final pic = student!.picture;
    if (pic.startsWith('http')) return NetworkImage(pic);
    if (pic.startsWith('assets/')) return AssetImage(pic);
    return student!.gender == Gender.female
        ? const AssetImage("assets/images/studentfemale.png")
        : const AssetImage("assets/images/studentmale.png");
  }

  void _showSuspendedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Account Suspended'),
        content: const Text(
          'Your account has been suspended. Please contact the admins for help.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _suspendedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFECACA)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Your account is suspended. Please contact the admins.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFB91C1C),
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
    );
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
        _loadStudent();
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
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      bottomNavigationBar: CustomBottomNavbar(
        selectedIndex: _selectedIndex,
        onTap: (int index) {
          if (widget.suspendedMode && index != 4) {
            _showSuspendedDialog();
            return;
          }
          if (index == _selectedIndex) {
            return;
          }
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Studenthomepage()),
            );
          } else if (index == 1 && student != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => Explorepage(student: student!)),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const CoursesPage()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ChatPage()),
            );
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF000080)),
              )
            : RefreshIndicator(
                color: const Color(0xFF000080),
                onRefresh: _loadStudent,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // ── Title ────────────────────────────────────────
                      const Text(
                        "Account",
                        style: TextStyle(
                          fontFamily: "Inter",
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      if (widget.suspendedMode) ...[
                        const SizedBox(height: 12),
                        _suspendedBanner(),
                      ],

                      const SizedBox(height: 24),

                      // ── Avatar ───────────────────────────────────────
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _avatarImage(),
                      ),

                      const SizedBox(height: 10),

                      // ── Name ─────────────────────────────────────────
                      Text(
                        student != null
                            ? '${student!.firstName} ${student!.lastName}'
                            : '—',
                        style: const TextStyle(
                          fontFamily: "Inter",
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // ── Grade · Level ─────────────────────────────────
                      if (_studySubtitle().isNotEmpty)
                        Text(
                          _studySubtitle(),
                          style: const TextStyle(
                            fontFamily: "Inter",
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // ── Menu card ─────────────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              context,
                              Icons.person_outline,
                              "Personal Information",
                              const PersonalInfoScreen(),
                            ),
                            _buildMenuItem(
                              context,
                              Icons.school_outlined,
                              "Study Information",
                              const StudyInfoScreen(),
                            ),
                            _buildMenuItem(
                              context,
                              Icons.settings_outlined,
                              "Profile Settings",
                              const ProfileSettingsScreen(),
                            ),
                            _buildMenuItem(
                              context,
                              Icons.notifications_none,
                              "Notifications",
                              const NotificationScreen(),
                            ),
                            _buildMenuItem(
                              context,
                              Icons.help_outline,
                              "Help & Support",
                              const HelpSupportScreen(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 34),

                      // ── Logout ────────────────────────────────────────
                      Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
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
