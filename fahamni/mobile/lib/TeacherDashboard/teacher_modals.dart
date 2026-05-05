import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SessionModalResult {
  const SessionModalResult({
    required this.date,
    required this.durationMinutes,
    required this.startTime,
    required this.sessionType,
    required this.modality,
    required this.onlineLink,
  });

  final DateTime date;
  final int durationMinutes;
  final TimeOfDay startTime;
  final String sessionType;
  final String modality;
  final String onlineLink;
}

class AddResourceModalResult {
  const AddResourceModalResult({
    required this.name,
    required this.resourceType,
    required this.resourceValue,
  });

  final String name;
  final String resourceType;
  final String resourceValue;
}

class QuoteResponseModalResult {
  const QuoteResponseModalResult({
    required this.price,
    required this.sessionsCount,
    required this.sessionDurationMinutes,
  });

  final double price;
  final int sessionsCount;
  final int sessionDurationMinutes;
}

class SessionModal extends StatefulWidget {
  const SessionModal({
    super.key,
    required this.title,
    this.initialDate,
    this.initialDuration = 30,
    this.initialStartTime,
    this.initialSessionType = 'Regular',
    this.initialModality = 'Online',
    this.initialOnlineLink = '',
  });

  final String title;
  final DateTime? initialDate;
  final int initialDuration;
  final TimeOfDay? initialStartTime;
  final String initialSessionType;
  final String initialModality;
  final String initialOnlineLink;

  static Future<SessionModalResult?> showCreate(BuildContext context) {
    return showDialog<SessionModalResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: SessionModal(title: 'Create Session'),
      ),
    );
  }

  static Future<SessionModalResult?> showReschedule(
    BuildContext context, {
    required DateTime date,
    required TimeOfDay startTime,
    required int duration,
    String modality = 'Online',
  }) {
    return showDialog<SessionModalResult>(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: SessionModal(
          title: 'Re-Schedule Session',
          initialDate: date,
          initialStartTime: startTime,
          initialDuration: duration,
          initialModality: modality,
        ),
      ),
    );
  }

  @override
  State<SessionModal> createState() => _SessionModalState();
}

