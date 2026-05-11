import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/session_model.dart';
import '../Teacher_Service_Details/service_details_service.dart';

class SessionTab extends StatefulWidget {
  final String serviceId;
  final int totalSessions;

  const SessionTab({
    super.key,
    required this.serviceId,
    required this.totalSessions,
  });

  @override
  State<SessionTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends State<SessionTab> {
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_sessions.isEmpty) {
      return const Center(
        child: Text('No sessions yet',
            style: TextStyle(fontFamily: 'Nunito', color: Color(0xFF94A3B8))),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: _sessions.length,
      itemBuilder: (_, i) => _SessionCard(session: _sessions[i]),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final SessionModel session;

  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final bool isOnline = session.mode.toLowerCase() == 'online';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Date
          Text(
            DateFormat('EEE, d MMM').format(session.startTime).toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Lexend',
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: Color(0xFF000080),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          // Time range
          Text(
            '${DateFormat('HH:mm').format(session.startTime)} – ${DateFormat('HH:mm').format(session.endTime)}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          // Mode badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isOnline
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isOnline
                      ? Icons.videocam_rounded
                      : Icons.location_on_rounded,
                  size: 12,
                  color: isOnline
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFE65100),
                ),
                const SizedBox(width: 4),
                Text(
                  isOnline ? 'Online' : 'Onsite',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: isOnline
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFE65100),
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

