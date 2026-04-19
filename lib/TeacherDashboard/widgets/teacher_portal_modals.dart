import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/teacher_portal_models.dart';

class SessionModal extends StatefulWidget {
  const SessionModal({
    super.key,
    required this.title,
    this.initialDraft,
    this.submitLabel = 'Create',
  });

  final String title;
  final TeacherSessionDraft? initialDraft;
  final String submitLabel;

  static Future<TeacherSessionDraft?> showCreate(BuildContext context) {
    return showDialog<TeacherSessionDraft>(
      context: context,
      builder: (_) => const SessionModal(title: 'Create Session'),
    );
  }

  static Future<TeacherSessionDraft?> showReschedule(
    BuildContext context, {
    TeacherSessionDraft? initialDraft,
  }) {
    return showDialog<TeacherSessionDraft>(
      context: context,
      builder: (_) => SessionModal(
        title: 'Re-Schedule Session',
        initialDraft: initialDraft,
        submitLabel: 'Save',
      ),
    );
  }

  @override
  State<SessionModal> createState() => _SessionModalState();
}

class _SessionModalState extends State<SessionModal> {
  static const List<int> _durations = <int>[30, 45, 60, 90];
  static const List<String> _types = <String>['Online', 'Onsite', 'Hybrid'];

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _selectedDuration;
  late String _selectedType;
  late TextEditingController _meetingLinkController;

  @override
  void initState() {
    super.initState();
    final TeacherSessionDraft? draft = widget.initialDraft;
    _selectedDate = draft?.date ?? DateTime.now().add(const Duration(days: 1));
    _selectedTime = TimeOfDay.fromDateTime(
      draft?.startTime ?? DateTime.now().add(const Duration(hours: 2)),
    );
    _selectedDuration = draft?.durationMinutes ?? 30;
    _selectedType = draft?.sessionType ?? 'Online';
    _meetingLinkController = TextEditingController(text: draft?.meetingLink ?? '');
  }

