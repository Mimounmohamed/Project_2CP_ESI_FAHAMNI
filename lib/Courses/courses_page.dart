import 'package:fahamni/Explore_map_pages/explorepage.dart';
import 'package:fahamni/StudentHomePage/Student_homepage.dart';
import 'package:fahamni/StudentHomePage/studenthome_service.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/models/service_model.dart';
import 'package:fahamni/models/session_model.dart';
import 'package:fahamni/models/student_model.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:fahamni/student_profile/student_account_page.dart';
import 'package:fahamni/widgets/customnavbar.dart';
import 'package:flutter/material.dart';

import '../widgets/servicedetails.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

enum _CourseFilter { all, inProgress, done }

class _CoursesPageState extends State<CoursesPage> {
  final studenthomepage_service _service = studenthomepage_service();
  late Future<_CoursesViewData> _coursesFuture;
  int _selectedIndex = 2;
  _CourseFilter _filter = _CourseFilter.all;

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

    if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentAccountPage()),
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
      backgroundColor: Colors.white,
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
          final List<_CourseCardData> visibleCourses = data.courses.where((course) {
            switch (_filter) {
              case _CourseFilter.all:
                return true;
              case _CourseFilter.inProgress:
                return course.session.status == SessionStatus.Ongoing ||
                    course.session.status == SessionStatus.Planned;
              case _CourseFilter.done:
                return course.session.status == SessionStatus.Completed;
            }
          }).toList();

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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 120),
              children: [
                const Center(
                  child: Text(
                    'Courses',
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _FilterPill(
                        label: 'All',
                        selected: _filter == _CourseFilter.all,
                        onTap: () => setState(() => _filter = _CourseFilter.all),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FilterPill(
                        label: 'In Progress',
                        selected: _filter == _CourseFilter.inProgress,
                        onTap: () => setState(() => _filter = _CourseFilter.inProgress),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FilterPill(
                        label: 'Done',
                        selected: _filter == _CourseFilter.done,
                        onTap: () => setState(() => _filter = _CourseFilter.done),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (visibleCourses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Text(
                      'No courses match this filter.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  ...visibleCourses.map((course) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _CourseCard(
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
                      ),
                    );
                  }),
              ],
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
    final String subjectLabel =
        service?.subject.isNotEmpty == true ? service!.subject.toUpperCase() : 'COURSE';
    final String tutorLabel =
        'Prof. ${tutor.firstName} ${tutor.lastName}'.trim();
    final String sessionsLabel =
        '${service?.sessionsnum ?? 1} ${service?.sessionsnum == 1 ? 'Session' : 'Sessions'}';
    final String durationLabel =
        '${service?.duration ?? session.endTime.difference(session.startTime).inMinutes} min session';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8DFF0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000080).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 135,
              width: double.infinity,
              child: Image(
                image: _courseCoverImage(service),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFF1F5A4E),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEBFF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    subjectLabel,
                    style: const TextStyle(
                      color: Color(0xFF000080),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage:
                          tutor.picture.isNotEmpty ? _imageProvider(tutor.picture) : null,
                      child: tutor.picture.isEmpty
                          ? Text(
                              tutor.firstName.isNotEmpty
                                  ? tutor.firstName[0].toUpperCase()
                                  : 'T',
                              style: const TextStyle(fontSize: 10),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tutorLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF7B8BA7),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _CourseStatRow(
                  icon: Icons.access_time_rounded,
                  label: durationLabel,
                ),
                const SizedBox(height: 8),
                _CourseStatRow(
                  icon: Icons.calendar_month_outlined,
                  label: sessionsLabel,
                ),
              ],
            ),
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

  ImageProvider _courseCoverImage(ServiceModel? service) {
    if (service?.picture.isNotEmpty == true) {
      return _imageProvider(service!.picture);
    }
    return const AssetImage('assets/images/slide0.png');
  }
}

class _CourseStatRow extends StatelessWidget {
  const _CourseStatRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF6F82A7)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6F82A7),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF000080) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF000080) : const Color(0xFFD5DDEA),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF374151),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
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