class _SessionModalState extends State<SessionModal> {
  late DateTime _date;
  late TimeOfDay _startTime;
  late int _duration;
  late String _sessionType;
  late String _modality;
  late TextEditingController _linkController;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _date = widget.initialDate ?? DateTime(now.year, now.month, now.day);
    _startTime = widget.initialStartTime ?? const TimeOfDay(hour: 9, minute: 0);
    _duration = widget.initialDuration;
    _sessionType = widget.initialSessionType;
    _modality = widget.initialModality;
    _linkController = TextEditingController(text: widget.initialOnlineLink);
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ModalHeader(title: widget.title),
          const SizedBox(height: 8),
          _FieldLabel(label: 'Date'),
          _SelectorField(
            value: DateFormat('EEE, dd MMM').format(_date).toUpperCase(),
            icon: Icons.calendar_today_outlined,
            onTap: _pickDate,
          ),
          const SizedBox(height: 10),
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
                      labelBuilder: (v) => '$v min',
                      onChanged: (v) => setState(() => _duration = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(label: 'Start Time'),
                    _SelectorField(
                      value: _startTime.format(context),
                      icon: Icons.access_time_outlined,
                      onTap: _pickTime,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _FieldLabel(label: 'Session Type'),
          _DropdownField<String>(
            value: _sessionType,
            items: const ['Regular', 'Intro', 'Exam Prep'],
            labelBuilder: (v) => v,
            onChanged: (v) => setState(() => _sessionType = v),
          ),
          const SizedBox(height: 10),
          const _FieldLabel(label: 'Session Mode'),
          _DropdownField<String>(
            value: _modality,
            items: const ['Online', 'Onsite'],
            labelBuilder: (v) => v,
            onChanged: (v) => setState(() => _modality = v),
          ),
          const SizedBox(height: 10),
          if (_modality == 'Online') ...[
            const _FieldLabel(label: 'Online Session Link'),
            TextField(
              controller: _linkController,
              decoration: _inputDecoration(hint: 'URL'),
            ),
            const SizedBox(height: 14),
          ] else
            const SizedBox(height: 14),
          Center(
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                minimumSize: const Size(132, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(widget.title.contains('Re-Schedule') ? 'Save' : 'Create'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (selected != null) {
      setState(() => _startTime = selected);
    }
  }

  void _submit() {
    Navigator.of(context).pop(
      SessionModalResult(
        date: _date,
        durationMinutes: _duration,
        startTime: _startTime,
        sessionType: _sessionType,
        modality: _modality,
        onlineLink: _linkController.text.trim(),
      ),
    );
  }
}

class AddResourceModal extends StatefulWidget {
  const AddResourceModal({super.key});

  static Future<AddResourceModalResult?> show(BuildContext context) {
    return showDialog<AddResourceModalResult>(
      context: context,
      builder: (_) => const Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: AddResourceModal(),
      ),
    );
  }

  @override
  State<AddResourceModal> createState() => _AddResourceModalState();
}

class _AddResourceModalState extends State<AddResourceModal> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  String _type = 'Document/Media';

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isLink = _type == 'Link';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ModalHeader(title: 'Add Resource'),
          const SizedBox(height: 8),
          const _FieldLabel(label: 'Resource Name'),
          TextField(
            controller: _nameController,
            decoration: _inputDecoration(hint: ''),
          ),
          const SizedBox(height: 10),
          const _FieldLabel(label: 'Resource Type'),
          _DropdownField<String>(
            value: _type,
            items: const ['Document/Media', 'Link'],
            labelBuilder: (value) => value,
            onChanged: (value) => setState(() => _type = value),
          ),
          const SizedBox(height: 10),
          const _FieldLabel(label: 'Resource'),
          if (isLink)
            TextField(
              controller: _valueController,
              decoration: _inputDecoration(hint: 'URL'),
            )
          else
            GestureDetector(
              onTap: () {
                _valueController.text = 'uploaded_file_placeholder';
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File picker integration point ready.')),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD6DBE6), style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.cloud_upload_outlined, color: Color(0xFF000080)),
                    SizedBox(height: 4),
                    Text(
                      'Tap to upload your resource',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          Center(
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                minimumSize: const Size(132, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Complete'),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.of(context).pop(
      AddResourceModalResult(
        name: name,
        resourceType: _type,
        resourceValue: _valueController.text.trim(),
      ),
    );
  }
}

class QuoteResponseModal extends StatefulWidget {
  const QuoteResponseModal({super.key});

  static Future<QuoteResponseModalResult?> show(BuildContext context) {
    return showDialog<QuoteResponseModalResult>(
      context: context,
      builder: (_) => const Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20),
        child: QuoteResponseModal(),
      ),
    );
  }

  @override
  State<QuoteResponseModal> createState() => _QuoteResponseModalState();
}

class _QuoteResponseModalState extends State<QuoteResponseModal> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _sessionsController = TextEditingController(text: '1');
  int _duration = 30;

  @override
  void dispose() {
    _priceController.dispose();
    _sessionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ModalHeader(title: 'Respond to Quote'),
          const SizedBox(height: 8),
          const _FieldLabel(label: 'Price (DA)'),
          TextField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _inputDecoration(hint: '2500'),
          ),
          const SizedBox(height: 10),
          const _FieldLabel(label: 'Sessions Number'),
          TextField(
            controller: _sessionsController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(hint: '1'),
          ),
          const SizedBox(height: 10),
          const _FieldLabel(label: 'Session Duration'),
          _DropdownField<int>(
            value: _duration,
            items: const [30, 45, 60, 90],
            labelBuilder: (v) => '$v min',
            onChanged: (v) => setState(() => _duration = v),
          ),
          const SizedBox(height: 14),
          Center(
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                minimumSize: const Size(132, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Complete'),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final double? price = double.tryParse(_priceController.text.trim());
    final int? sessions = int.tryParse(_sessionsController.text.trim());
    if (price == null || sessions == null || sessions < 1) {
      return;
    }
    Navigator.of(context).pop(
      QuoteResponseModalResult(
        price: price,
        sessionsCount: sessions,
        sessionDurationMinutes: _duration,
      ),
    );
  }
}

class _ModalHeader extends StatelessWidget {
  const _ModalHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Center(
            child: Text(
              title,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF334155),
          fontWeight: FontWeight.w600,
          fontSize: 12,
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
      child: InputDecorator(
        decoration: _inputDecoration(hint: ''),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF334155),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
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
  final String Function(T) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: _inputDecoration(hint: ''),
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(labelBuilder(item)),
            ),
          )
          .toList(),
      onChanged: (T? selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }
}

InputDecoration _inputDecoration({required String hint}) {
  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD6DBE6)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFD6DBE6)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF000080)),
    ),
  );
}


