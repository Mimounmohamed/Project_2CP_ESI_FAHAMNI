import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fahamni/Services/session_service.dart';
import 'package:fahamni/models/service_model.dart';
import 'package:fahamni/models/session_model.dart';
import 'package:fahamni/models/student_model.dart';
import 'package:fahamni/models/user_model.dart';
import 'package:flutter/material.dart';

class DocumentsTab extends StatefulWidget {
  const DocumentsTab({
    super.key,
    required this.service,
  });

  final ServiceModel service;

  @override
  State<DocumentsTab> createState() => _DocumentsTabState();
}

class _DocumentsTabState extends State<DocumentsTab> {
  static const List<_CourseDocument> _placeholderDocuments = <_CourseDocument>[
    _CourseDocument(
      name: 'Lecture Notes - Unit 01',
      type: 'PDF',
      subtitle: 'Course handout',
      icon: Icons.picture_as_pdf_outlined,
      actionIcon: Icons.download_rounded,
    ),
    _CourseDocument(
      name: 'Session Replay - Introduction',
      type: 'Video',
      subtitle: 'Recorded explanation',
      icon: Icons.play_circle_outline_rounded,
      actionIcon: Icons.download_rounded,
    ),
    _CourseDocument(
      name: 'Practice Resource Link',
      type: 'Link',
      subtitle: 'External reference',
      icon: Icons.link_rounded,
      actionIcon: Icons.open_in_new_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_placeholderDocuments.isEmpty) {
      return const _TabEmptyState(
        icon: Icons.folder_open_rounded,
        title: 'No documents yet',
        subtitle: 'Resources linked to this course will appear here.',
      );
    }

    return Container(
      color: const Color(0xFFF9F9F9),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _placeholderDocuments.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final _CourseDocument document = _placeholderDocuments[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EEFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    document.icon,
                    color: const Color(0xFF000080),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${document.type} • ${document.subtitle}',
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${document.type} action coming soon.'),
                      ),
                    );
                  },
                  icon: Icon(
                    document.actionIcon,
                    color: const Color(0xFF000080),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class MembersTab extends StatefulWidget {
  const MembersTab({
    super.key,
    required this.service,
  });

  final ServiceModel service;

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  late Future<List<StudentModel>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = _loadMembers();
  }

  Future<List<StudentModel>> _loadMembers() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('students')
        .where('courses', arrayContains: widget.service.serviceId)
        .get();

    final List<StudentModel> students = snapshot.docs
        .map(
          (doc) => StudentModel.fromMap(
            <String, dynamic>{
              ...doc.data(),
              'uid': doc.data()['uid'] ?? doc.id,
            },
          ),
        )
        .toList();

    students.sort(
      (a, b) => '${a.firstName} ${a.lastName}'
          .toLowerCase()
          .compareTo('${b.firstName} ${b.lastName}'.toLowerCase()),
    );

    return students;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9F9F9),
      child: FutureBuilder<List<StudentModel>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF000080)),
            );
          }

          if (snapshot.hasError) {
            return const _TabEmptyState(
              icon: Icons.group_off_rounded,
              title: 'Unable to load members',
              subtitle: 'Please try again in a moment.',
            );
          }

          final List<StudentModel> members = snapshot.data ?? <StudentModel>[];
          if (members.isEmpty) {
            return Column(
              children: [
                _MembersOverviewHeader(
                  enrolled: 0,
                  max: widget.service.maxnum,
                ),
                const Expanded(
                  child: _TabEmptyState(
                    icon: Icons.groups_2_outlined,
                    title: 'No enrolled members yet',
                    subtitle: 'Students added to this course will show up here.',
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: members.length + 1,
            separatorBuilder: (_, index) =>
                index == 0 ? const SizedBox(height: 16) : const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _MembersOverviewHeader(
                  enrolled: members.length,
                  max: widget.service.maxnum,
                );
              }

              final StudentModel student = members[index - 1];
              final bool isActive = student.accountStatus == AccountStatus.validated;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: _cardDecoration(),
                child: Row(
                  children: [
                    _StudentAvatar(student: student),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${student.firstName} ${student.lastName}'.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            student.schoolLevel.isEmpty
                                ? 'Level not set'
                                : student.schoolLevel,
                            style: const TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusChip(
                      label: isActive ? 'Active' : 'Pending',
                      backgroundColor: isActive
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFFEDD5),
                      textColor: isActive
                          ? const Color(0xFF15803D)
                          : const Color(0xFFEA580C),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class SessionsTab extends StatefulWidget {
  const SessionsTab({
    super.key,
    required this.service,
    required this.student,
  });

  final ServiceModel service;
  final StudentModel student;

  @override
  State<SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends State<SessionsTab> {
  final SessionService _sessionService = SessionService();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9F9F9),
      child: StreamBuilder<List<SessionModel>>(
        stream: _sessionService.streamSessions(widget.student.uid).map(
          (sessions) => sessions
              .where((session) => session.serviceId == widget.service.serviceId)
              .toList()
            ..sort((a, b) => _sessionDateTime(a).compareTo(_sessionDateTime(b))),
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF000080)),
            );
          }

          if (snapshot.hasError) {
            return const _TabEmptyState(
              icon: Icons.event_busy_outlined,
              title: 'Unable to load sessions',
              subtitle: 'Please try again in a moment.',
            );
          }

          final List<SessionModel> allSessions = snapshot.data ?? <SessionModel>[];
          if (allSessions.isEmpty) {
            return const _TabEmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'No sessions scheduled yet',
              subtitle: 'Upcoming, live, and completed sessions will appear here.',
            );
          }

          final Map<_SessionGroup, List<SessionModel>> groupedSessions =
              <_SessionGroup, List<SessionModel>>{
            _SessionGroup.upcoming: <SessionModel>[],
            _SessionGroup.ongoing: <SessionModel>[],
            _SessionGroup.completed: <SessionModel>[],
          };

          for (final SessionModel session in allSessions) {
            groupedSessions[_groupSession(session)]!.add(session);
          }

          final List<_SessionSectionData> sections = groupedSessions.entries
              .where((entry) => entry.value.isNotEmpty)
              .map((entry) => _SessionSectionData(group: entry.key, sessions: entry.value))
              .toList()
            ..sort((a, b) => a.group.order.compareTo(b.group.order));

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(height: 20),
            itemBuilder: (context, index) {
              final _SessionSectionData section = sections[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.group.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...section.sessions.map(
                    (session) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SessionCard(session: session),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
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

  _SessionGroup _groupSession(SessionModel session) {
    switch (session.status) {
      case SessionStatus.Completed:
        return _SessionGroup.completed;
      case SessionStatus.Ongoing:
        return _SessionGroup.ongoing;
      case SessionStatus.Canceled:
        return _sessionDateTime(session).isAfter(DateTime.now())
            ? _SessionGroup.upcoming
            : _SessionGroup.completed;
      case SessionStatus.Planned:
        return _SessionGroup.upcoming;
    }
  }
}

class _MembersOverviewHeader extends StatelessWidget {
  const _MembersOverviewHeader({
    required this.enrolled,
    required this.max,
  });

  final int enrolled;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Enrolled',
            value: '$enrolled',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            label: 'Capacity',
            value: '$enrolled / $max',
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Lexend',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF000080),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
  });

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final int duration = session.endTime.difference(session.startTime).inMinutes;
    final bool isCompleted = session.status == SessionStatus.Completed;
    final bool isUpcoming = session.status == SessionStatus.Planned;
    final bool isOngoing = session.status == SessionStatus.Ongoing;

    Color statusBackground;
    Color statusText;
    String statusLabel;

    if (isCompleted) {
      statusBackground = const Color(0xFFDCFCE7);
      statusText = const Color(0xFF15803D);
      statusLabel = 'Completed';
    } else if (isOngoing) {
      statusBackground = const Color(0xFFDBEAFE);
      statusText = const Color(0xFF1D4ED8);
      statusLabel = 'Ongoing';
    } else {
      statusBackground = const Color(0xFFFFEDD5);
      statusText = const Color(0xFFEA580C);
      statusLabel = 'Upcoming';
    }

    final bool onlineMode =
        session.type.toLowerCase().contains('online') ||
        session.modality.toLowerCase().contains('online');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatDate(session.date),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF000080),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatTime(session.startTime)} - ${_formatTime(session.endTime)}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$duration min • ${session.modality}',
            style: const TextStyle(
              fontFamily: 'Lexend',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(
                label: onlineMode ? 'Online' : 'In-person',
                backgroundColor: onlineMode
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFFFEDD5),
                textColor: onlineMode
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFEA580C),
              ),
              _StatusChip(
                label: statusLabel,
                backgroundColor: statusBackground,
                textColor: statusText,
              ),
              _StatusChip(
                label: session.type.isEmpty ? 'Session' : session.type,
                backgroundColor: const Color(0xFFE2E8F0),
                textColor: const Color(0xFF334155),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StudentAvatar extends StatelessWidget {
  const _StudentAvatar({
    required this.student,
  });

  final StudentModel student;

  @override
  Widget build(BuildContext context) {
    if (student.picture.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFE2E8F0),
        backgroundImage: NetworkImage(student.picture),
      );
    }

    final bool isFemale = student.gender == Gender.female;
    return CircleAvatar(
      radius: 22,
      backgroundColor: isFemale
          ? const Color(0xFFFCE7F3)
          : const Color(0xFFDBEAFE),
      child: Icon(
        isFemale ? Icons.person_2_rounded : Icons.person_rounded,
        color: const Color(0xFF000080),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Lexend',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _TabEmptyState extends StatelessWidget {
  const _TabEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 52,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Lexend',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
      BoxShadow(
        color: Color(0x3394A3B8),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  );
}

String _formatDate(DateTime date) {
  const List<String> weekdays = <String>[
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];
  const List<String> months = <String>[
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
}

String _formatTime(DateTime time) {
  final String hour = time.hour.toString().padLeft(2, '0');
  final String minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class _CourseDocument {
  const _CourseDocument({
    required this.name,
    required this.type,
    required this.subtitle,
    required this.icon,
    required this.actionIcon,
  });

  final String name;
  final String type;
  final String subtitle;
  final IconData icon;
  final IconData actionIcon;
}

enum _SessionGroup {
  upcoming('Upcoming', 0),
  ongoing('Ongoing', 1),
  completed('Completed', 2);

  const _SessionGroup(this.title, this.order);

  final String title;
  final int order;
}

class _SessionSectionData {
  const _SessionSectionData({
    required this.group,
    required this.sessions,
  });

  final _SessionGroup group;
  final List<SessionModel> sessions;
}


