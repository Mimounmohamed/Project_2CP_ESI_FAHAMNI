import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../models/tutor_model.dart';
import 'members_tab.dart';
import 'ressources_tab.dart';
import 'sessions_tab.dart';

class CourseDetailsPage extends StatefulWidget {
  final ServiceModel service;
  final TutorModel tutor;

  const CourseDetailsPage({
    super.key,
    required this.service,
    required this.tutor,
  });

  @override
  State<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends State<CourseDetailsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
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
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_outlined,
              color: Color(0xFF0F172A)),
        ),
        title: Text(
          widget.service.subject,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Color(0xFF0F172A)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cover image
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/slide1.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),

          // TabBar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w400,
                fontSize: 13,
              ),
              labelColor: const Color(0xFF000080),
              unselectedLabelColor: const Color(0xFF94A3B8),
              indicatorColor: const Color(0xFF000080),
              indicatorWeight: 2.5,
              tabs: const [
                Tab(text: 'Sessions'),
                Tab(text: 'Resources'),
                Tab(text: 'Members'),
              ],
            ),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SessionsTab(
                  serviceId: widget.service.serviceId,
                  totalSessions: widget.service.sessionsnum,
                ),
                ResourcesTab(serviceId: widget.service.serviceId),
                MembersTab(service: widget.service),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
