import 'package:fahamni/Account_Settings_Teacher/account_screen.dart' as teacher_account;
import 'package:fahamni/TeacherDashboard/models/teacher_portal_models.dart';
import 'package:fahamni/TeacherDashboard/teacher_create_service_page.dart';
import 'package:fahamni/TeacherDashboard/teacher_portal_service.dart';
import 'package:fahamni/TeacherDashboard/widgets/teacher_navbar.dart';
import 'package:fahamni/TeacherDashboard/widgets/teacher_portal_modals.dart' as portal_modals;
import 'package:fahamni/Teacher_Service_Details/service_details_page.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/models/quote_model.dart';
import 'package:fahamni/models/service_model.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:flutter/material.dart';

import 'teacher_dashboard.dart';

class TeacherServicesDashboardScreen extends StatefulWidget {
  const TeacherServicesDashboardScreen({super.key});

  @override
  State<TeacherServicesDashboardScreen> createState() =>
      _TeacherServicesDashboardScreenState();
}

class _TeacherServicesDashboardScreenState
    extends State<TeacherServicesDashboardScreen> {
  final TeacherPortalService _service = TeacherPortalService();

  late Future<TeacherServicesDashboardData> _dashboardFuture;
  int _selectedTab = 0;
  TeacherServicesFilter _filter = TeacherServicesFilter.all;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _service.loadDashboard();
  }

  Future<void> _refresh() async {
    final Future<TeacherServicesDashboardData> future = _service.loadDashboard();
    setState(() {
      _dashboardFuture = future;
    });
    await future;
  }

  void _handleNavigation(int index) {
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
      );
      return;
    }
    if (index == 1) {
      return;
    }
    if (index == 2) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChatPage()),
      );
      return;
    }
    if (index == 3) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const teacher_account.AccountScreen()),
      );
      return;
    }
  }

  Future<void> _openCreateService() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TeacherCreateServicePage()),
    );
    await _refresh();
  }

  Future<void> _acceptRequest(TeacherJoinRequestDetail request) async {
    final TeacherQuoteResponseDraft? response =
        await portal_modals.QuoteResponseModal.show(context, request);
    if (response == null) {
      return;
    }

    await _service.respondToQuote(
      request: request,
      status: QuoteStatus.accepted,
      response: response,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request from ${request.studentName} accepted.')),
    );
    await _refresh();
  }

  Future<void> _rejectRequest(TeacherJoinRequestDetail request) async {
    await _service.respondToQuote(
      request: request,
      status: QuoteStatus.rejected,
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request from ${request.studentName} rejected.')),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      bottomNavigationBar: TeacherNavbar(
        selectedIndex: 1,
        onTap: _handleNavigation,
      ),
      body: SafeArea(
        child: FutureBuilder<TeacherServicesDashboardData>(
          future: _dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return _TeacherPortalError(
                message: snapshot.error.toString(),
                onRetry: _refresh,
              );
            }

            final TeacherServicesDashboardData data = snapshot.data!;
            final List<ServiceModel> visibleServices = _filteredServices(data.services);

            return RefreshIndicator(
              color: const Color(0xFF0D138B),
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          const SizedBox(height: 8),
                          const Center(
                            child: Text(
                              'Services',
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _TopTabSwitcher(
                            selectedIndex: _selectedTab,
                            labels: const ['Services', 'Quote Requests'],
                            onChanged: (index) {
                              setState(() {
                                _selectedTab = index;
                              });
                            },
                          ),
                          const SizedBox(height: 18),
                          if (_selectedTab == 0) ...[
                            _StatusFilterBar(
                              value: _filter,
                              onChanged: (value) {
                                setState(() {
                                  _filter = value;
                                });
                              },
                            ),
                            const SizedBox(height: 18),
                            if (visibleServices.isEmpty)
                              const _EmptyTeacherState(
                                title: 'No services yet',
                                subtitle:
                                    'Create your first service to start receiving join requests.',
                              )
                            else
                              ...visibleServices.map(
                                (service) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _TeacherServiceCard(
                                    tutor: data.tutor,
                                    service: service,
                                    onToggleStatus: () async {
                                      await _service.updateServiceStatus(
                                        serviceId: service.serviceId,
                                        isActive: !service.isActive,
                                      );
                                      await _refresh();
                                    },
                                    onDelete: () async {
                                      await _service.deleteService(service.serviceId);
                                      await _refresh();
                                    },
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _openCreateService,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0D138B),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text(
                                  'Create Service',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ] else ...[
                            if (data.joinRequests.isEmpty)
                              const _EmptyTeacherState(
                                title: 'No join requests',
                                subtitle:
                                    'Incoming requests from students will appear here.',
                              )
                            else
                              ...data.joinRequests.map(
                                (request) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _JoinRequestCard(
                                    request: request,
                                    onOpen: () {},
                                    onAccept: () => _acceptRequest(request),
                                    onReject: () => _rejectRequest(request),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<ServiceModel> _filteredServices(List<ServiceModel> services) {
    switch (_filter) {
      case TeacherServicesFilter.active:
        return services.where((service) => service.isActive).toList();
      case TeacherServicesFilter.inactive:
        return services.where((service) => !service.isActive).toList();
      case TeacherServicesFilter.all:
        return services;
    }
  }
}

class _TeacherServiceCard extends StatelessWidget {
  const _TeacherServiceCard({
    required this.tutor,
    required this.service,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final TutorModel tutor;
  final ServiceModel service;
  final Future<void> Function() onToggleStatus;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CourseDetailsPage(service: service
                                    , tutor: tutor
                                    )
                                  ),
                                );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE8EBF7)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D138B).withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TeacherServiceImage(imagePath: service.picture),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE4E6F7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            service.subject.isEmpty
                                ? 'SERVICE'
                                : service.subject.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF0D138B),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: service.isActive
                                ? const Color(0xFFDDF8E5)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            service.isActive ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(
                              color: service.isActive
                                  ? const Color(0xFF22C55E)
                                  : const Color(0xFF64748B),
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      service.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF253043),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          color: Color(0xFF7A88A3),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${service.sessionsnum} Session${service.sessionsnum == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Color(0xFF6A7A99),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            '${service.price.toInt()} DA',
                            style: const TextStyle(
                              color: Color(0xFF0D138B),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Color(0xFF000080).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: GestureDetector(
                            child: const Icon(
                              Icons.edit_outlined,
                              size: 22,
                              color: Color(0xFF000080),
                            ),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Edit flow can be added on top of the create form.',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        _TeacherStatusSwitch(
                          value: service.isActive,
                          onChanged: (_) => onToggleStatus(),
                        ),
                        const SizedBox(width: 12),
                         Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF000080
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child:
                        GestureDetector(
                          onTap: onDelete,
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            size: 22,
                            color: Color(0xFF000080),
                          ),
                        ),)
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeacherServiceImage extends StatelessWidget {
  const _TeacherServiceImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    const double headerHeight = 140;
    final String trimmed = imagePath.trim();
    final bool isNetwork =
        trimmed.startsWith('http://') || trimmed.startsWith('https://');
    final bool isAsset = trimmed.startsWith('assets/');

    if (isNetwork) {
      return SizedBox(
        height: headerHeight,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(trimmed),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    if (isAsset) {
      return SizedBox(
        height: headerHeight,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(trimmed),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    return _fallbackImage();
  }

  Widget _fallbackImage() {
    return const SizedBox(
      height: 140,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/default_service_img.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class _TeacherStatusSwitch extends StatelessWidget {
  const _TeacherStatusSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 52,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF120E9B),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFDDE3F5),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _JoinRequestCard extends StatelessWidget {
  const _JoinRequestCard({
    required this.request,
    required this.onOpen,
    required this.onAccept,
    required this.onReject,
  });

  final TeacherJoinRequestDetail request;
  final VoidCallback onOpen;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8ECF5)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFDBEAFE),
                  backgroundImage:
                      request.studentAvatar.isNotEmpty ? NetworkImage(request.studentAvatar) : null,
                  child: request.studentAvatar.isEmpty
                      ? Text(
                          request.studentName.characters.first.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0D138B),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.studentName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${request.subject} · ${request.studentLevel}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  request.createdAtLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InlineActionButton(
                    label: 'Accept',
                    filled: true,
                    onTap: onAccept,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InlineActionButton(
                    label: 'Reject',
                    filled: false,
                    onTap: onReject,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopTabSwitcher extends StatelessWidget {
  const _TopTabSwitcher({
    required this.selectedIndex,
    required this.labels,
    required this.onChanged,
  });

  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(labels.length, (index) {
        final bool selected = selectedIndex == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(index),
            child: Container(
              padding: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected
                        ? const Color(0xFF0D138B)
                        : const Color(0xFFE2E8F0),
                    width: 3,
                  ),
                ),
              ),
              child: Text(
                labels[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected
                      ? const Color(0xFF0D138B)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _StatusFilterBar extends StatelessWidget {
  const _StatusFilterBar({
    required this.value,
    required this.onChanged,
  });

  final TeacherServicesFilter value;
  final ValueChanged<TeacherServicesFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, TeacherServicesFilter filter) {
      final bool selected = value == filter;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(filter),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF0D138B) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('All', TeacherServicesFilter.all),
        chip('Active', TeacherServicesFilter.active),
        chip('Inactive', TeacherServicesFilter.inactive),
      ],
    );
  }
}

class _InlineActionButton extends StatelessWidget {
  const _InlineActionButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: filled ? const Color(0xFF0D138B) : Colors.white,
          foregroundColor:
              filled ? Colors.white : const Color(0xFF475569),
          side: filled
              ? BorderSide.none
              : const BorderSide(color: Color(0xFFD3DAEA)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF475569)),
      ),
    );
  }
}

class _EmptyTeacherState extends StatelessWidget {
  const _EmptyTeacherState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.dashboard_customize_outlined,
            color: Color(0xFF0D138B),
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherPortalError extends StatelessWidget {
  const _TeacherPortalError({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Failed to load teacher services.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D138B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}


