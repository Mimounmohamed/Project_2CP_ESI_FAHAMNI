import 'package:fahamni/TeacherDashboard/teacher_dashboard.dart';
import 'package:fahamni/TeacherDashboard/teacher_dashboard_service.dart';
import 'package:fahamni/TeacherDashboard/teacher_services_dashboard.dart';
import 'package:fahamni/TeacherDashboard/widgets/teacher_navbar.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/models/teacher_schedule_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum _TeacherScheduleMode { week, month, day }

class TeacherSchedulePage extends StatefulWidget {
  const TeacherSchedulePage({super.key});

  @override
  State<TeacherSchedulePage> createState() => _TeacherSchedulePageState();
}

class _TeacherSchedulePageState extends State<TeacherSchedulePage> {
  late Future<TeacherScheduleModel> _scheduleFuture;
  DateTime _focusedDate = DateTime.now();
  _TeacherScheduleMode _mode = _TeacherScheduleMode.week;
  int _selectedNavIndex = 0;

  static const Color _pageBackground = Colors.white;
  static const int _agendaStartHour = 8;
  static const int _agendaEndHour = 22;
  static const double _timeColumnWidth = 34;
  static const double _hourRowHeight = 110;
  static const double _headerHeight = 56;

  @override
  void initState() {
    super.initState();
    _scheduleFuture = _loadSchedule();
  }

