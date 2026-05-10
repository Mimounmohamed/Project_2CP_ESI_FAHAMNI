import 'package:fahamni/Explore_map_pages/explorepage.dart';
import 'package:fahamni/StudentHomePage/Student_homepage.dart';
import 'package:fahamni/StudentHomePage/studenthome_service.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/models/service_model.dart';
import 'package:fahamni/models/session_model.dart';
import 'package:fahamni/models/student_model.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:fahamni/Account_Settings_Student/account_screen.dart';
import 'package:fahamni/widgets/customnavbar.dart';
import 'package:fahamni/utils/resource_link_launcher.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fahamni/Courses/courses_page.dart';

enum _ScheduleMode { week, month, day }

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final studenthomepage_service _service = studenthomepage_service();
  late Future<_ScheduleViewData> _scheduleFuture;
  DateTime _focusedDate = DateTime.now();
  _ScheduleMode _mode = _ScheduleMode.week;
  final int _selectedIndex = -1;

  static const int _agendaStartHour = 9;
  static const int _agendaEndHour = 22;
  static const double _timeColumnWidth = 34;
  static const double _hourRowHeight = 110;
  static const double _headerHeight = 56;

  @override
  void initState() {
    super.initState();
    _scheduleFuture = _loadSchedule();
  }

  Future<_ScheduleViewData> _loadSchedule() async {
    final StudentModel student = await _service.getStudentData();
    final List<SessionModel> sessions = await _service.getCourses(
      student.Courses,
    );
    sessions.sort((a, b) => _sessionStart(a).compareTo(_sessionStart(b)));

    final List<_ScheduledSession> items = <_ScheduledSession>[];
    for (final SessionModel session in sessions) {
      TutorModel tutor;
      try {
        tutor = await _service.getTutorData(session.tutorId);
      } catch (_) {
        // Skip sessions whose tutor document is missing rather than crashing.
        continue;
      }
      final ServiceModel? service = await _service.getServiceData(
        session.serviceId,
      );
      items.add(
        _ScheduledSession(session: session, tutor: tutor, service: service),
      );
    }

    // Navigate to the nearest upcoming session's week; fall back to today.
    final DateTime now = DateTime.now();
    final _ScheduledSession? nearest = items
        .cast<_ScheduledSession?>()
        .firstWhere(
          (item) => item != null && _sessionStart(item.session).isAfter(now),
          orElse: () => items.isNotEmpty ? items.first : null,
        );
    if (nearest != null) {
      _focusedDate = _startOfWeek(_sessionStart(nearest.session));
    } else {
      _focusedDate = _startOfWeek(now);
    }

    return _ScheduleViewData(student: student, sessions: items);
  }

  Future<void> _refresh() async {
    setState(() {
      _scheduleFuture = _loadSchedule();
    });
    await _scheduleFuture;
  }

  void _goToPreviousRange() {
    setState(() {
      switch (_mode) {
        case _ScheduleMode.week:
          _focusedDate = _focusedDate.subtract(const Duration(days: 7));
          break;
        case _ScheduleMode.month:
          _focusedDate = DateTime(
            _focusedDate.year,
            _focusedDate.month - 1,
            _focusedDate.day,
          );
          break;
        case _ScheduleMode.day:
          _focusedDate = _focusedDate.subtract(const Duration(days: 1));
          break;
      }
    });
  }

  void _goToNextRange() {
    setState(() {
      switch (_mode) {
        case _ScheduleMode.week:
          _focusedDate = _focusedDate.add(const Duration(days: 7));
          break;
        case _ScheduleMode.month:
          _focusedDate = DateTime(
            _focusedDate.year,
            _focusedDate.month + 1,
            _focusedDate.day,
          );
          break;
        case _ScheduleMode.day:
          _focusedDate = _focusedDate.add(const Duration(days: 1));
          break;
      }
    });
  }

  Widget _buildModeBody(List<_ScheduledSession> sessions) {
    switch (_mode) {
      case _ScheduleMode.week:
        final List<DateTime> weekDays = _weekDaysFor(_focusedDate);
        final List<_ScheduledSession> weekSessions = sessions
            .where(
              (item) => weekDays.any(
                (day) => _isSameDay(_sessionStart(item.session), day),
              ),
            )
            .toList();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _WeekAgendaView(
            days: weekDays,
            sessions: weekSessions,
            selectedDay: _focusedDate,
            onSelectDay: (day) {
              setState(() {
                _focusedDate = day;
              });
            },
            agendaStartHour: _agendaStartHour,
            agendaEndHour: _agendaEndHour,
            timeColumnWidth: _timeColumnWidth,
            hourRowHeight: _hourRowHeight,
            headerHeight: _headerHeight,
          ),
        );
      case _ScheduleMode.month:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _MonthView(
            focusedDate: _focusedDate,
            sessions: sessions,
            onSelectDay: (day) {
              setState(() {
                _focusedDate = day;
                _mode = _ScheduleMode.day;
              });
            },
          ),
        );
      case _ScheduleMode.day:
        final List<_ScheduledSession> daySessions =
            sessions
                .where(
                  (item) =>
                      _isSameDay(_sessionStart(item.session), _focusedDate),
                )
                .toList()
              ..sort(
                (a, b) => _sessionStart(
                  a.session,
                ).compareTo(_sessionStart(b.session)),
              );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _DayView(
            date: _focusedDate,
            sessions: daySessions,
            agendaStartHour: _agendaStartHour,
            agendaEndHour: _agendaEndHour,
            timeColumnWidth: _timeColumnWidth,
            hourRowHeight: _hourRowHeight,
          ),
        );
    }
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

    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CoursesPage()),
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
        MaterialPageRoute(builder: (_) => const AccountScreen()),
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<_ScheduleViewData>(
          future: _scheduleFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _ScheduleMessageState(
                title: 'Failed to load schedule',
                subtitle: snapshot.error.toString(),
                actionLabel: 'Retry',
                onAction: _refresh,
              );
            }

            final _ScheduleViewData data = snapshot.data!;
            if (data.sessions.isEmpty) {
              return _ScheduleMessageState(
                title: 'No sessions yet',
                subtitle: 'Booked sessions will appear here in agenda form.',
                actionLabel: 'Refresh',
                onAction: _refresh,
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: _ScheduleHeader(
                    focusedDate: _focusedDate,
                    mode: _mode,
                    onBack: () => Navigator.maybePop(context),
                    onPreviousWeek: _goToPreviousRange,
                    onNextWeek: _goToNextRange,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _ModeSwitcher(
                    mode: _mode,
                    onChanged: (mode) {
                      setState(() {
                        _mode = mode;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(child: _buildModeBody(data.sessions)),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: FutureBuilder<_ScheduleViewData>(
        future: _scheduleFuture,
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

  static DateTime _sessionStart(SessionModel session) => DateTime(
    session.date.year,
    session.date.month,
    session.date.day,
    session.startTime.hour,
    session.startTime.minute,
  );

  static DateTime _sessionEnd(SessionModel session) => DateTime(
    session.date.year,
    session.date.month,
    session.date.day,
    session.endTime.hour,
    session.endTime.minute,
  );

  static DateTime _stripTime(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _startOfWeek(DateTime date) {
    final DateTime normalized = _stripTime(date);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  static List<DateTime> _weekDaysFor(DateTime date) {
    final DateTime start = _startOfWeek(date);
    return List<DateTime>.generate(
      7,
      (index) => start.add(Duration(days: index)),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({
    required this.focusedDate,
    required this.mode,
    required this.onBack,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  final DateTime focusedDate;
  final _ScheduleMode mode;
  final VoidCallback onBack;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: onBack,
                  child: const Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 24,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ),
              const Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _OutlinedCircleArrow(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onPreviousWeek,
            ),
            const SizedBox(width: 12),
            Text(
              switch (mode) {
                _ScheduleMode.week => DateFormat(
                  'dd MMMM yyyy',
                ).format(focusedDate),
                _ScheduleMode.month => DateFormat(
                  'MMMM yyyy',
                ).format(focusedDate),
                _ScheduleMode.day => DateFormat(
                  'dd MMMM yyyy',
                ).format(focusedDate),
              },
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(width: 12),
            _OutlinedCircleArrow(
              icon: Icons.arrow_forward_ios_rounded,
              onTap: onNextWeek,
            ),
          ],
        ),
      ],
    );
  }
}

class _OutlinedCircleArrow extends StatelessWidget {
  const _OutlinedCircleArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF374151), width: 1.6),
        ),
        child: Icon(icon, size: 14, color: const Color(0xFF374151)),
      ),
    );
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({required this.mode, required this.onChanged});

  final _ScheduleMode mode;
  final ValueChanged<_ScheduleMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: _ScheduleMode.values.map((item) {
          final bool selected = item == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF000080)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  switch (item) {
                    _ScheduleMode.week => 'Week',
                    _ScheduleMode.month => 'Month',
                    _ScheduleMode.day => 'Day',
                  },
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _WeekAgendaView extends StatelessWidget {
  const _WeekAgendaView({
    required this.days,
    required this.sessions,
    required this.selectedDay,
    required this.onSelectDay,
    required this.agendaStartHour,
    required this.agendaEndHour,
    required this.timeColumnWidth,
    required this.hourRowHeight,
    required this.headerHeight,
  });

  final List<DateTime> days;
  final List<_ScheduledSession> sessions;
  final DateTime selectedDay;
  final ValueChanged<DateTime> onSelectDay;
  final int agendaStartHour;
  final int agendaEndHour;
  final double timeColumnWidth;
  final double hourRowHeight;
  final double headerHeight;

  @override
  Widget build(BuildContext context) {
    final int totalHours = agendaEndHour - agendaStartHour;
    final double timelineHeight = totalHours * hourRowHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableWidth = constraints.maxWidth - timeColumnWidth;
        final double dayColumnWidth = availableWidth / days.length;
        final int selectedIndex = days
            .indexWhere(
              (day) => _SchedulePageState._isSameDay(day, selectedDay),
            )
            .clamp(0, days.length - 1);

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SizedBox(
            height: headerHeight + timelineHeight + 24,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: timeColumnWidth + (selectedIndex * dayColumnWidth),
                  child: Container(
                    width: dayColumnWidth,
                    height: headerHeight + timelineHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFEEEAFE).withValues(alpha: 0),
                          const Color(0xFFEEEAFE).withValues(alpha: 0.48),
                          const Color(0xFFEEEAFE).withValues(alpha: 0.82),
                          const Color(0xFFEEEAFE).withValues(alpha: 1),
                        ],
                        stops: const [0, 0.18, 0.45, 1],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: timeColumnWidth,
                  right: 0,
                  height: headerHeight,
                  child: Row(
                    children: days.asMap().entries.map((entry) {
                      final DateTime day = entry.value;
                      final bool selected = entry.key == selectedIndex;
                      return SizedBox(
                        width: dayColumnWidth,
                        child: GestureDetector(
                          onTap: () => onSelectDay(day),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFEEEAFE)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${day.day}',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('EEE').format(day),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Positioned(
                  top: headerHeight,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: timelineHeight,
                    child: Column(
                      children: List<Widget>.generate(totalHours, (index) {
                        return Container(
                          height: hourRowHeight,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Color(0xFFE5E7EB),
                                width: 1,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Positioned(
                  top: headerHeight,
                  left: 0,
                  width: timeColumnWidth,
                  child: Column(
                    children: List<Widget>.generate(totalHours, (index) {
                      final int hour = agendaStartHour + index;
                      return SizedBox(
                        height: hourRowHeight,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            DateFormat(
                              'hh a',
                            ).format(DateTime(2026, 1, 1, hour)),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                ...days.asMap().entries.map((entry) {
                  final int dayIndex = entry.key;
                  final DateTime day = entry.value;
                  final List<_ScheduledSession> daySessions =
                      sessions
                          .where(
                            (item) => _SchedulePageState._isSameDay(
                              _SchedulePageState._sessionStart(item.session),
                              day,
                            ),
                          )
                          .toList()
                        ..sort(
                          (a, b) => _SchedulePageState._sessionStart(a.session)
                              .compareTo(
                                _SchedulePageState._sessionStart(b.session),
                              ),
                        );

                  return Positioned(
                    top: headerHeight,
                    left: timeColumnWidth + (dayIndex * dayColumnWidth) + 4,
                    width: dayColumnWidth - 8,
                    height: timelineHeight,
                    child: Stack(
                      children: daySessions.asMap().entries.map((itemEntry) {
                        final int position = itemEntry.key;
                        final _ScheduledSession item = itemEntry.value;
                        final DateTime start = _SchedulePageState._sessionStart(
                          item.session,
                        );
                        final DateTime end = _SchedulePageState._sessionEnd(
                          item.session,
                        );
                        final double top =
                            ((start.hour + (start.minute / 60)) -
                                agendaStartHour) *
                            hourRowHeight;
                        final double height =
                            (end.difference(start).inMinutes / 60) *
                            hourRowHeight;

                        return Positioned(
                          top: top,
                          left: 0,
                          right: 0,
                          height: height,
                          child: _ScheduleSessionCard(
                            item: item,
                            palette: _paletteForSession(
                              item,
                              fallbackIndex: position,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.focusedDate,
    required this.sessions,
    required this.onSelectDay,
  });

  final DateTime focusedDate;
  final List<_ScheduledSession> sessions;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final DateTime monthStart = DateTime(
      focusedDate.year,
      focusedDate.month,
      1,
    );
    final DateTime gridStart = monthStart.subtract(
      Duration(days: monthStart.weekday - 1),
    );
    final List<DateTime> days = List<DateTime>.generate(
      35,
      (index) => gridStart.add(Duration(days: index)),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: const [
              SizedBox(width: 6),
              Expanded(
                child: Center(
                  child: Text('Mon', style: _MonthWeekdayStyle.textStyle),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('Tue', style: _MonthWeekdayStyle.textStyle),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('Wed', style: _MonthWeekdayStyle.textStyle),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('Thu', style: _MonthWeekdayStyle.textStyle),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('Fri', style: _MonthWeekdayStyle.textStyle),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('Sat', style: _MonthWeekdayStyle.textStyle),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text('Sun', style: _MonthWeekdayStyle.textStyle),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.58,
            ),
            itemBuilder: (context, index) {
              final DateTime day = days[index];
              final bool inMonth = day.month == focusedDate.month;
              final bool selected = _SchedulePageState._isSameDay(
                day,
                focusedDate,
              );
              final List<_ScheduledSession> daySessions = sessions
                  .where(
                    (item) => _SchedulePageState._isSameDay(
                      _SchedulePageState._sessionStart(item.session),
                      day,
                    ),
                  )
                  .toList();

              return GestureDetector(
                onTap: () => onSelectDay(day),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFEEEAFE)
                        : inMonth
                        ? const Color(0xFFF9FAFB)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: inMonth
                              ? const Color(0xFF111827)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...daySessions.take(3).toList().asMap().entries.map((
                        entry,
                      ) {
                        final _ScheduledSession item = entry.value;
                        final _EventPalette palette = _paletteForSession(
                          item,
                          fallbackIndex: entry.key,
                        );
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          height: 12,
                          decoration: BoxDecoration(
                            color: palette.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MonthWeekdayStyle {
  static const TextStyle textStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xFF9CA3AF),
  );
}

class _DayView extends StatelessWidget {
  const _DayView({
    required this.date,
    required this.sessions,
    required this.agendaStartHour,
    required this.agendaEndHour,
    required this.timeColumnWidth,
    required this.hourRowHeight,
  });

  final DateTime date;
  final List<_ScheduledSession> sessions;
  final int agendaStartHour;
  final int agendaEndHour;
  final double timeColumnWidth;
  final double hourRowHeight;

  @override
  Widget build(BuildContext context) {
    final int totalHours = agendaEndHour - agendaStartHour;
    final double timelineHeight = totalHours * hourRowHeight;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFEEEAFE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('dd').format(date),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                DateFormat('EEEE').format(date),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: timelineHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Column(
                      children: List<Widget>.generate(totalHours, (index) {
                        return Container(
                          height: hourRowHeight,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    width: timeColumnWidth,
                    child: Column(
                      children: List<Widget>.generate(totalHours, (index) {
                        final int hour = agendaStartHour + index;
                        return SizedBox(
                          height: hourRowHeight,
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              DateFormat(
                                'hh a',
                              ).format(DateTime(2026, 1, 1, hour)),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  Positioned(
                    left: timeColumnWidth + 10,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Stack(
                      children: sessions.asMap().entries.map((entry) {
                        final _ScheduledSession item = entry.value;
                        final DateTime start = _SchedulePageState._sessionStart(
                          item.session,
                        );
                        final DateTime end = _SchedulePageState._sessionEnd(
                          item.session,
                        );
                        final double top =
                            ((start.hour + (start.minute / 60)) -
                                agendaStartHour) *
                            hourRowHeight;
                        final double height =
                            (end.difference(start).inMinutes / 60) *
                            hourRowHeight;
                        return Positioned(
                          top: top,
                          left: 0,
                          right: 0,
                          height: height,
                          child: _ScheduleSessionCard(
                            item: item,
                            palette: _paletteForSession(
                              item,
                              fallbackIndex: entry.key,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleSessionCard extends StatelessWidget {
  const _ScheduleSessionCard({required this.item, required this.palette});

  final _ScheduledSession item;
  final _EventPalette palette;

  bool get _isOnlineSession => item.isOnlineSession;

  Future<void> _openSessionLink(BuildContext context) async {
    final String link = item.session.meetingLink.trim();
    if (link.isEmpty) {
      return;
    }

    final bool opened = await launchResourceLink(link);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the session link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isOnlineSession ? () => _openSessionLink(context) : null,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        decoration: BoxDecoration(
          color: palette.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.shortTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.roomLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleMessageState extends StatelessWidget {
  const _ScheduleMessageState({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Color(0xFF000080),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleViewData {
  const _ScheduleViewData({required this.student, required this.sessions});

  final StudentModel student;
  final List<_ScheduledSession> sessions;
}

class _ScheduledSession {
  const _ScheduledSession({
    required this.session,
    required this.tutor,
    required this.service,
  });

  final SessionModel session;
  final TutorModel tutor;
  final ServiceModel? service;

  String get title {
    if (service?.name.isNotEmpty == true) {
      return service!.name;
    }
    if (service?.subject.isNotEmpty == true) {
      return service!.subject;
    }
    if (tutor.expertiseDomain.isNotEmpty) {
      return tutor.expertiseDomain;
    }
    return 'Session';
  }

  String get shortTitle {
    final List<String> parts = title.split(RegExp(r'\s+'));
    if (parts.length <= 2) {
      return title;
    }
    return parts.take(2).join('\n');
  }

  String get roomLabel {
    if (isOnlineSession) {
      return session.meetingLink.isNotEmpty
          ? 'Open session link'
          : 'Online session';
    }
    if (service?.area.isNotEmpty == true) {
      return service!.area;
    }
    return 'Room 101';
  }

  bool get isOnlineSession {
    final String mode = session.mode.toLowerCase();
    final String type = session.type.toLowerCase();
    final String modality = session.modality.toLowerCase();

    return mode == 'online' || type == 'online' || modality == 'online';
  }
}

class _EventPalette {
  const _EventPalette({required this.primary});

  final Color primary;
}

_EventPalette _paletteForSession(
  _ScheduledSession item, {
  required int fallbackIndex,
}) {
  final String seed = item.title.toLowerCase();
  if (seed.contains('org') ||
      seed.contains('management') ||
      seed.contains('mgt')) {
    return const _EventPalette(primary: Color(0xFFE2C83D));
  }
  if (seed.contains('macro')) {
    return const _EventPalette(primary: Color(0xFF3730C7));
  }
  if (seed.contains('micro')) {
    return const _EventPalette(primary: Color(0xFFB14FE6));
  }
  if (seed.contains('financial') || seed.contains('finance')) {
    return const _EventPalette(primary: Color(0xFF5F71F1));
  }

  const List<_EventPalette> palettes = <_EventPalette>[
    _EventPalette(primary: Color(0xFFE2C83D)),
    _EventPalette(primary: Color(0xFF5F71F1)),
    _EventPalette(primary: Color(0xFFB14FE6)),
    _EventPalette(primary: Color(0xFF3730C7)),
  ];
  return palettes[fallbackIndex % palettes.length];
}
