import 'package:fahamni/Notification_page/notification_page.dart';
import 'package:fahamni/Account_Settings_Teacher/account_screen.dart'
    as teacher_account;
import 'package:fahamni/Services/notification_service.dart';
import 'package:fahamni/Services/guest_mode_protection.dart';
import 'package:fahamni/Services/suspended_account_gate.dart';
import 'package:fahamni/TeacherDashboard/models/teacher_portal_models.dart';
import 'package:fahamni/TeacherDashboard/teacher_dashboard_service.dart';
import 'package:fahamni/TeacherDashboard/teacher_quote_request_detail_page.dart';
import 'package:fahamni/TeacherDashboard/teacher_quotes_page.dart';
import 'package:fahamni/TeacherDashboard/teacher_schedule_page.dart';
import 'package:fahamni/TeacherDashboard/teacher_services_dashboard.dart';
import 'package:fahamni/TeacherDashboard/widgets/teacher_navbar.dart';
import 'package:fahamni/Teacher_Service_Details/service_details_page.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/models/notification_model.dart';
import 'package:fahamni/models/service_model.dart';
import 'package:fahamni/models/teacher_dashboard_model.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:fahamni/navigation/app_navigation.dart';
import 'package:fahamni/otp_verification_Screen/primarybutton.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';

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
  final NotificationService _notificationService = NotificationService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _hasUnreadNotifications = false;
  StreamSubscription<List<NotificationModel>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = TeacherDashboardService().loadDashboard();
    _startNotificationListener();
  }

  void _startNotificationListener() {
    final String? userId = _auth.currentUser?.uid;
    if (userId != null) {
      _notificationSubscription = _notificationService
          .streamNotifications(userId)
          .listen((notifications) {
            final bool hasUnread = notifications.any(
              (notification) => !notification.isRead,
            );
            if (mounted && hasUnread != _hasUnreadNotifications) {
              setState(() {
                _hasUnreadNotifications = hasUnread;
              });
            }
          });
    }
  }

  Future<void> _refreshDashboard() async {
    final Future<TeacherDashboardModel> future = TeacherDashboardService()
        .loadDashboard();
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
        // Services - restricted in guest mode
        _checkAndNavigateToServices();
        break;
      case 2:
        // Chat - restricted in guest mode
        _checkAndNavigateToChat();
        break;
      case 3:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const teacher_account.AccountScreen(),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This section is coming soon.')),
        );
    }
  }

  Future<void> _checkAndNavigateToServices() async {
    final canAccess = await GuestModeProtection.canAccessTeacherFeature(
      context,
    );
    if (canAccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const TeacherServicesDashboardScreen(),
        ),
      );
    } else {
      setState(() => _selectedIndex = 0);
    }
  }

  Future<void> _checkAndNavigateToChat() async {
    final canAccess = await GuestModeProtection.canAccessTeacherFeature(
      context,
    );
    if (canAccess) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ChatPage()));
    } else {
      setState(() => _selectedIndex = 0);
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SuspendedAccountGate(
      child: Scaffold(
        backgroundColor: _pageBackground,
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
                        delegate: SliverChildListDelegate([
                          _DashboardHeader(
                            teacherName: dashboard.teacherName,
                            teacherRoleLabel: dashboard.teacherRoleLabel,
                            profileImage: dashboard.profileImage,
                            hasUnreadNotifications: _hasUnreadNotifications,
                          ),
                          const SizedBox(height: 22),
                          _PerformanceCard(
                            stats: dashboard.stats,
                            title: dashboard.performanceTitle,
                          ),
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
                            onActionTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const TeacherServicesDashboardScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 300,
                            child: dashboard.services.isEmpty
                                ? _EmptyCard(
                                    label: dashboard.emptyServicesLabel,
                                  )
                                : ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: dashboard.services.length,
                                    itemBuilder: (context, index) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          right:
                                              index ==
                                                  dashboard.services.length - 1
                                              ? 0
                                              : 16,
                                        ),
                                        child: _ServiceCard(
                                          service: dashboard.services[index],
                                          serviceRecord:
                                              dashboard.serviceRecords[index],
                                          tutor: dashboard.tutorProfile,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 22),
                          _SectionHeader(
                            title: dashboard.quoteRequestsTitle,
                            actionLabel: dashboard.seeAllLabel,
                            onActionTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TeacherQuotesPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          if (dashboard.quoteRequests.isEmpty)
                            _EmptyCard(label: dashboard.emptyQuotesLabel)
                          else
                            ...dashboard.quoteRequests.map((request) {
                              final joinRequest = TeacherJoinRequestDetail(
                                quote: request.quote,
                                studentName: request.studentName,
                                studentLevel: request.studentLevel,
                                studentAvatar: request.avatarPath,
                                serviceTitle:
                                    request.quote.serviceName.isNotEmpty
                                    ? request.quote.serviceName
                                    : request.subtitle,
                                description:
                                    request.quote.description.isNotEmpty
                                    ? request.quote.description
                                    : request.objective,
                                subject: request.subject.isNotEmpty
                                    ? request.subject
                                    : request.quote.subject,
                                teachingMode: request.quote.teachingMode,
                                sessionsCount: request.quote.sessionsCount,
                                sessionDurationLabel:
                                    request.duration.isNotEmpty
                                    ? request.duration
                                    : request.quote.duration,
                                createdAtLabel: request.createdAtLabel,
                                isChild:
                                    request.quote.level.isEmpty &&
                                    request.studentLevel.isNotEmpty,
                              );
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _QuoteRequestTile(
                                  request: joinRequest,
                                  onChanged: _refreshDashboard,
                                ),
                              );
                            }),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
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
    required this.hasUnreadNotifications,
  });

  final String teacherName;
  final String teacherRoleLabel;
  final String profileImage;
  final bool hasUnreadNotifications;

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
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const NotificationPage()));
          },
          icon: Stack(
            children: [
              SvgPicture.asset(
                'assets/images/bell.svg',
                width: 28,
                height: 28,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF1F2937),
                  BlendMode.srcIn,
                ),
              ),
              if (hasUnreadNotifications)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({required this.stats, required this.title});

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
                            if (stat.label == 'RATING')
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    stat.value,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                  SvgPicture.asset(
                                    "assets/images/star.svg",
                                    height: 12,
                                    width: 12,
                                  ),
                                ],
                              )
                            else
                              Text(
                                stat.value,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Nunito',
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
              fontFamily: 'Inter',
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
              fontFamily: 'Nunito',
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
  const _SessionCard({required this.session});

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
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.subject,
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.timeRange,
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: 'Lexend',
                            fontWeight: FontWeight.w400,
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
    required this.serviceRecord,
    required this.tutor,
  });

  final TeacherDashboardServiceCard service;
  final ServiceModel serviceRecord;
  final TutorModel tutor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                CourseDetailsPage(service: serviceRecord, tutor: tutor),
          ),
        );
      },
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: SizedBox(
                height: 132,
                width: double.infinity,
                child: _DashboardImage(imagePath: service.imagePath),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TagChip(
                          label: service.category,
                          backgroundColor: const Color(0xFFE8EAF6),
                          textColor: const Color(0xFF1A237E),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _TagChip(
                        label: service.statusLabel,
                        backgroundColor: const Color(0xFFE8F7EC),
                        textColor: const Color(0xFF16A34A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    service.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: Color(0xFF94A3B8),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          service.sessionsLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    service.priceLabel,
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D138B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuoteRequestTile extends StatelessWidget {
  const _QuoteRequestTile({required this.request, required this.onChanged});

  final TeacherJoinRequestDetail request;
  final Future<void> Function() onChanged;

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
          _ProfileAvatar(imagePath: request.studentAvatar, radius: 24),
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
                  request.subject,
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
            text: "see details",
            onPressed: () async {
              final bool? changed = await NavigationService.instance.push<bool>(
                TeacherQuoteRequestDetailPage(request: request),
              );
              if (changed == true) {
                await onChanged();
              }
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
  const _DashboardErrorState({required this.message, required this.onRetry});

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
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Color(0xFF1A237E),
            ),
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
  const _EmptyCard({required this.label});

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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imagePath, required this.radius});

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
  const _DashboardImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final ImageProvider<Object>? imageProvider = _resolveImageProvider(
      imagePath,
    );
    if (imageProvider == null) {
      return Container(
        color: const Color(0xFF16324F),
        alignment: Alignment.center,
        child: const Icon(Icons.school_rounded, color: Colors.white, size: 34),
      );
    }

    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
      ),
    );
  }
}

class _QuoteRequestDetailsPage extends StatelessWidget {
  const _QuoteRequestDetailsPage({required this.request});

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
