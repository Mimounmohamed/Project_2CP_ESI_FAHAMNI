import 'package:fahamni/Explore_map_pages/explorepage.dart';
import 'package:fahamni/StudentHomePage/Student_homepage.dart';
import 'package:fahamni/StudentHomePage/studenthome_service.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/models/service_model.dart';
import 'package:fahamni/models/session_model.dart';
import 'package:fahamni/models/student_model.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:fahamni/widgets/customnavbar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/servicedetails.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  final studenthomepage_service _service = studenthomepage_service();
  late Future<_CoursesViewData> _coursesFuture;
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _loadCourses();
  }

  Future<_CoursesViewData> _loadCourses() async {
    final StudentModel student = await _service.getStudentData();
    final List<SessionModel> sessions = await _service.getCourses(student.Courses);
    sessions.sort((a, b) => _sessionDateTime(a).compareTo(_sessionDateTime(b)));

    final List<_CourseCardData> cards = <_CourseCardData>[];
    for (final SessionModel session in sessions) {
      final TutorModel tutor = await _service.getTutorData(session.tutorId);
      final ServiceModel? service = await _service.getServiceData(session.serviceId);
      cards.add(
        _CourseCardData(
          session: session,
          tutor: tutor,
          service: service,
        ),
      );
    }

    return _CoursesViewData(
      student: student,
      courses: cards,
    );
  }

  void _handleNavigation(int index, StudentModel student) {
    if (index == _selectedIndex) {
      return;
    }

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Studenthomepage()),
      );
      return;
    }

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Explorepage(student: student)),
      );
      return;
    }

    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatPage()),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _coursesFuture = _loadCourses();
    });
    await _coursesFuture;
  }

  DateTime _sessionDateTime(SessionModel session) {
    return DateTime(
      session.date.year,
      session.date.month,
      session.date.day,
      session.startTime.hour,
      session.startTime.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Courses',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: FutureBuilder<_CoursesViewData>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Failed to load courses.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final _CoursesViewData data = snapshot.data!;

          if (data.courses.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
                children: const [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 64,
                    color: Color(0xFF000080),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No courses yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your enrolled sessions will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              itemCount: data.courses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final _CourseCardData course = data.courses[index];
                return _CourseCard(
                  course: course,
                  onOpenService: course.service == null
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Servicedetails(
                                tutor: course.tutor,
                                service: course.service!,
                              ),
                            ),
                          );
                        },
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<_CoursesViewData>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          final StudentModel? student = snapshot.data?.student;
          return CustomBottomNavbar(
            selectedIndex: _selectedIndex,
            onTap: (index) {
              if (student == null) {
                return;
              }
              _handleNavigation(index, student);
            },
          );
        },
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.onOpenService,
  });

  final _CourseCardData course;
  final VoidCallback? onOpenService;

  @override
  Widget build(BuildContext context) {
    final SessionModel session = course.session;
    final ServiceModel? service = course.service;
    final TutorModel tutor = course.tutor;
    final String title = service?.name.isNotEmpty == true
        ? service!.name
        : service?.subject.isNotEmpty == true
            ? service!.subject
            : 'Session';
    final String subtitle = [
      if (service?.subject.isNotEmpty == true) service!.subject,
      if (service?.level.isNotEmpty == true) service!.level,
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000080).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: tutor.picture.isNotEmpty
                    ? _imageProvider(tutor.picture)
                    : null,
                child: tutor.picture.isEmpty
                    ? Text(
                        tutor.firstName.isNotEmpty
                            ? tutor.firstName[0].toUpperCase()
                            : 'T',
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${tutor.firstName} ${tutor.lastName}'.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF000080).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      session.type,
                      style: const TextStyle(
                        color: Color(0xFF000080),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _StatusBadge(status: session.status),
                ],
              ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF000080),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _CourseMetaChip(
                icon: Icons.calendar_today_outlined,
                label: DateFormat('EEE, dd MMM').format(session.date),
              ),
              _CourseMetaChip(
                icon: Icons.access_time_rounded,
                label:
                    '${DateFormat('HH:mm').format(session.startTime)} - ${DateFormat('HH:mm').format(session.endTime)}',
              ),
              _CourseMetaChip(
                icon: Icons.hourglass_bottom_rounded,
                label:
                    '${session.endTime.difference(session.startTime).inMinutes} min',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  tutor.expertiseDomain,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ),
              if (onOpenService != null)
                TextButton(
                  onPressed: onOpenService,
                  child: const Text(
                    'Open service',
                    style: TextStyle(
                      color: Color(0xFF000080),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  ImageProvider _imageProvider(String path) {
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }
    return AssetImage(path);
  }
}

class _CourseMetaChip extends StatelessWidget {
  const _CourseMetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF000080)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final SessionStatus status;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    switch (status) {
      case SessionStatus.Ongoing:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        label = 'Ongoing';
        break;
      case SessionStatus.Completed:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = 'Completed';
        break;
      case SessionStatus.Canceled:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        label = 'Canceled';
        break;
      case SessionStatus.Planned:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        label = 'Planned';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          fontSize: 11,
          color: fg,
        ),
      ),
    );
  }
}

class _CoursesViewData {
  const _CoursesViewData({
    required this.student,
    required this.courses,
  });

  final StudentModel student;
  final List<_CourseCardData> courses;
}

class _CourseCardData {
  const _CourseCardData({
    required this.session,
    required this.tutor,
    required this.service,
  });

  final SessionModel session;
  final TutorModel tutor;
  final ServiceModel? service;
}
