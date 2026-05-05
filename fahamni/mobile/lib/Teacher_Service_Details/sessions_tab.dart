import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/session_model.dart';
import 'service_details_service.dart';

class SessionsTab extends StatefulWidget {
  final String serviceId;
  final String tutorId;
  final List<String> studentIds;
  final int totalSessions;

  const SessionsTab({
    super.key,
    required this.serviceId,
    required this.tutorId,
    required this.studentIds,
    required this.totalSessions,
  });

  @override
  State<SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends State<SessionsTab> {
  final _service = CourseDetailsService();
  List<SessionModel> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getSessions(widget.serviceId);
    if (!mounted) {
      return;
    }
    setState(() {
      _sessions = data
          .where((session) => session.status != SessionStatus.Canceled)
          .toList();
      _loading = false;
    });
  }

  Future<void> _createSession() async {
    final _SessionDraft? draft = await _SessionDialog.showCreate(context);
    if (draft == null) {
      return;
    }

    final session = SessionModel(
      sessionId: '',
      serviceId: widget.serviceId,
      studentIds: widget.studentIds,
      tutorId: widget.tutorId,
      status: SessionStatus.Planned,
      type: draft.modality,
      modality: draft.modality,
      mode: draft.modality,
      meetingLink: draft.onlineLink,
      notes: '',
      date: DateTime(draft.date.year, draft.date.month, draft.date.day),
      startTime: draft.startDateTime,
      endTime: draft.endDateTime,
    );

    try {
      await _service.addSession(session);
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create session: $error')),
      );
    }
  }

  Future<void> _rescheduleSession(SessionModel session) async {
    final int duration = session.endTime
        .difference(session.startTime)
        .inMinutes;
    final _SessionDraft? draft = await _SessionDialog.showReschedule(
      context,
      session: session,
      duration: duration > 0 ? duration : 30,
    );
    if (draft == null) {
      return;
    }

    final updated = SessionModel(
      sessionId: session.sessionId,
      serviceId: session.serviceId,
      studentIds: session.studentIds,
      tutorId: session.tutorId,
      status: session.status,
      type: session.type,
      modality: session.modality,
      mode: session.mode,
      meetingLink: session.meetingLink,
      notes: session.notes,
      date: DateTime(draft.date.year, draft.date.month, draft.date.day),
      startTime: draft.startDateTime,
      endTime: draft.endDateTime,
    );

    try {
      await _service.updateSession(updated);
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to re-schedule session: $error')),
      );
    }
  }

  Future<void> _cancelSession(SessionModel session) async {
    try {
      await _service.cancelSession(session.sessionId);
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel session: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final remaining = widget.totalSessions - _sessions.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Container(
            margin: const EdgeInsets.fromLTRB(38, 0, 38, 0),
            child: Row(
              children: [
                _StatBox(
                  label: 'SCHEDULED',
                  value: _sessions.length.toString(),
                ),
                const SizedBox(width: 12),
                _StatBox(
                  label: 'REMAINING',
                  value: remaining < 0 ? '0' : remaining.toString(),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _sessions.isEmpty
              ? const Center(
                  child: Text(
                    'No sessions yet',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.45,
                  ),
                  itemCount: _sessions.length,
                  itemBuilder: (_, i) => _SessionGridCard(
                    session: _sessions[i],
                    onReschedule: () => _rescheduleSession(_sessions[i]),
                    onCancel: () => _cancelSession(_sessions[i]),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: SizedBox(
            width: 200,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _createSession,
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add Session',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionGridCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback onReschedule;
  final VoidCallback onCancel;

  const _SessionGridCard({
    required this.session,
    required this.onReschedule,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline = session.modality.toLowerCase().contains('online');
    final dayStr = DateFormat('EEE, d MMM').format(session.date).toUpperCase();
    final startStr = DateFormat('HH:mm').format(session.startTime);
    final endStr = DateFormat('HH:mm').format(session.endTime);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000080).withValues(alpha: 0.12),
            blurRadius: 2,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  dayStr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Color(0xFF000080),
                  ),
                ),
              ),
              PopupMenuButton<_SessionAction>(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.more_vert,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                onSelected: (action) {
                  switch (action) {
                    case _SessionAction.reschedule:
                      onReschedule();
                      break;
                    case _SessionAction.cancel:
                      onCancel();
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<_SessionAction>(
                    value: _SessionAction.reschedule,
                    height: 34,
                    child: Row(
                      children: [
                        Icon(
                          Icons.event_repeat_rounded,
                          size: 17,
                          color: Color(0xFF1F2937),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Re-Schedule',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<_SessionAction>(
                    value: _SessionAction.cancel,
                    height: 34,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 17,
                          color: Color(0xFF1F2937),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            '$startStr - $endStr',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFFEDD5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOnline ? Icons.videocam_rounded : Icons.location_on_rounded,
                  size: 14,
                  color: isOnline
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFEA580C),
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? 'Online' : 'Onsite',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: isOnline
                        ? const Color(0xFF22C55E)
                        : const Color(0xFFEA580C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _SessionAction { reschedule, cancel }

class _SessionDialog extends StatefulWidget {
  const _SessionDialog.create()
    : title = 'Create Session',
      initialDate = null,
      initialTime = null,
      initialDuration = 30,
      initialModality = 'Online',
      initialOnlineLink = '',
      isReschedule = false;

  _SessionDialog.reschedule({
    required SessionModel session,
    required int duration,
  }) : title = 'Re-Schedule Session',
       initialDate = session.date,
       initialTime = session.startTime,
       initialDuration = duration,
       initialModality = session.modality,
       initialOnlineLink = session.meetingLink,
       isReschedule = true;

  final String title;
  final DateTime? initialDate;
  final DateTime? initialTime;
  final int initialDuration;
  final String initialModality;
  final String initialOnlineLink;
  final bool isReschedule;

  static Future<_SessionDraft?> showCreate(BuildContext context) {
    return showDialog<_SessionDraft>(
      context: context,
      builder: (_) => const Dialog(
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 36),
        child: _SessionDialog.create(),
      ),
    );
  }

  static Future<_SessionDraft?> showReschedule(
    BuildContext context, {
    required SessionModel session,
    required int duration,
  }) {
    return showDialog<_SessionDraft>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: _SessionDialog.reschedule(session: session, duration: duration),
      ),
    );
  }

  @override
  State<_SessionDialog> createState() => _SessionDialogState();
}

class _SessionDialogState extends State<_SessionDialog> {
  late int _duration;
  late String _modality;
  late TextEditingController _linkController;
  DateTime? _date;
  TimeOfDay? _startTime;

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration;
    _modality = _normalizeModality(widget.initialModality);
    _linkController = TextEditingController(text: widget.initialOnlineLink);
    _date = widget.initialDate;
    _startTime = widget.initialTime == null
        ? null
        : TimeOfDay.fromDateTime(widget.initialTime!);
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const _FieldLabel(label: 'Date'),
          _SelectorField(
            value: _date == null
                ? 'Choose Date'
                : DateFormat('EEE, dd MMM').format(_date!).toUpperCase(),
            icon: Icons.calendar_today_outlined,
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(label: 'Session Duration'),
                    _DropdownField<int>(
                      value: _duration,
                      items: const [30, 45, 60, 90],
                      labelBuilder: (value) => '$value min',
                      onChanged: (value) => setState(() => _duration = value),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(label: 'Start Time'),
                    _SelectorField(
                      value: _startTime == null
                          ? 'Choose Time'
                          : _formatTime(_startTime!),
                      icon: Icons.access_time_outlined,
                      onTap: _pickTime,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!widget.isReschedule) ...[
            const SizedBox(height: 12),
            const _FieldLabel(label: 'Session Type'),
            _DropdownField<String>(
              value: _modality,
              items: const ['Online', 'Onsite'],
              labelBuilder: (value) => value,
              onChanged: (value) => setState(() => _modality = value),
            ),
            if (_modality == 'Online') ...[
              const SizedBox(height: 12),
              const _FieldLabel(label: 'Online Session Link'),
              TextField(
                controller: _linkController,
                decoration: _inputDecoration(hint: 'URL'),
              ),
            ],
          ],
          const SizedBox(height: 18),
          Center(
            child: SizedBox(
              width: 108,
              height: 42,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  widget.isReschedule ? 'Save' : 'Create',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null && mounted) {
      setState(() => _date = selected);
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (selected != null && mounted) {
      setState(() => _startTime = selected);
    }
  }

  void _submit() {
    final date = _date;
    final startTime = _startTime;
    if (date == null || startTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose date and start time.')),
      );
      return;
    }

    final start = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );
    Navigator.of(context).pop(
      _SessionDraft(
        date: date,
        startDateTime: start,
        endDateTime: start.add(Duration(minutes: _duration)),
        durationMinutes: _duration,
        modality: _modality,
        onlineLink: _modality == 'Online' ? _linkController.text.trim() : '',
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String _normalizeModality(String value) {
    return value.toLowerCase().contains('onsite') ? 'Onsite' : 'Online';
  }
}

class _SessionDraft {
  const _SessionDraft({
    required this.date,
    required this.startDateTime,
    required this.endDateTime,
    required this.durationMinutes,
    required this.modality,
    required this.onlineLink,
  });

  final DateTime date;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final int durationMinutes;
  final String modality;
  final String onlineLink;
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }
}

class _SelectorField extends StatelessWidget {
  const _SelectorField({
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF64748B),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    labelBuilder(item),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({required String hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      fontFamily: 'Inter',
      fontSize: 12,
      color: Color(0xFF94A3B8),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF000080)),
    ),
  );
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000080).withValues(alpha: 0.2),
              blurRadius: 2,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Lexend',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 26,
                color: Color(0xFF000080),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
