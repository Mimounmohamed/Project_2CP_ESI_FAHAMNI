import 'package:fahamni/Account_Settings_Teacher/account_screen.dart';
import 'package:fahamni/TeacherDashboard/teacher_dashboard_service.dart';
import 'package:fahamni/TeacherDashboard/teacher_schedule_page.dart';
import 'package:fahamni/Notification_page/notification_page.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/models/teacher_dashboard_model.dart';
import 'package:fahamni/navigation/app_navigation.dart';
import 'package:fahamni/otp_verification_Screen/primarybutton.dart';
import 'package:fahamni/widgets/customnavbar.dart';
import 'package:flutter/material.dart';

class Teacherpage extends StatelessWidget {
  const Teacherpage({super.key});

  @override
  Widget build(BuildContext context) => const TeacherDashboardScreen();
}

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  static const Color _primaryBlue = Color(0xFF1A237E);
  static const Color _pageBackground = Color(0xFFF5F5F5);
  late Future<TeacherDashboardModel> _dashboardFuture;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = TeacherDashboardService().loadDashboard();
  }

  Future<void> _refreshDashboard() async {
    final Future<TeacherDashboardModel> future =
        TeacherDashboardService().loadDashboard();
    setState(() {
      _dashboardFuture = future;
    });
    await future;
  }

  void _handleNavigation(int index) {
    if (index == _selectedIndex) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher explore is coming soon.')),
        );
        break;
      case 2:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TeacherSchedulePage()),
        );
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChatPage()),
        );
        break;
      case 4:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        ).then((_) => _refreshDashboard());
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This section is coming soon.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground,
      bottomNavigationBar: CustomBottomNavbar(
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
              return _DashboardErrorState(
                message: snapshot.error.toString(),
                onRetry: _refreshDashboard,
              );
            }

            final TeacherDashboardModel dashboard = snapshot.data!;
            return RefreshIndicator(
              color: _primaryBlue,
              onRefresh: _refreshDashboard,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _DashboardHeader(
                            teacherName: dashboard.teacherName,
                            teacherRoleLabel: dashboard.teacherRoleLabel,
                            profileImage: dashboard.profileImage,
                          ),
                          const SizedBox(height: 22),
                          _PerformanceCard(stats: dashboard.stats, title: dashboard.performanceTitle),
                          const SizedBox(height: 22),
                          _SectionHeader(
                            title: dashboard.todaySessionsTitle,
                            actionLabel: dashboard.seeAllLabel,
                            onActionTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TeacherSchedulePage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          if (dashboard.nextSession != null)
                            _SessionCard(session: dashboard.nextSession!)
                          else
                            _EmptyCard(label: dashboard.emptySessionsLabel),
                          const SizedBox(height: 22),
                          _SectionHeader(
                            title: dashboard.myServicesTitle,
                            actionLabel: dashboard.seeAllLabel,
                            onActionTap: () {},
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 248,
                            child: dashboard.services.isEmpty
                                ? _EmptyCard(label: dashboard.emptyServicesLabel)
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: dashboard.services.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          right: index == dashboard.services.length - 1 ? 0 : 16,
                                        ),
                                        child: _ServiceCard(
                                          service: dashboard.services[index],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 22),
                          _SectionHeader(
                            title: dashboard.quoteRequestsTitle,
                            actionLabel: dashboard.seeAllLabel,
                            onActionTap: () {},
                          ),
                          const SizedBox(height: 14),
                          if (dashboard.quoteRequests.isEmpty)
                            _EmptyCard(label: dashboard.emptyQuotesLabel)
                          else
                            ...dashboard.quoteRequests.map(
                              (request) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _QuoteRequestTile(request: request),
                              ),
                            ),
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
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.teacherName,
    required this.teacherRoleLabel,
    required this.profileImage,
  });

  final String teacherName;
  final String teacherRoleLabel;
  final String profileImage;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ProfileAvatar(imagePath: profileImage, radius: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                teacherName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                teacherRoleLabel,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A237E),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationPage()),
            );
          },
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF1F2937),
            size: 28,
          ),
        ),
      ],
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.stats,
    required this.title,
  });

  final List<TeacherDashboardStat> stats;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEFF5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: stats
                .map(
                  (stat) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              stat.label,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              stat.value,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        TextButton(
          onPressed: onActionTap,
          child: Text(
            actionLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A237E),
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
  });

  final TeacherDashboardSession session;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 132,
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _TagChip(
                        label: session.badgeLabel,
                        backgroundColor: const Color(0xFFE8EAF6),
                        textColor: const Color(0xFF1A237E),
                      ),
                      const Spacer(),
                      _TagChip(
                        label: session.modalityLabel,
                        backgroundColor: const Color(0xFFE8F7EC),
                        textColor: const Color(0xFF16A34A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    session.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: Color(0xFF64748B), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.subject,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded, color: Color(0xFF64748B), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.timeRange,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.service,
  });

  final TeacherDashboardServiceCard service;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 208,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SizedBox(
              height: 112,
              width: double.infinity,
              child: _DashboardImage(imagePath: service.imagePath),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: _TagChip(
                        label: service.category,
                        backgroundColor: const Color(0xFFE8EAF6),
                        textColor: const Color(0xFF1A237E),
                      ),
                    ),
                    const Spacer(),
                    _TagChip(
                      label: service.statusLabel,
                      backgroundColor: const Color(0xFFE8F7EC),
                      textColor: const Color(0xFF16A34A),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  service.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, color: Color(0xFF94A3B8), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      service.sessionsLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  service.priceLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A237E),
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

class _QuoteRequestTile extends StatelessWidget {
  const _QuoteRequestTile({
    required this.request,
  });

  final TeacherDashboardQuoteRequest request;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _ProfileAvatar(imagePath: request.avatarPath, radius: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.studentLevel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  request.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PrimaryButton(
            text: request.actionLabel,
            onPressed: () {
              NavigationService.instance.push(
                _QuoteRequestDetailsPage(request: request),
              );
            },
            minimumSize: const Size(112, 40),
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            fontSize: 12,
          ),
        ],
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  const _DashboardErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 52, color: Color(0xFF1A237E)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              text: 'Retry',
              onPressed: () {
                onRetry();
              },
            ),
          ],
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.imagePath,
    required this.radius,
  });

  final String imagePath;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE2E8F0),
      backgroundImage: _resolveImageProvider(imagePath),
      child: imagePath.trim().isEmpty
          ? const Icon(Icons.person_rounded, color: Color(0xFF64748B))
          : null,
    );
  }
}

class _DashboardImage extends StatelessWidget {
  const _DashboardImage({
    required this.imagePath,
  });

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final ImageProvider<Object>? imageProvider = _resolveImageProvider(imagePath);
    if (imageProvider == null) {
      return Container(
        color: const Color(0xFF16324F),
        alignment: Alignment.center,
        child: const Icon(Icons.school_rounded, color: Colors.white, size: 34),
      );
    }

    return Ink.image(
      image: imageProvider,
      fit: BoxFit.cover,
    );
  }
}

class _QuoteRequestDetailsPage extends StatelessWidget {
  const _QuoteRequestDetailsPage({
    required this.request,
  });

  final TeacherDashboardQuoteRequest request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Quote Request',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.studentName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                request.studentLevel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                request.subtitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This placeholder page is ready for your full quote-request details flow.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ImageProvider<Object>? _resolveImageProvider(String imagePath) {
  final String trimmed = imagePath.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return NetworkImage(trimmed);
  }

  if (trimmed.startsWith('assets/')) {
    return AssetImage(trimmed);
  }

  return null;
}
