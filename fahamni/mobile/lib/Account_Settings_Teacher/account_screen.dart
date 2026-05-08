import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fahamni/TeacherDashboard/teacher_dashboard_service.dart';
import 'package:fahamni/TeacherDashboard/teacher_services_dashboard.dart';
import 'package:fahamni/TeacherDashboard/widgets/teacher_navbar.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/models/teacher_dashboard_model.dart';
import 'package:fahamni/feedback/feedback_pages.dart';
import '../TeacherDashboard/teacher_dashboard.dart';
import '../TeacherDashboard/teacher_quotes_page.dart';
import 'settings_menu_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, this.suspendedMode = false});

  final bool suspendedMode;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late Future<TeacherDashboardModel> _dashboardFuture;
  final TeacherDashboardService _service = TeacherDashboardService();

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _service.loadDashboard();
  }

  void _handleNavigation(int index) {
    if (widget.suspendedMode && index != 3) {
      _showSuspendedDialog();
      return;
    }
    if (index == 3) return;
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
        );
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const TeacherServicesDashboardScreen(),
          ),
        );
        break;
      case 2:
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const ChatPage()));
        break;
    }
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
      child: Text(
        'Your account is suspended. Please contact the admins.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: const Color(0xFFB91C1C),
          fontWeight: FontWeight.w600,
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
        onTap: _handleNavigation,
      ),
      body: SafeArea(
        child: FutureBuilder<TeacherDashboardModel>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF000080)),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {
                          _dashboardFuture = _service.loadDashboard();
                        }),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              );
            }

            final dashboard = snapshot.data!;
            final tutor = dashboard.tutorProfile;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Account",
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  if (widget.suspendedMode) ...[
                    const SizedBox(height: 12),
                    _suspendedBanner(),
                  ],
                  const SizedBox(height: 30),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage: tutor.picture.isNotEmpty
                        ? NetworkImage(tutor.picture)
                        : null,
                    child: tutor.picture.isEmpty
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: Color(0xFF64748B),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${tutor.firstName} ${tutor.lastName}',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tutor.expertiseDomain} Specialist',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(height: 30),

                  if (!widget.suspendedMode) ...[
                    _PerformanceOverviewCard(stats: dashboard.stats),
                    const SizedBox(height: 30),
                    _AccountMenuItem(
                      icon: Icons.star_border,
                      title: "FeedBacks",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FeedbacksPage(
                              tutorId: tutor.uid,
                              tutorName: '${tutor.firstName} ${tutor.lastName}',
                            ),
                          ),
                        );
                      },
                    ),
                    _AccountMenuItem(
                      icon: Icons.description_outlined,
                      title: "Quote Requests",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TeacherQuotesPage(),
                          ),
                        );
                      },
                    ),
                  ],
                  _AccountMenuItem(
                    icon: Icons.settings_outlined,
                    title: "Settings",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TeacherSettingsPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PerformanceOverviewCard extends StatelessWidget {
  final List<TeacherDashboardStat> stats;

  const _PerformanceOverviewCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEFF5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Performance Overview",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: stats.map((stat) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          stat.label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (stat.label == 'RATING')
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                stat.value,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                              SvgPicture.asset(
                                "assets/images/star.svg",
                                height: 14,
                                width: 14,
                              ),
                            ],
                          )
                        else
                          Text(
                            stat.value,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AccountMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AccountMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: const Color(0xFF64748B)),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1F2937),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB)),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
    );
  }
}
