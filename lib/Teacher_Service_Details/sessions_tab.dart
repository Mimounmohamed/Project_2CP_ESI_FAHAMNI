import 'package:flutter/material.dart';
import '../../models/session_model.dart';
import 'service_details_service.dart';
import 'session_card.dart';

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

  void _showAddSessionSheet() {
    final modeController = TextEditingController();
    DateTime? startTime;
    DateTime? endTime;

    showModalBottomSheet(
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
              // Mode
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
              // Start time
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
              // End time
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
                        modeController.text.isEmpty) return;
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
                      date: DateTime(selectedStart.year, selectedStart.month, selectedStart.day),
                      startTime: selectedStart,
                      endTime: endTime!,
                    );
                    await _service.addSession(session);
                    Navigator.pop(ctx);
                    _load();
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
  }

  Future<DateTime?> showDateTimePicker(BuildContext ctx) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return null;
    final time = await showTimePicker(
      context: ctx,
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
        // Stats row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              _StatBox(label: 'SCHEDULED', value: _sessions.length.toString()),
              const SizedBox(width: 12),
              _StatBox(
                  label: 'REMAINING',
                  value: remaining < 0 ? '0' : remaining.toString()),
            ],
          ),
        ),
        // Sessions list
        Expanded(
          child: _sessions.isEmpty
              ? const Center(
                  child: Text('No sessions yet',
                      style: TextStyle(
                          fontFamily: 'Nunito', color: Color(0xFF94A3B8))))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _sessions.length,
                  itemBuilder: (_, i) => SessionCard(
                    session: _sessions[i],
                    onDelete: () async {
                      await _service.deleteSession(_sessions[i].sessionId);
                      _load();
                    },
                  ),
                ),
        ),
        // Add button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _showAddSessionSheet,
              icon: const Icon(Icons.add),
              label: const Text('Add Session',
                  style: TextStyle(
                      fontFamily: 'Nunito', fontWeight: FontWeight.w700)),
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

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.8)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: Color(0xFF000080))),
          ],
        ),
      ),
    );
  }
}