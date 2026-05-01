import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/session_model.dart';
import 'service_details_service.dart';

class SessionsTab extends StatefulWidget {
  final String serviceId;
  final int totalSessions;

  const SessionsTab({
    super.key,
    required this.serviceId,
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
    setState(() {
      _sessions = data;
      _loading = false;
    });
  }

  void _showAddSessionSheet() async {
    final modeController = TextEditingController();
    DateTime? startTime;
    DateTime? endTime;

    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Session',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
              const SizedBox(height: 16),
              TextField(
                controller: modeController,
                decoration: InputDecoration(
                  hintText: 'Mode (online / onsite)',
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                title: Text(startTime == null
                    ? 'Pick Start Time'
                    : 'Start: ${startTime!.hour}:${startTime!.minute.toString().padLeft(2, '0')}'),
                trailing:
                    const Icon(Icons.access_time, color: Color(0xFF000080)),
                onTap: () async {
                  final picked = await showDateTimePicker(ctx);
                  if (picked != null) setModalState(() => startTime = picked);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                title: Text(endTime == null
                    ? 'Pick End Time'
                    : 'End: ${endTime!.hour}:${endTime!.minute.toString().padLeft(2, '0')}'),
                trailing:
                    const Icon(Icons.access_time, color: Color(0xFF000080)),
                onTap: () async {
                  final picked = await showDateTimePicker(ctx);
                  if (picked != null) setModalState(() => endTime = picked);
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (startTime == null ||
                        endTime == null ||
                        modeController.text.trim().isEmpty) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select start/end time and enter a mode.'),
                        ),
                      );
                      return;
                    }
                    if (endTime!.isBefore(startTime!)) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('End time must occur after start time.'),
                        ),
                      );
                      return;
                    }

                    final DateTime selectedStart = startTime!;
                    final session = SessionModel(
                      sessionId: '',
                      serviceId: widget.serviceId,
                      studentIds: const [],
                      tutorId: '',
                      status: SessionStatus.Planned,
                      type: 'Session',
                      modality: modeController.text.trim(),
                      mode: modeController.text.trim(),
                      meetingLink: '',
                      notes: '',
                      date: DateTime(selectedStart.year, selectedStart.month,
                          selectedStart.day),
                      startTime: selectedStart,
                      endTime: endTime!,
                    );

                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(ctx);
                    try {
                      await _service.addSession(session);
                      navigator.pop(true);
                    } catch (error) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('Failed to add session: $error')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000080),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Add Session',
                      style: TextStyle(
                          fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (added == true) {
      if (!mounted) return;
      await _load();
    }
  }

  // ignore: use_build_context_synchronously
  Future<DateTime?> showDateTimePicker(BuildContext ctx) async {
    final pickerContext = ctx;
    final date = await showDatePicker(
      context: pickerContext,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return null;
    if (!mounted) return null;
    final time = await showTimePicker(
      // ignore: use_build_context_synchronously
      context: pickerContext,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final remaining = widget.totalSessions - _sessions.length;

    return Column(
      children: [
        // ── Stats row ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Container(
            margin: const EdgeInsets.fromLTRB(38, 0, 38, 0),
            child: Row(
              children: [
                _StatBox(
                    label: 'SCHEDULED', value: _sessions.length.toString()),
                const SizedBox(width: 12),
                _StatBox(
                    label: 'REMAINING',
                    value: remaining < 0 ? '0' : remaining.toString()),
              ],
            ),
          ),
        ),

        // ── Grid list ──────────────────────────────────────────────
        Expanded(
          child: _sessions.isEmpty
              ? const Center(
                  child: Text(
                    'No sessions yet',
                    style: TextStyle(
                        fontFamily: 'Nunito', color: Color(0xFF94A3B8)),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,       // 2 columns like the screenshot
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.05,  // card height/width ratio
                  ),
                  itemCount: _sessions.length,
                  itemBuilder: (_, i) => _SessionGridCard(
                    session: _sessions[i],
                    onDelete: () async {
                      await _service.deleteSession(_sessions[i].sessionId);
                      _load();
                    },
                  ),
                ),
        ),

        // ── Add button ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: SizedBox(
            width: 200,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _showAddSessionSheet,
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Add Session',
                style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Grid card ────────────────────────────────────────────────────────────────
class _SessionGridCard extends StatelessWidget {
  final SessionModel session;
  final VoidCallback onDelete;

  const _SessionGridCard({
    required this.session,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOnline =
        session.modality.toLowerCase().contains('online');

    final dayStr =
        DateFormat('EEE, d MMM').format(session.date).toUpperCase();
    final startStr = DateFormat('HH:mm').format(session.startTime);
    final endStr   = DateFormat('HH:mm').format(session.endTime);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Date + menu ─────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  dayStr,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF000080),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showMenu(context),
                child: const Icon(Icons.more_vert,
                    size: 18, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Time range ──────────────────────────────
          Text(
            '$startStr – $endStr',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: Color(0xFF0F172A),
            ),
          ),

          const Spacer(),

          // ── Modality badge ──────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFFDCFCE7)   // green tint
                  : const Color(0xFFFEF3C7),  // orange tint
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOnline ? Icons.videocam_rounded : Icons.location_on,
                  size: 14,
                  color: isOnline
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFD97706),
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? 'Online' : 'Onsite',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isOnline
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete Session',
                  style: TextStyle(
                      fontFamily: 'Lexend', color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat box ─────────────────────────────────────────────────────────────────
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
              color: Color(0xFF000080).withValues(alpha: 0.2),
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