  Future<TeacherScheduleModel> _loadSchedule() async {
    final TeacherScheduleModel schedule =
        await TeacherDashboardService().loadSchedule(days: 90);
    if (schedule.days.isNotEmpty) {
      _focusedDate = _startOfWeek(schedule.days.first.date);
    }
    return schedule;
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
        case _TeacherScheduleMode.week:
          _focusedDate = _focusedDate.subtract(const Duration(days: 7));
          break;
        case _TeacherScheduleMode.month:
          _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1, 1);
          break;
        case _TeacherScheduleMode.day:
          _focusedDate = _focusedDate.subtract(const Duration(days: 1));
          break;
      }
    });
  }

  void _goToNextRange() {
    setState(() {
      switch (_mode) {
        case _TeacherScheduleMode.week:
          _focusedDate = _focusedDate.add(const Duration(days: 7));
          break;
        case _TeacherScheduleMode.month:
          _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1, 1);
          break;
        case _TeacherScheduleMode.day:
          _focusedDate = _focusedDate.add(const Duration(days: 1));
          break;
      }
    });
  }

  void _handleNavigation(int index) {
    if (index == _selectedNavIndex) {
      return;
    }

    setState(() {
      _selectedNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
        );
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TeacherServicesDashboardScreen()),
        );
        break;
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChatPage()),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher profile is coming soon.')),
        );
    }
  }

  Widget _buildModeBody(List<_TeacherScheduledSession> sessions) {
    switch (_mode) {
      case _TeacherScheduleMode.week:
        final List<DateTime> weekDays = _weekDaysFor(_focusedDate);
        final List<_TeacherScheduledSession> weekSessions = sessions
            .where((item) => weekDays.any((day) => _isSameDay(item.start, day)))
            .toList();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _TeacherWeekAgendaView(
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
      case _TeacherScheduleMode.month:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _TeacherMonthView(
            focusedDate: _focusedDate,
            sessions: sessions,
            onSelectDay: (day) {
              setState(() {
                _focusedDate = day;
                _mode = _TeacherScheduleMode.day;
              });
            },
          ),
        );
      case _TeacherScheduleMode.day:
        final List<_TeacherScheduledSession> daySessions = sessions
            .where((item) => _isSameDay(item.start, _focusedDate))
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: _TeacherDayView(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      bottomNavigationBar: TeacherNavbar(
        selectedIndex: _selectedNavIndex,
        onTap: _handleNavigation,
      ),
      body: SafeArea(
        child: FutureBuilder<TeacherScheduleModel>(
          future: _scheduleFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _TeacherScheduleMessageState(
                title: 'Failed to load schedule',
                subtitle: snapshot.error.toString(),
                actionLabel: 'Retry',
                onAction: _refresh,
              );
            }

            final TeacherScheduleModel schedule = snapshot.data!;
            final List<_TeacherScheduledSession> sessions = schedule.days
                .expand((day) => day.sessions)
                .map((session) => _TeacherScheduledSession(session: session))
                .toList()
              ..sort((a, b) => a.start.compareTo(b.start));

            if (sessions.isEmpty) {
              return _TeacherScheduleMessageState(
                title: 'No sessions yet',
                subtitle: 'Your teaching sessions will appear here in agenda form.',
                actionLabel: 'Refresh',
                onAction: _refresh,
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: _TeacherScheduleHeader(
                    title: schedule.title,
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
                  child: _TeacherModeSwitcher(
                    mode: _mode,
                    onChanged: (mode) {
                      setState(() {
                        _mode = mode;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: _buildModeBody(sessions),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static DateTime _stripTime(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _startOfWeek(DateTime date) {
    final DateTime normalized = _stripTime(date);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  static List<DateTime> _weekDaysFor(DateTime date) {
    final DateTime start = _startOfWeek(date);
    return List<DateTime>.generate(7, (index) => start.add(Duration(days: index)));
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _TeacherScheduleHeader extends StatelessWidget {
  const _TeacherScheduleHeader({
    required this.title,
    required this.focusedDate,
    required this.mode,
    required this.onBack,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  final String title;
  final DateTime focusedDate;
  final _TeacherScheduleMode mode;
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TeacherOutlinedCircleArrow(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onPreviousWeek,
            ),
            const SizedBox(width: 12),
            Text(
              switch (mode) {
                _TeacherScheduleMode.week => DateFormat('dd MMMM yyyy').format(focusedDate),
                _TeacherScheduleMode.month => DateFormat('MMMM yyyy').format(focusedDate),
                _TeacherScheduleMode.day => DateFormat('dd MMMM yyyy').format(focusedDate),
              },
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(width: 12),
            _TeacherOutlinedCircleArrow(
              icon: Icons.arrow_forward_ios_rounded,
              onTap: onNextWeek,
            ),
          ],
        ),
      ],
    );
  }
}

class _TeacherOutlinedCircleArrow extends StatelessWidget {
  const _TeacherOutlinedCircleArrow({
    required this.icon,
    required this.onTap,
  });

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

class _TeacherModeSwitcher extends StatelessWidget {
  const _TeacherModeSwitcher({
    required this.mode,
    required this.onChanged,
  });

  final _TeacherScheduleMode mode;
  final ValueChanged<_TeacherScheduleMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: _TeacherScheduleMode.values.map((item) {
          final bool selected = item == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF000080) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  switch (item) {
                    _TeacherScheduleMode.week => 'Week',
                    _TeacherScheduleMode.month => 'Month',
                    _TeacherScheduleMode.day => 'Day',
                  },
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : const Color(0xFF6B7280),
                    fontFamily: 'Nunito',
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

class _TeacherWeekAgendaView extends StatelessWidget {
  const _TeacherWeekAgendaView({
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
  final List<_TeacherScheduledSession> sessions;
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
        final int selectedIndex =
            days.indexWhere((day) => _TeacherSchedulePageState._isSameDay(day, selectedDay))
                .clamp(0, days.length - 1);

        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                              color: selected ? const Color(0xFFEEEAFE) : Colors.transparent,
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
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('EEE').format(day),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6B7280),
                                    fontFamily: 'Nunito',
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
                            DateFormat('hh a').format(DateTime(2026, 1, 1, hour)),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF9CA3AF),
                              fontFamily: 'Nunito',
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
                  final List<_TeacherScheduledSession> daySessions = sessions
                      .where((item) => _TeacherSchedulePageState._isSameDay(item.start, day))
                      .toList()
                    ..sort((a, b) => a.start.compareTo(b.start));

                  return Positioned(
                    top: headerHeight,
                    left: timeColumnWidth + (dayIndex * dayColumnWidth) + 4,
                    width: dayColumnWidth - 8,
                    height: timelineHeight,
                    child: Stack(
                      children: daySessions.asMap().entries.map((itemEntry) {
                        final int position = itemEntry.key;
                        final _TeacherScheduledSession item = itemEntry.value;
                        final double top = ((item.start.hour + (item.start.minute / 60)) -
                                agendaStartHour) *
                            hourRowHeight;
                        final double height =
                            (item.end.difference(item.start).inMinutes / 60) *
                                hourRowHeight;

                        return Positioned(
                          top: top,
                          left: 0,
                          right: 0,
                          height: height,
                          child: _TeacherAgendaSessionCard(
                            item: item,
                            palette: _teacherPaletteForSession(
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

class _TeacherMonthView extends StatelessWidget {
  const _TeacherMonthView({
    required this.focusedDate,
    required this.sessions,
    required this.onSelectDay,
  });

  final DateTime focusedDate;
  final List<_TeacherScheduledSession> sessions;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final DateTime monthStart = DateTime(focusedDate.year, focusedDate.month, 1);
    final DateTime gridStart =
        monthStart.subtract(Duration(days: monthStart.weekday - 1));
    final List<DateTime> days =
        List<DateTime>.generate(35, (index) => gridStart.add(Duration(days: index)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: const [
              SizedBox(width: 6),
              Expanded(child: Center(child: Text('Mon', style: _TeacherMonthWeekdayStyle.textStyle))),
              Expanded(child: Center(child: Text('Tue', style: _TeacherMonthWeekdayStyle.textStyle))),
              Expanded(child: Center(child: Text('Wed', style: _TeacherMonthWeekdayStyle.textStyle))),
              Expanded(child: Center(child: Text('Thu', style: _TeacherMonthWeekdayStyle.textStyle))),
              Expanded(child: Center(child: Text('Fri', style: _TeacherMonthWeekdayStyle.textStyle))),
              Expanded(child: Center(child: Text('Sat', style: _TeacherMonthWeekdayStyle.textStyle))),
              Expanded(child: Center(child: Text('Sun', style: _TeacherMonthWeekdayStyle.textStyle))),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
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
              final bool selected = _TeacherSchedulePageState._isSameDay(day, focusedDate);
              final List<_TeacherScheduledSession> daySessions = sessions
                  .where((item) => _TeacherSchedulePageState._isSameDay(item.start, day))
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
                          fontFamily: 'Inter',
                          color: inMonth
                              ? const Color(0xFF111827)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...daySessions.take(3).toList().asMap().entries.map((entry) {
                        final _TeacherScheduledSession item = entry.value;
                        final _TeacherEventPalette palette =
                            _teacherPaletteForSession(item, fallbackIndex: entry.key);
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

class _TeacherMonthWeekdayStyle {
  static const TextStyle textStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: Color(0xFF9CA3AF),
    fontFamily: 'Nunito',
  );
}

class _TeacherDayView extends StatelessWidget {
  const _TeacherDayView({
    required this.date,
    required this.sessions,
    required this.agendaStartHour,
    required this.agendaEndHour,
    required this.timeColumnWidth,
    required this.hourRowHeight,
  });

  final DateTime date;
  final List<_TeacherScheduledSession> sessions;
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
                  fontFamily: 'Inter',
                ),
              ),
              Text(
                DateFormat('EEEE').format(date),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                              DateFormat('hh a').format(DateTime(2026, 1, 1, hour)),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9CA3AF),
                                fontFamily: 'Nunito',
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
                        final _TeacherScheduledSession item = entry.value;
                        final double top =
                            ((item.start.hour + (item.start.minute / 60)) -
                                    agendaStartHour) *
                                hourRowHeight;
                        final double height =
                            (item.end.difference(item.start).inMinutes / 60) *
                                hourRowHeight;
                        return Positioned(
                          top: top,
                          left: 0,
                          right: 0,
                          height: height,
                          child: _TeacherAgendaSessionCard(
                            item: item,
                            palette: _teacherPaletteForSession(
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

class _TeacherAgendaSessionCard extends StatelessWidget {
  const _TeacherAgendaSessionCard({
    required this.item,
    required this.palette,
  });

  final _TeacherScheduledSession item;
  final _TeacherEventPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              fontFamily: 'Inter',
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
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherScheduleMessageState extends StatelessWidget {
  const _TeacherScheduleMessageState({
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
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: const TextStyle(
                  color: Color(0xFF000080),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Nunito',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeacherScheduledSession {
  const _TeacherScheduledSession({
    required this.session,
  });

  final TeacherScheduleSession session;

  DateTime get start => DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
        session.startTime.hour,
        session.startTime.minute,
      );

  DateTime get end => DateTime(
        session.date.year,
        session.date.month,
        session.date.day,
        session.endTime.hour,
        session.endTime.minute,
      );

  String get title => session.title;

  String get shortTitle {
    final List<String> parts = title.split(RegExp(r'\s+'));
    if (parts.length <= 2) {
      return title;
    }
    return parts.take(2).join('\n');
  }

  String get roomLabel {
    if (session.subject.trim().isNotEmpty) {
      return session.subject;
    }
    return session.studentSummary;
  }
}

class _TeacherEventPalette {
  const _TeacherEventPalette({required this.primary});

  final Color primary;
}

_TeacherEventPalette _teacherPaletteForSession(
  _TeacherScheduledSession item, {
  required int fallbackIndex,
}) {
  final String seed =
      '${item.session.subject} ${item.session.title} ${item.session.statusLabel}'
          .toLowerCase();

  if (seed.contains('math') || seed.contains('algebra')) {
    return const _TeacherEventPalette(primary: Color(0xFF5F71F1));
  }
  if (seed.contains('physics')) {
    return const _TeacherEventPalette(primary: Color(0xFF3730C7));
  }
  if (seed.contains('language') || seed.contains('english') || seed.contains('french')) {
    return const _TeacherEventPalette(primary: Color(0xFFB14FE6));
  }
  if (seed.contains('program') || seed.contains('computer')) {
    return const _TeacherEventPalette(primary: Color(0xFFE2C83D));
  }

  const List<_TeacherEventPalette> palettes = <_TeacherEventPalette>[
    _TeacherEventPalette(primary: Color(0xFFE2C83D)),
    _TeacherEventPalette(primary: Color(0xFF5F71F1)),
    _TeacherEventPalette(primary: Color(0xFFB14FE6)),
    _TeacherEventPalette(primary: Color(0xFF3730C7)),
  ];
  return palettes[fallbackIndex % palettes.length];
}


