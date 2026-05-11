import 'package:fahamni/StudentHomePage/studenthome_service.dart';
import 'package:fahamni/Account_Settings_Parent/account_screen.dart';
import 'package:fahamni/ParentDashboread/ParentHomePage/home_page.dart';
import 'package:fahamni/ParentDashboread/ParentExplorePage/parent_explore_page.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/models/service_model.dart';
import 'package:fahamni/models/session_model.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:fahamni/models/child_model.dart';
import 'package:fahamni/widgets/customnavbar.dart';
import 'package:flutter/material.dart';

import 'package:fahamni/Courses/student_course_details_page.dart';
import 'package:fahamni/Services/parent_child_service.dart';

class ParentCoursesPage extends StatefulWidget {
  const ParentCoursesPage({super.key});

  @override
  State<ParentCoursesPage> createState() => _ParentCoursesPageState();
}

enum _CourseFilter { all, inProgress, done }

class _ParentCoursesPageState extends State<ParentCoursesPage> {
  final studenthomepage_service _service = studenthomepage_service();
  final ParentChildService _childService = ParentChildService();
  late Future<_CoursesViewData> _coursesFuture;
  List<ChildModel> _children = <ChildModel>[];
  ChildModel? _selectedChild;
  int _selectedIndex = 2;
  _CourseFilter _filter = _CourseFilter.all;

  @override
  void initState() {
    super.initState();
    _coursesFuture = _loadCourses();
  }

  Future<_CoursesViewData> _loadCourses({String? childId}) async {
    _children = await _childService.fetchLinkedChildren();
    final String? selectedChildId = childId ?? _selectedChild?.id;
    ChildModel? child;

    if (_children.isNotEmpty) {
      child = selectedChildId == null
          ? _children.first
          : _children.firstWhere(
              (c) => c.id == selectedChildId,
              orElse: () => _children.first,
            );
      _selectedChild = child;
    }

    if (child == null) {
      return _CoursesViewData(student: null, courses: <_CourseCardData>[]);
    }

    final List<SessionModel> sessions = await _service.getCourses(
      <String>[],
      studentId: child.id,
    );
    sessions.sort((a, b) => _sessionDateTime(a).compareTo(_sessionDateTime(b)));

    final List<_CourseCardData> cards = <_CourseCardData>[];
    for (final SessionModel session in sessions) {
      final TutorModel tutor = await _service.getTutorData(session.tutorId);
      final ServiceModel? service = await _service.getServiceData(
        session.serviceId,
      );
      cards.add(
        _CourseCardData(session: session, tutor: tutor, service: service),
      );
    }

    final Map<String, _CourseCardData> byService = {};
    final DateTime now = DateTime.now();
    for (final _CourseCardData card in cards) {
      final String key = card.session.serviceId.isNotEmpty
          ? card.session.serviceId
          : card.session.sessionId;
      if (!byService.containsKey(key)) {
        byService[key] = card;
      } else {
        final DateTime existing = _sessionDateTime(byService[key]!.session);
        final DateTime candidate = _sessionDateTime(card.session);
        final bool candidateUpcoming = candidate.isAfter(now);
        final bool existingUpcoming = existing.isAfter(now);
        if (candidateUpcoming &&
            (!existingUpcoming || candidate.isBefore(existing))) {
          byService[key] = card;
        }
      }
    }

    final List<_CourseCardData> deduped = byService.values.toList()
      ..sort(
        (a, b) =>
            _sessionDateTime(a.session).compareTo(_sessionDateTime(b.session)),
      );

    return _CoursesViewData(student: child, courses: deduped);
  }

  void _handleNavigation(int index) {
    if (index == _selectedIndex) return;
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
        MaterialPageRoute(builder: (_) => const ParentAccountScreen()),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _coursesFuture = _loadCourses(childId: _selectedChild?.id);
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

  void _onChildChanged(ChildModel? child) {
    setState(() {
      _selectedChild = child;
      _coursesFuture = _loadCourses(childId: child?.id);
    });
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
          final List<_CourseCardData> visibleCourses = data.courses.where((
            course,
          ) {
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
                const SizedBox(height: 12),
                // Child selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _ChildSelector(
                    children: _children,
                    selectedChild: _selectedChild,
                    onChanged: _onChildChanged,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _FilterPill(
                        label: 'All',
                        selected: _filter == _CourseFilter.all,
                        onTap: () =>
                            setState(() => _filter = _CourseFilter.all),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FilterPill(
                        label: 'In Progress',
                        selected: _filter == _CourseFilter.inProgress,
                        onTap: () =>
                            setState(() => _filter = _CourseFilter.inProgress),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _FilterPill(
                        label: 'Done',
                        selected: _filter == _CourseFilter.done,
                        onTap: () =>
                            setState(() => _filter = _CourseFilter.done),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (data.courses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Column(
                      children: [
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
                  )
                else if (visibleCourses.isEmpty)
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
                                    builder: (_) => StudentCourseDetailsPage(
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
          final ChildModel? student = snapshot.data?.student;
          return CustomBottomNavbar(
            selectedIndex: _selectedIndex,
            onTap: (index) {
              if (student == null) {
                return;
              }
              _handleNavigation(index);
            },
          );
        },
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onOpenService});

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

    final String subjectLabel = service?.subject.isNotEmpty == true
        ? service!.subject.toUpperCase()
        : 'COURSE';
    final String tutorLabel = 'Prof. ${tutor.firstName} ${tutor.lastName}'
        .trim();
    final String sessionsLabel =
        '${service?.sessionsnum ?? 1} ${service?.sessionsnum == 1 ? 'Session' : 'Sessions'}';
    final String durationLabel =
        '${service?.duration ?? session.endTime.difference(session.startTime).inMinutes} min session';

    return GestureDetector(
      onTap: onOpenService,
      child: Container(
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
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
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
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          subjectLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tutorLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        sessionsLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        durationLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

ImageProvider<Object> _courseCoverImage(ServiceModel? service) {
  if (service == null) return const AssetImage('assets/images/book.png');
  if (service.picture.isNotEmpty) return NetworkImage(service.picture);
  return const AssetImage('assets/images/book.png');
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
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF000080) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontFamily: "Nunito",
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

class _CourseCardData {
  final SessionModel session;
  final TutorModel tutor;
  final ServiceModel? service;

  _CourseCardData({
    required this.session,
    required this.tutor,
    required this.service,
  });
}

class _CoursesViewData {
  final ChildModel? student;
  final List<_CourseCardData> courses;

  _CoursesViewData({required this.student, required this.courses});
}

class _ChildSelector extends StatelessWidget {
  const _ChildSelector({
    required this.children,
    required this.selectedChild,
    required this.onChanged,
  });

  final List<ChildModel> children;
  final ChildModel? selectedChild;
  final ValueChanged<ChildModel?> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool hasChildren = children.isNotEmpty;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000080).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ChildModel>(
          value: selectedChild,
          isExpanded: true,
          hint: Text(
            hasChildren ? 'Select Child' : 'No linked children',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF6B7280),
          ),
          items: children
              .map(
                (child) => DropdownMenuItem<ChildModel>(
                  value: child,
                  child: Text(
                    child.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: hasChildren ? onChanged : null,
        ),
      ),
    );
  }
}