  @override
  void dispose() {
    _meetingLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TeacherModalShell(
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label: 'Date'),
          _ActionField(
            label: DateFormat('EEE, dd MMM').format(_selectedDate).toUpperCase(),
            icon: Icons.calendar_month_outlined,
            onTap: _pickDate,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DropdownField<int>(
                  label: 'Session Duration',
                  initialValue: _selectedDuration,
                  items: _durations
                      .map((duration) => DropdownMenuItem<int>(
                            value: duration,
                            child: Text('$duration min'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedDuration = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(label: 'Start Time'),
                    _ActionField(
                      label: _selectedTime.format(context),
                      icon: Icons.access_time_rounded,
                      onTap: _pickTime,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DropdownField<String>(
            label: 'Session Type',
            initialValue: _selectedType,
            items: _types
                .map((type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedType = value;
                });
              }
            },
          ),
          if (_selectedType == 'Online' || _selectedType == 'Hybrid') ...[
            const SizedBox(height: 14),
            _TextField(
              controller: _meetingLinkController,
              label: 'Online Session Link',
              hint: 'URL',
            ),
          ],
          const SizedBox(height: 20),
          _PrimaryModalButton(
            label: widget.submitLabel,
            onTap: () {
              final DateTime combined = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _selectedTime.hour,
                _selectedTime.minute,
              );
              Navigator.of(context).pop(
                TeacherSessionDraft(
                  date: _selectedDate,
                  startTime: combined,
                  durationMinutes: _selectedDuration,
                  sessionType: _selectedType,
                  meetingLink: _meetingLinkController.text.trim(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class AddResourceModal extends StatefulWidget {
  const AddResourceModal({super.key});

  static Future<TeacherResourceDraft?> show(BuildContext context) {
    return showDialog<TeacherResourceDraft>(
      context: context,
      builder: (_) => const AddResourceModal(),
    );
  }

  @override
  State<AddResourceModal> createState() => _AddResourceModalState();
}

class _AddResourceModalState extends State<AddResourceModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  TeacherResourceType _selectedType = TeacherResourceType.document;
  String _selectedFilePath = '';

  @override
  void dispose() {
    _nameController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _TeacherModalShell(
      title: 'Add Resource',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TextField(
            controller: _nameController,
            label: 'Resource Name',
          ),
          const SizedBox(height: 14),
          _DropdownField<TeacherResourceType>(
            label: 'Resource Type',
            initialValue: _selectedType,
            items: const [
              DropdownMenuItem(
                value: TeacherResourceType.document,
                child: Text('Document/Media'),
              ),
              DropdownMenuItem(
                value: TeacherResourceType.link,
                child: Text('Link'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedType = value;
                });
              }
            },
          ),
          const SizedBox(height: 14),
          if (_selectedType == TeacherResourceType.document)
            _UploadField(
              label: _selectedFilePath.isEmpty
                  ? 'Tap to upload your resource'
                  : _selectedFilePath.split('/').last,
              onTap: _pickFile,
            )
          else
            _TextField(
              controller: _linkController,
              label: 'Resource Link',
              hint: 'URL',
            ),
          const SizedBox(height: 20),
          _PrimaryModalButton(
            label: 'Complete',
            onTap: () {
              Navigator.of(context).pop(
                TeacherResourceDraft(
                  name: _nameController.text.trim(),
                  type: _selectedType,
                  filePath: _selectedFilePath,
                  link: _linkController.text.trim(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class QuoteResponseModal extends StatefulWidget {
  const QuoteResponseModal({super.key});

  static Future<TeacherQuoteResponseDraft?> show(BuildContext context) {
    return showDialog<TeacherQuoteResponseDraft>(
      context: context,
      builder: (_) => const QuoteResponseModal(),
    );
  }

  @override
  State<QuoteResponseModal> createState() => _QuoteResponseModalState();
}

class _QuoteResponseModalState extends State<QuoteResponseModal> {
  final TextEditingController _priceController =
      TextEditingController(text: '1 DA');
  final int _sessionsCount = 12;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _TeacherModalShell(
      title: 'Quote Respond',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel(
            label: 'PRICE/SESSION',
            fontSize: 17,
            color: Color(0xFF273246),
            letterSpacing: 0,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7B97),
            ),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 22,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Color(0xFFDEE5F2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: Color(0xFFC9D4EC), width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Upon submission, the student will receive a PDF document containing the service details and your proposed estimate pricing. You may contact the student directly to discuss any additional requirements or clarifications.',
            style: TextStyle(
              fontSize: 16,
              height: 1.35,
              color: Color(0xFF6D7F9E),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 34),
          _PrimaryModalButton(
            label: 'Send',
            onTap: () {
              Navigator.of(context).pop(
                TeacherQuoteResponseDraft(
                  priceLabel: _priceController.text.trim(),
                  sessionsCount: _sessionsCount,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TeacherModalShell extends StatelessWidget {
  const _TeacherModalShell({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 38, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 24, 30, 30),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF273246),
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      size: 34,
                      color: Color(0xFF71819C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    this.fontSize = 12,
    this.color = const Color(0xFF334155),
    this.letterSpacing = 0.3,
  });

  final String label;
  final double fontSize;
  final Color color;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: letterSpacing,
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.hint = '',
  });

  final TextEditingController controller;
  final String label;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0D138B)),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.initialValue,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T initialValue;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label),
        DropdownButtonFormField<T>(
          initialValue: initialValue,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0D138B)),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionField extends StatelessWidget {
  const _ActionField({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(icon, color: const Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }
}

class _UploadField extends StatelessWidget {
  const _UploadField({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFD6DBF3),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_upload_outlined, color: Color(0xFF0D138B)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryModalButton extends StatelessWidget {
  const _PrimaryModalButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: SizedBox(
          width: 282,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF120E9B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
