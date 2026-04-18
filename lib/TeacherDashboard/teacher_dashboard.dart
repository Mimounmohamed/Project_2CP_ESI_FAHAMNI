import 'package:fahamni/Notification_page/notification_page.dart';
import 'package:fahamni/TeacherDashboard/teacher_dashboard_service.dart';
import 'package:fahamni/TeacherDashboard/teacher_modals.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/models/service_model.dart';
import 'package:fahamni/models/teacher_dashboard_model.dart';
import 'package:fahamni/widgets/servicecard.dart';
import 'package:fahamni/widgets/teacher_navbar.dart';
import 'package:flutter/material.dart';

class Teacherpage extends StatelessWidget {
  const Teacherpage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const TeacherDashboardScreen(),
    );
  }
}

enum _TeacherTab { services, joinRequests }
enum _ServiceFilter { all, active, inactive }

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final TeacherDashboardService _service = TeacherDashboardService();
  late Future<TeacherDashboardModel> _dashboardFuture;

  int _selectedIndex = 1;
  _TeacherTab _tab = _TeacherTab.services;
  _ServiceFilter _serviceFilter = _ServiceFilter.all;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _service.loadDashboard();
  }

  Future<void> _refreshDashboard() async {
    final Future<TeacherDashboardModel> future = _service.loadDashboard();
    setState(() {
      _dashboardFuture = future;
    });
    await future;
  }

  void _handleNavigation(int index) {
    setState(() => _selectedIndex = index);
    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChatPage()),
      );
      return;
    }
    if (index == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile page is ready to plug in.')),
      );
    }
  }

  Future<void> _openCreateService() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateServicePage(service: _service),
      ),
    );
    await _refreshDashboard();
  }

  Future<void> _toggleService(ServiceModel service) async {
    await _service.setServiceStatus(
      serviceId: service.serviceId,
      isActive: !service.isActive,
    );
    await _refreshDashboard();
  }

  List<ServiceModel> _filterServices(List<ServiceModel> services) {
    return services.where((service) {
      switch (_serviceFilter) {
        case _ServiceFilter.all:
          return true;
        case _ServiceFilter.active:
          return service.isActive;
        case _ServiceFilter.inactive:
          return !service.isActive;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: TeacherNavbar(
        selectedIndex: _selectedIndex,
        onTap: _handleNavigation,
      ),
      body: SafeArea(
        child: FutureBuilder<TeacherDashboardModel>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _ErrorState(
                message: snapshot.error.toString(),
                onRetry: _refreshDashboard,
              );
            }

            final TeacherDashboardModel dashboard = snapshot.data!;
            final List<ServiceModel> visibleServices =
                _filterServices(dashboard.serviceRecords);

            return RefreshIndicator(
              onRefresh: _refreshDashboard,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Services',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NotificationPage()),
                          );
                        },
                        icon: const Icon(Icons.notifications_none_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _TabSwitcher(
                    selectedTab: _tab,
                    onChanged: (tab) => setState(() => _tab = tab),
                  ),
                  const SizedBox(height: 12),
                  if (_tab == _TeacherTab.services) ...[
                    Row(
                      children: [
                        _FilterChipButton(
                          label: 'All',
                          selected: _serviceFilter == _ServiceFilter.all,
                          onTap: () => setState(() => _serviceFilter = _ServiceFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _FilterChipButton(
                          label: 'Active',
                          selected: _serviceFilter == _ServiceFilter.active,
                          onTap: () => setState(() => _serviceFilter = _ServiceFilter.active),
                        ),
                        const SizedBox(width: 8),
                        _FilterChipButton(
                          label: 'Inactive',
                          selected: _serviceFilter == _ServiceFilter.inactive,
                          onTap: () => setState(() => _serviceFilter = _ServiceFilter.inactive),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (visibleServices.isEmpty)
                      const _EmptyCard(label: 'No services match this filter.')
                    else
                      ...visibleServices.map(
                        (service) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ServiceCard(
                            tutor: dashboard.tutorProfile,
                            service: service,
                            showBookButton: false,
                            trailingActions: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _RoundIconButton(
                                  icon: Icons.edit_outlined,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Edit flow can reuse this form.')),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                _RoundIconButton(
                                  icon: service.isActive
                                      ? Icons.toggle_on_rounded
                                      : Icons.toggle_off_rounded,
                                  iconColor: const Color(0xFF000080),
                                  onTap: () => _toggleService(service),
                                ),
                                const SizedBox(width: 8),
                                _RoundIconButton(
                                  icon: Icons.delete_outline_rounded,
                                  iconColor: const Color(0xFF64748B),
                                  onTap: () => _service
                                      .setServiceStatus(
                                        serviceId: service.serviceId,
                                        isActive: false,
                                      )
                                      .then((_) => _refreshDashboard()),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Center(
                      child: ElevatedButton(
                        onPressed: _openCreateService,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF000080),
                          minimumSize: const Size(170, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                          ),
                        ),
                        child: const Text('+ Create Service'),
                      ),
                    ),
                  ] else ...[
                    if (dashboard.quoteRequests.isEmpty)
                      const _EmptyCard(label: 'No join requests yet.')
                    else
                      ...dashboard.quoteRequests.map(
                        (request) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _JoinRequestCard(
                            request: request,
                            service: _service,
                            onRefresh: _refreshDashboard,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({
    required this.selectedTab,
    required this.onChanged,
  });

  final _TeacherTab selectedTab;
  final ValueChanged<_TeacherTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EDF7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _TabButton(
            label: 'Services',
            selected: selectedTab == _TeacherTab.services,
            onTap: () => onChanged(_TeacherTab.services),
          ),
          _TabButton(
            label: 'Join Requests',
            selected: selectedTab == _TeacherTab.joinRequests,
            onTap: () => onChanged(_TeacherTab.joinRequests),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: selected ? Border.all(color: const Color(0xFFD7DEED)) : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? const Color(0xFF000080) : const Color(0xFF64748B),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF000080) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF000080) : const Color(0xFFD3D9E8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = const Color(0xFF000080),
  });

  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F3FA),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: iconColor, size: 18),
      ),
    );
  }
}

class _JoinRequestCard extends StatefulWidget {
  const _JoinRequestCard({
    required this.request,
    required this.service,
    required this.onRefresh,
  });

  final TeacherDashboardQuoteRequest request;
  final TeacherDashboardService service;
  final Future<void> Function() onRefresh;

  @override
  State<_JoinRequestCard> createState() => _JoinRequestCardState();
}

class _JoinRequestCardState extends State<_JoinRequestCard> {
  bool _busy = false;

  Future<void> _accept() async {
    final QuoteResponseModalResult? response = await QuoteResponseModal.show(context);
    if (response == null) {
      return;
    }

    setState(() => _busy = true);
    try {
      await widget.service.respondToQuote(
        quoteId: widget.request.id,
        accepted: true,
        price: response.price,
        sessionsNumber: response.sessionsCount,
        sessionDurationMinutes: response.sessionDurationMinutes,
      );
      if (!mounted) {
        return;
      }
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _reject() async {
    setState(() => _busy = true);
    try {
      await widget.service.respondToQuote(
        quoteId: widget.request.id,
        accepted: false,
      );
      if (!mounted) {
        return;
      }
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E0EE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage:
                    widget.request.avatarPath.isNotEmpty ? _resolveImage(widget.request.avatarPath) : null,
                child: widget.request.avatarPath.isEmpty
                    ? const Icon(Icons.person, size: 16)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.request.studentName,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                    ),
                    Text(
                      '${widget.request.subject} - ${widget.request.studentLevel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                widget.request.createdAtLabel,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy ? null : _accept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000080),
                    minimumSize: const Size.fromHeight(38),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Accept'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _reject,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(38),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              IconButton(
                onPressed: _busy
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => QuoteRequestDetailPage(
                              request: widget.request,
                              service: widget.service,
                            ),
                          ),
                        );
                        await widget.onRefresh();
                      },
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ImageProvider _resolveImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return AssetImage(path);
  }
}

class CreateServicePage extends StatefulWidget {
  const CreateServicePage({
    super.key,
    required this.service,
  });

  final TeacherDashboardService service;

  @override
  State<CreateServicePage> createState() => _CreateServicePageState();
}

class _CreateServicePageState extends State<CreateServicePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _membersController = TextEditingController(text: '1');
  final TextEditingController _sessionsController = TextEditingController(text: '1');
  final TextEditingController _priceController = TextEditingController(text: '1');

  String _domain = 'Math';
  String _grade = '2nd';
  String _mode = 'Online';
  int _duration = 30;
  String _selectedPicture = 'assets/images/default_service_img.png';
  bool _submitting = false;

  static const List<String> _pictures = <String>[
    'assets/images/default_service_img.png',
    'assets/images/slide0.png',
    'assets/images/slide1.png',
    'assets/images/slide2.png',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _subjectController.dispose();
    _membersController.dispose();
    _sessionsController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.service.createService(
        CreateServicePayload(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          domain: _domain,
          grade: _grade,
          subject: _subjectController.text.trim(),
          price: double.parse(_priceController.text.trim()),
          membersNumber: int.parse(_membersController.text.trim()),
          mode: _mode,
          sessionsNumber: int.parse(_sessionsController.text.trim()),
          sessionDuration: _duration,
          picture: _selectedPicture,
        ),
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Service'),
      ),
      bottomNavigationBar: TeacherNavbar(
        selectedIndex: 1,
        onTap: (_) {},
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LabelField(label: 'Service Name'),
              TextFormField(
                controller: _nameController,
                validator: _required,
                decoration: _fieldDecoration(''),
              ),
              const SizedBox(height: 12),
              const _LabelField(label: 'Description'),
              TextFormField(
                controller: _descriptionController,
                validator: _required,
                minLines: 3,
                maxLines: 5,
                maxLength: 200,
                decoration: _fieldDecoration('In this service...'),
              ),
              Row(
                children: [
                  Expanded(
                    child: _DropdownInput(
                      label: 'Domain',
                      value: _domain,
                      options: const ['Math', 'Physics', 'Chemistry', 'Languages'],
                      onChanged: (value) => setState(() => _domain = value),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DropdownInput(
                      label: 'Grade',
                      value: _grade,
                      options: const ['1st', '2nd', '3rd', '4th', '5th'],
                      onChanged: (value) => setState(() => _grade = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    child: _LabelField(label: 'Members Number', includeBottomSpacing: false),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DropdownInput(
                      label: 'Mode',
                      value: _mode,
                      options: const ['Online', 'Onsite'],
                      onChanged: (value) => setState(() => _mode = value),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _membersController,
                      keyboardType: TextInputType.number,
                      validator: _positiveInt,
                      decoration: _fieldDecoration('1'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Expanded(
                    child: _LabelField(label: 'Sessions Number', includeBottomSpacing: false),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DropdownInput(
                      label: 'Sessions Duration',
                      value: '$_duration min',
                      options: const ['30 min', '45 min', '60 min', '90 min'],
                      onChanged: (value) {
                        setState(() => _duration = int.parse(value.split(' ').first));
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sessionsController,
                      keyboardType: TextInputType.number,
                      validator: _positiveInt,
                      decoration: _fieldDecoration('1'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
              const SizedBox(height: 10),
              const _LabelField(label: 'Subject'),
              TextFormField(
                controller: _subjectController,
                validator: _required,
                decoration: _fieldDecoration('Algebra / Vector Spaces'),
              ),
              const SizedBox(height: 10),
              const _LabelField(label: 'Service Price'),
              TextFormField(
                controller: _priceController,
                validator: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _fieldDecoration('1 DA'),
              ),
              const SizedBox(height: 12),
              const _LabelField(label: 'Service Picture'),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _pictures.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final String picture = _pictures[index];
                    final bool selected = picture == _selectedPicture;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPicture = picture),
                      child: Container(
                        width: 96,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? const Color(0xFF000080) : const Color(0xFFD6DBE6),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(9),
                          child: Image.asset(picture, fit: BoxFit.cover),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000080),
                    minimumSize: const Size(170, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _positiveInt(String? value) {
    final int? parsed = int.tryParse((value ?? '').trim());
    if (parsed == null || parsed < 1) {
      return 'Enter valid number';
    }
    return null;
  }

  String? _price(String? value) {
    final double? parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed <= 0) {
      return 'Enter valid price';
    }
    return null;
  }
}

class QuoteRequestDetailPage extends StatefulWidget {
  const QuoteRequestDetailPage({
    super.key,
    required this.request,
    required this.service,
  });

  final TeacherDashboardQuoteRequest request;
  final TeacherDashboardService service;

  @override
  State<QuoteRequestDetailPage> createState() => _QuoteRequestDetailPageState();
}

class _QuoteRequestDetailPageState extends State<QuoteRequestDetailPage> {
  bool _busy = false;

  Future<void> _accept() async {
    final QuoteResponseModalResult? response = await QuoteResponseModal.show(context);
    if (response == null) {
      return;
    }

    setState(() => _busy = true);
    try {
      await widget.service.respondToQuote(
        quoteId: widget.request.id,
        accepted: true,
        price: response.price,
        sessionsNumber: response.sessionsCount,
        sessionDurationMinutes: response.sessionDurationMinutes,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _reject() async {
    setState(() => _busy = true);
    try {
      await widget.service.respondToQuote(
        quoteId: widget.request.id,
        accepted: false,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _createSession() async {
    final SessionModalResult? result = await SessionModal.showCreate(context);
    if (result == null) {
      return;
    }
    await widget.service.createSession(
      serviceId: '',
      date: result.date,
      startTime: result.startTime,
      durationMinutes: result.durationMinutes,
      sessionType: result.sessionType,
      modality: result.modality,
      onlineLink: result.onlineLink,
      studentIds: [widget.request.studentId],
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Session created successfully.')),
    );
  }

  Future<void> _addResource() async {
    final AddResourceModalResult? result = await AddResourceModal.show(context);
    if (result == null) {
      return;
    }
    await widget.service.addResource(
      sessionId: '',
      name: result.name,
      type: result.resourceType,
      value: result.resourceValue,
      subject: widget.request.subject,
      level: widget.request.studentLevel,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resource added successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote Request'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD9E0EE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: widget.request.avatarPath.isNotEmpty
                        ? (widget.request.avatarPath.startsWith('http')
                            ? NetworkImage(widget.request.avatarPath)
                            : AssetImage(widget.request.avatarPath) as ImageProvider)
                        : null,
                    child: widget.request.avatarPath.isEmpty
                        ? const Icon(Icons.person_rounded)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.request.studentName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          widget.request.studentLevel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow(label: 'Subject', value: widget.request.subject),
              _DetailRow(label: 'Objective', value: widget.request.objective),
              _DetailRow(label: 'Frequency', value: widget.request.frequency),
              _DetailRow(label: 'Requested Duration', value: widget.request.duration),
              _DetailRow(label: 'Budget', value: widget.request.budget),
              _DetailRow(label: 'Status', value: widget.request.status),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFFD8C7)),
                ),
                child: const Text(
                  'By accepting this request, the student can access service documents, group and sessions.',
                  style: TextStyle(
                    color: Color(0xFF9A3412),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: _createSession,
                    icon: const Icon(Icons.event),
                    label: const Text('Create Session'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _addResource,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Add Resource'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy ? null : _accept,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000080)),
                      child: _busy
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _reject,
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownInput extends StatelessWidget {
  const _DropdownInput({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabelField(label: label),
        DropdownButtonFormField<String>(
          value: value,
          decoration: _fieldDecoration(''),
          items: options
              .map(
                (opt) => DropdownMenuItem<String>(
                  value: opt,
                  child: Text(opt),
                ),
              )
              .toList(),
          onChanged: (selected) {
            if (selected != null) {
              onChanged(selected);
            }
          },
        ),
      ],
    );
  }
}

class _LabelField extends StatelessWidget {
  const _LabelField({
    required this.label,
    this.includeBottomSpacing = true,
  });

  final String label;
  final bool includeBottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: includeBottomSpacing ? 6 : 2),
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFF000080)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
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
