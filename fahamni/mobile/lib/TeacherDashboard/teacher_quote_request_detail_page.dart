import 'package:fahamni/TeacherDashboard/models/teacher_portal_models.dart';
import 'package:fahamni/TeacherDashboard/teacher_portal_service.dart';
import 'package:fahamni/TeacherDashboard/widgets/teacher_portal_modals.dart' as portal_modals;
import 'package:fahamni/models/quote_model.dart';
import 'package:flutter/material.dart';
import 'teacher_modals.dart';

const Color _pageBackground = Color(0xFFF7F8FC);
const Color _primaryBlue = Color(0xFF0D138B);
const Color _titleColor = Color(0xFF1F2937);
const Color _bodyColor = Color(0xFF52627A);
const Color _hintColor = Color(0xFFA4B3CE);
const Color _cardBorder = Color(0xFFE4E8F2);
const Color _iconChipBackground = Color(0xFFE7E9F8);

class TeacherQuoteRequestDetailPage extends StatefulWidget {
  const TeacherQuoteRequestDetailPage({
    super.key,
    required this.request,
  });

  final TeacherJoinRequestDetail request;

  @override
  State<TeacherQuoteRequestDetailPage> createState() =>
      _TeacherQuoteRequestDetailPageState();
}

class _TeacherQuoteRequestDetailPageState
    extends State<TeacherQuoteRequestDetailPage> {
  final TeacherPortalService _service = TeacherPortalService();
  bool _busy = false;

  Future<void> _accept() async {
    final double? price = await portal_modals.QuoteRespondModal.show(context);
    if (price == null) {
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      await _service.respondToQuote(
        request: widget.request,
        status: QuoteStatus.accepted,
        response: TeacherQuoteResponseDraft(
          priceLabel: price.toStringAsFixed(0),
          sessionsCount: widget.request.sessionsCount,
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quote sent to ${widget.request.studentName}.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _reject() async {
    setState(() {
      _busy = true;
    });
    try {
      await _service.respondToQuote(
        request: widget.request,
        status: QuoteStatus.rejected,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request from ${widget.request.studentName} rejected.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _createSession() async {
    final SessionModalResult? draftResult = await SessionModal.showCreate(context);
    if (draftResult == null) {
      return;
    }

    final draft = TeacherSessionDraft(
      date: draftResult.date,
      startTime: DateTime(
        draftResult.date.year,
        draftResult.date.month,
        draftResult.date.day,
        draftResult.startTime.hour,
        draftResult.startTime.minute,
      ),
      durationMinutes: draftResult.durationMinutes,
      sessionType: draftResult.modality,
      meetingLink: draftResult.onlineLink,
    );

    setState(() {
      _busy = true;
    });
    try {
      await _service.createSession(request: widget.request, draft: draft);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session created successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _rescheduleSession() async {
    final SessionModalResult? draftResult =
        await SessionModal.showReschedule(
          context,
          date: DateTime.now(),
          startTime: TimeOfDay.now(),
          duration: 60,
        );
    if (draftResult == null) {
      return;
    }

    final draft = TeacherSessionDraft(
      date: draftResult.date,
      startTime: DateTime(
        draftResult.date.year,
        draftResult.date.month,
        draftResult.date.day,
        draftResult.startTime.hour,
        draftResult.startTime.minute,
      ),
      durationMinutes: draftResult.durationMinutes,
      sessionType: draftResult.modality,
      meetingLink: draftResult.onlineLink,
    );

    setState(() {
      _busy = true;
    });
    try {
      final String? sessionId = await _service.findLatestSessionId(widget.request);
      if (sessionId == null) {
        await _service.createSession(request: widget.request, draft: draft);
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No session was found, so a new one was created.'),
          ),
        );
      } else {
        await _service.rescheduleSession(sessionId: sessionId, draft: draft);
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session rescheduled successfully.')),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _addResource() async {
    final AddResourceModalResult? draftResult = await AddResourceModal.show(context);
    if (draftResult == null) {
      return;
    }

    final draft = TeacherResourceDraft(
      name: draftResult.name,
      type: draftResult.resourceType == 'Link'
          ? TeacherResourceType.link
          : TeacherResourceType.document,
      link: draftResult.resourceValue,
      filePath: draftResult.resourceType == 'Link' ? '' : draftResult.resourceValue,
    );

    setState(() {
      _busy = true;
    });
    try {
      await _service.addResource(request: widget.request, draft: draft);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resource added successfully.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TeacherJoinRequestDetail request = widget.request;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: _titleColor,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Quote Request',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: _titleColor,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      PopupMenuButton<_RequestMenuAction>(
                        onSelected: (action) {
                          switch (action) {
                            case _RequestMenuAction.createSession:
                              _createSession();
                              break;
                            case _RequestMenuAction.reschedule:
                              _rescheduleSession();
                              break;
                            case _RequestMenuAction.addResource:
                              _addResource();
                              break;
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: _RequestMenuAction.createSession,
                            child: Text('Create Session'),
                          ),
                          PopupMenuItem(
                            value: _RequestMenuAction.reschedule,
                            child: Text('Re-Schedule'),
                          ),
                          PopupMenuItem(
                            value: _RequestMenuAction.addResource,
                            child: Text('Add Resource'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage: request.studentAvatar.isNotEmpty
                        ? NetworkImage(request.studentAvatar)
                        : null,
                    child: request.studentAvatar.isEmpty
                        ? Text(
                            request.studentName.characters.first.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: _primaryBlue,
                              fontFamily: 'Inter',
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    request.studentName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _titleColor,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    request.studentLevel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _primaryBlue,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const SizedBox(height: 18),
                  _CardSection(
                    title: 'Description',
                    titleIcon: Icons.description_outlined,
                    child: Text(
                      request.description,
                      style: const TextStyle(
                        color: _bodyColor,
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CardSection(
                    title: 'Details',
                    titleIcon: Icons.info_outline_rounded,
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.menu_book_outlined,
                          label: 'Subject',
                          value: request.subject,
                        ),
                        _DetailRow(
                          icon: Icons.wifi_tethering_outlined,
                          label: 'Teaching Mode',
                          value: request.teachingMode,
                        ),
                        _DetailRow(
                          icon: Icons.calendar_month_outlined,
                          label: 'Number of Sessions',
                          value: '${request.sessionsCount} session${request.sessionsCount == 1 ? '' : 's'}',
                        ),
                        _DetailRow(
                          icon: Icons.access_time_rounded,
                          label: 'Session Duration',
                          value: request.sessionDurationLabel,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Accept',
                          filled: true,
                          onTap: _busy ? null : _accept,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: 'Reject',
                          filled: false,
                          onTap: _busy ? null : _reject,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_busy)
              const ColoredBox(
                color: Color(0x66000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

enum _RequestMenuAction {
  createSession,
  reschedule,
  addResource,
}

class _CardSection extends StatelessWidget {
  const _CardSection({
    required this.title,
    required this.child,
    required this.titleIcon,
  });

  final String title;
  final Widget child;
  final IconData titleIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D138B).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                titleIcon,
                size: 28,
                color: _primaryBlue,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _titleColor,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _iconChipBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 31, color: _primaryBlue),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _hintColor,
                    fontFamily: 'Nunito',
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _titleColor,
                    fontFamily: 'Nunito',
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: filled ? _primaryBlue : Colors.white,
          foregroundColor: filled ? Colors.white : _bodyColor,
          side: filled
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFD3DAEA)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: 'Nunito',
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}


