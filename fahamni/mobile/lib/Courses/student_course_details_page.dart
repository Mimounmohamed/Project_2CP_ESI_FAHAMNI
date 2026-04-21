import 'package:fahamni/Account_Settings_Student/account_screen.dart';
import 'package:fahamni/Courses/courses_page.dart';
import 'package:fahamni/StudentHomePage/Student_homepage.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/widgets/customnavbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../models/service_model.dart';
import '../models/tutor_model.dart';
import '../Courses/members_tab.dart';
import '../Courses/Ressources_tab.dart';
import '../Courses/Session_tab.dart';

class StudentCourseDetailsPage extends StatefulWidget {
  final ServiceModel service;
  final TutorModel tutor;

  const StudentCourseDetailsPage({
    super.key,
    required this.service,
    required this.tutor,
  });

  @override
  State<StudentCourseDetailsPage> createState() => _StudentCourseDetailsPageState();
}

class _StudentCourseDetailsPageState extends State<StudentCourseDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_outlined,
              color: Color(0xFF0F172A)),
        ),
        title: Text(
          widget.service.name,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Card (Tutor Info)
          Container(
            padding: const EdgeInsets.all(12),
            margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.05),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    widget.tutor.picture,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/tutormale.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.tutor.firstName} ${widget.tutor.lastName}',
                        style: const TextStyle(
                          fontFamily: "Lexend",
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.tutor.expertiseDomain,
                        style: const TextStyle(
                          fontFamily: "Lexend",
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                "assets/images/position.svg",
                                height: 12,
                                width: 12,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFF64748B),
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                widget.tutor.location,
                                style: const TextStyle(
                                  fontFamily: "Lexend",
                                  fontWeight: FontWeight.w500,
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            widget.tutor.isAvailable ? 'Available' : 'Busy',
                            style: TextStyle(
                              fontFamily: "Lexend",
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              color: widget.tutor.isAvailable
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: ShapeDecoration(
                    color: const Color(0xFF000080).withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        "assets/images/star.svg",
                        height: 12,
                        width: 12,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        widget.tutor.averageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 12,
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // TabBar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                labelColor: const Color(0xFF000080),
                unselectedLabelColor: const Color(0xFF94A3B8),
                indicatorColor: const Color(0xFF000080),
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Sessions'),
                  Tab(text: 'Resources'),
                  Tab(text: 'Members'),
                ],
              ),
            ),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SessionTab(
                  serviceId: widget.service.serviceId,
                  totalSessions: widget.service.sessionsnum,
                ),
                ResourceTab(serviceId: widget.service.serviceId),
                MemberTab(service: widget.service),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavbar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          if (index == _selectedIndex) return;
          if (index == 0) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const Studenthomepage()));
          } else if (index == 2) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const CoursesPage()));
          } else if (index == 3) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const ChatPage()));
          } else if (index == 4) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const AccountScreen()));
          }
        },
      ),
    );
  }
}
