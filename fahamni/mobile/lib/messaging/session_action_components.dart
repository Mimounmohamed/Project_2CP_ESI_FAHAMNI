import 'package:dotted_border/dotted_border.dart';
import 'package:fahamni/otp_verification_Screen/primarybutton.dart';
import 'package:flutter/material.dart';

enum ResourceInputType { documentMedia, link }

enum SessionDeliveryType { onsite, online }

class SessionDraft {
  const SessionDraft({
    required this.date,
    required this.durationMinutes,
    required this.startTime,
    required this.deliveryType,
    this.onlineLink,
  });

  final DateTime? date;
  final int durationMinutes;
  final TimeOfDay? startTime;
  final SessionDeliveryType deliveryType;
  final String? onlineLink;
}

class ResourceDraft {
  const ResourceDraft({
    required this.name,
    required this.inputType,
    this.link,
  });

  final String name;
  final ResourceInputType inputType;
  final String? link;
}

class JoinServiceRequestCard extends StatelessWidget {
  const JoinServiceRequestCard({
    super.key,
    required this.studentName,
    required this.levelLabel,
    required this.subjectLabel,
    required this.serviceName,
    this.avatarImage,
    this.noticeText,
    this.onAccept,
    this.onReject,
    this.onClose,
  });

  final String studentName;
  final String levelLabel;
  final String subjectLabel;
  final String serviceName;
  final ImageProvider<Object>? avatarImage;
  final String? noticeText;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 255,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                ),
              ),
            ],
          ),
          CircleAvatar(
            radius: 29,
            backgroundColor: const Color(0xFFE2E8F0),
            backgroundImage: avatarImage,
            child: avatarImage == null
                ? const Icon(Icons.person_rounded, color: Color(0xFF64748B), size: 30)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            studentName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$levelLabel - $subjectLabel',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Color(0xFF334155),
              ),
              children: [
                TextSpan(text: '$studentName requests to join the following service:\n'),
                TextSpan(
                  text: serviceName,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const TextSpan(
                  text: '\nYou can accept the join request once the payment is done, or reject it.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.error_outline_rounded, size: 15, color: Color(0xFFEF4444)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  noticeText ??
                      'By accepting the request, the new student can access all the service documents, group and sessions.',
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: 'Accept',
                  onPressed: onAccept ?? () {},
                  minimumSize: const Size(0, 36),
                  borderRadius: 18,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD0D5DD)),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AddResourceDialog extends StatefulWidget {
  const AddResourceDialog({
    super.key,
    this.initialType = ResourceInputType.documentMedia,
    this.onComplete,
    this.onClose,
    this.onPickFile,
  });

  final ResourceInputType initialType;
  final ValueChanged<ResourceDraft>? onComplete;
  final VoidCallback? onClose;
  final VoidCallback? onPickFile;

  @override
  State<AddResourceDialog> createState() => _AddResourceDialogState();
}

class _AddResourceDialogState extends State<AddResourceDialog> {
  late final TextEditingController _resourceNameController;
  late final TextEditingController _resourceLinkController;
  late ResourceInputType _selectedType;

  @override
  void initState() {
    super.initState();
    _resourceNameController = TextEditingController();
    _resourceLinkController = TextEditingController();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _resourceNameController.dispose();
    _resourceLinkController.dispose();
    super.dispose();
  }

  void _handleComplete() {
    widget.onComplete?.call(
      ResourceDraft(
        name: _resourceNameController.text.trim(),
        inputType: _selectedType,
        link: _selectedType == ResourceInputType.link
            ? _resourceLinkController.text.trim()
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ActionDialogShell(
      title: 'Add Ressource',
      onClose: widget.onClose,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _FieldLabel(label: 'Resource Name'),
          const SizedBox(height: 6),
          _DialogTextField(
            controller: _resourceNameController,
            hintText: '',
          ),
          const SizedBox(height: 14),
          _FieldLabel(label: 'Resource Type'),
          const SizedBox(height: 6),
          _DialogDropdown<ResourceInputType>(
            value: _selectedType,
            items: const [
              DropdownMenuItem(
                value: ResourceInputType.documentMedia,
                child: Text('Document/Media'),
              ),
              DropdownMenuItem(
                value: ResourceInputType.link,
                child: Text('Link'),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedType = value;
              });
            },
          ),
          const SizedBox(height: 14),
          if (_selectedType == ResourceInputType.documentMedia) ...[
            _FieldLabel(label: 'Resource'),
            const SizedBox(height: 8),
            InkWell(
              onTap: widget.onPickFile,
              borderRadius: BorderRadius.circular(14),
              child: DottedBorder(
                color: const Color(0xFFD3DCE8),
                dashPattern: const [5, 4],
                strokeWidth: 1.2,
                borderType: BorderType.RRect,
                radius: const Radius.circular(14),
                child: Container(
                  height: 86,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.cloud_upload_outlined, color: Color(0xFF0F179B), size: 24),
                      SizedBox(height: 6),
                      Text(
                        'Tap to upload your Resource',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            _FieldLabel(label: 'Resource Link'),
            const SizedBox(height: 6),
            _DialogTextField(
              controller: _resourceLinkController,
              hintText: 'URL',
            ),
          ],
          const SizedBox(height: 18),
          Align(
            child: PrimaryButton(
              text: 'Complete',
              onPressed: _handleComplete,
              minimumSize: const Size(102, 34),
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class CreateSessionDialog extends StatefulWidget {
  const CreateSessionDialog({
    super.key,
    this.initialDuration = 30,
    this.initialDeliveryType = SessionDeliveryType.onsite,
    this.onCreate,
    this.onClose,
  });

  final int initialDuration;
  final SessionDeliveryType initialDeliveryType;
  final ValueChanged<SessionDraft>? onCreate;
  final VoidCallback? onClose;

  @override
  State<CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<CreateSessionDialog> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late int _duration;
  late SessionDeliveryType _deliveryType;
  late final TextEditingController _onlineLinkController;

  @override
  void initState() {
    super.initState();
    _duration = widget.initialDuration;
    _deliveryType = widget.initialDeliveryType;
    _onlineLinkController = TextEditingController();
  }

  @override
  void dispose() {
    _onlineLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) {
      return;
    }
    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 13, minute: 0),
    );
    if (time == null || !mounted) {
      return;
    }
    setState(() {
      _selectedTime = time;
    });
  }

  void _handleCreate() {
    widget.onCreate?.call(
      SessionDraft(
        date: _selectedDate,
        durationMinutes: _duration,
        startTime: _selectedTime,
        deliveryType: _deliveryType,
        onlineLink: _deliveryType == SessionDeliveryType.online
            ? _onlineLinkController.text.trim()
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ActionDialogShell(
      title: 'Create Session',
      onClose: widget.onClose,
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _FieldLabel(label: 'Date'),
          const SizedBox(height: 6),
          _SelectionField(
            label: _selectedDate == null
                ? 'Choose Date'
                : _sessionDateLabel(_selectedDate!),
            icon: Icons.calendar_today_outlined,
            onTap: _pickDate,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(label: 'Session Duration'),
                    const SizedBox(height: 6),
                    _DialogDropdown<int>(
                      value: _duration,
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30 min')),
                        DropdownMenuItem(value: 45, child: Text('45 min')),
                        DropdownMenuItem(value: 60, child: Text('60 min')),
                        DropdownMenuItem(value: 90, child: Text('90 min')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _duration = value;
                        });
                      },
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
                    const SizedBox(height: 6),
                    _SelectionField(
                      label: _selectedTime == null
                          ? 'Choose Time'
                          : _selectedTime!.format(context),
                      icon: Icons.access_time_rounded,
                      onTap: _pickTime,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _FieldLabel(label: 'Session Type'),
          const SizedBox(height: 6),
          _DialogDropdown<SessionDeliveryType>(
            value: _deliveryType,
            items: const [
              DropdownMenuItem(
                value: SessionDeliveryType.online,
                child: Text('Online'),
              ),
              DropdownMenuItem(
                value: SessionDeliveryType.onsite,
                child: Text('Onsite'),
              ),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _deliveryType = value;
              });
            },
          ),
          if (_deliveryType == SessionDeliveryType.online) ...[
            const SizedBox(height: 14),
            _FieldLabel(label: 'Online Session Link'),
            const SizedBox(height: 6),
            _DialogTextField(
              controller: _onlineLinkController,
              hintText: 'URL',
            ),
          ],
          const SizedBox(height: 18),
          Align(
            child: PrimaryButton(
              text: 'Create',
              onPressed: _handleCreate,
              minimumSize: const Size(102, 34),
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class RescheduleSessionDialog extends StatefulWidget {
  const RescheduleSessionDialog({
    super.key,
    this.initialDate,
    this.initialTime,
    this.initialDuration = 30,
    this.onSave,
    this.onClose,
  });

  final DateTime? initialDate;
  final TimeOfDay? initialTime;
  final int initialDuration;
  final ValueChanged<SessionDraft>? onSave;
  final VoidCallback? onClose;

  @override
  State<RescheduleSessionDialog> createState() => _RescheduleSessionDialogState();
}

class _RescheduleSessionDialogState extends State<RescheduleSessionDialog> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late int _duration;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _selectedTime = widget.initialTime;
    _duration = widget.initialDuration;
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) {
      return;
    }
    setState(() {
      _selectedDate = date;
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 13, minute: 0),
    );
    if (time == null || !mounted) {
      return;
    }
    setState(() {
      _selectedTime = time;
    });
  }

  void _handleSave() {
    widget.onSave?.call(
      SessionDraft(
        date: _selectedDate,
        durationMinutes: _duration,
        startTime: _selectedTime,
        deliveryType: SessionDeliveryType.onsite,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ActionDialogShell(
      title: 'Re-Schedule Session',
      onClose: widget.onClose,
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _FieldLabel(label: 'Date'),
          const SizedBox(height: 6),
          _SelectionField(
            label: _selectedDate == null
                ? 'Choose Date'
                : _sessionDateLabel(_selectedDate!),
            icon: Icons.calendar_today_outlined,
            onTap: _pickDate,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(label: 'Session Duration'),
                    const SizedBox(height: 6),
                    _DialogDropdown<int>(
                      value: _duration,
                      items: const [
                        DropdownMenuItem(value: 30, child: Text('30 min')),
                        DropdownMenuItem(value: 45, child: Text('45 min')),
                        DropdownMenuItem(value: 60, child: Text('60 min')),
                        DropdownMenuItem(value: 90, child: Text('90 min')),
                      ],
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setState(() {
                          _duration = value;
                        });
                      },
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
                    const SizedBox(height: 6),
                    _SelectionField(
                      label: _selectedTime == null
                          ? 'Choose Time'
                          : _selectedTime!.format(context),
                      icon: Icons.access_time_rounded,
                      onTap: _pickTime,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            child: PrimaryButton(
              text: 'Save',
              onPressed: _handleSave,
              minimumSize: const Size(102, 34),
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class SessionActionsMenu extends StatelessWidget {
  const SessionActionsMenu({
    super.key,
    this.onReschedule,
    this.onCancel,
  });

  final VoidCallback? onReschedule;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return _ActionMenuCard(
      items: [
        _ActionMenuItemData(
          icon: Icons.event_repeat_rounded,
          label: 'Re-Schedule',
          onTap: onReschedule,
        ),
        _ActionMenuItemData(
          icon: Icons.delete_outline_rounded,
          label: 'Cancel',
          onTap: onCancel,
        ),
      ],
    );
  }
}

class ResourceActionsMenu extends StatelessWidget {
  const ResourceActionsMenu({
    super.key,
    this.onOverview,
    this.onEdit,
    this.onDelete,
  });

  final VoidCallback? onOverview;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return _ActionMenuCard(
      items: [
        _ActionMenuItemData(
          icon: Icons.visibility_outlined,
          label: 'Overview',
          onTap: onOverview,
        ),
        _ActionMenuItemData(
          icon: Icons.edit_outlined,
          label: 'Edit',
          onTap: onEdit,
        ),
        _ActionMenuItemData(
          icon: Icons.delete_outline_rounded,
          label: 'Delete',
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _ActionDialogShell extends StatelessWidget {
  const _ActionDialogShell({
    required this.title,
    required this.child,
    this.onClose,
    this.width = 262,
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Spacer(),
                Expanded(
                  flex: 6,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: onClose,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF334155),
      ),
    );
  }
}

class _DialogTextField extends StatelessWidget {
  const _DialogTextField({
    required this.controller,
    required this.hintText,
  });

  final TextEditingController controller;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF0F179B)),
          ),
        ),
      ),
    );
  }
}

class _DialogDropdown<T> extends StatelessWidget {
  const _DialogDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          items: items,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _SelectionField extends StatelessWidget {
  const _SelectionField({
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
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: label.startsWith('Choose') ? FontWeight.w500 : FontWeight.w600,
                  color: label.startsWith('Choose')
                      ? const Color(0xFF475569)
                      : const Color(0xFF334155),
                ),
              ),
            ),
            Icon(icon, color: const Color(0xFF64748B), size: 18),
          ],
        ),
      ),
    );
  }
}

class _ActionMenuCard extends StatelessWidget {
  const _ActionMenuCard({
    required this.items,
  });

  final List<_ActionMenuItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 94,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(items.length, (index) {
          final _ActionMenuItemData item = items[index];
          return InkWell(
            onTap: item.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Icon(item.icon, size: 16, color: const Color(0xFF1F2937)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ActionMenuItemData {
  const _ActionMenuItemData({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

String _sessionDateLabel(DateTime date) {
  const List<String> weekdays = [
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
    'SUN',
  ];
  const List<String> months = [
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
