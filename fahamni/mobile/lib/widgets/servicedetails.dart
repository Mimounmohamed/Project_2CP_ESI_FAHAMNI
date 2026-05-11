import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/messaging/conversation_page.dart';
import 'package:fahamni/Explore_map_pages/map.dart';
import 'package:fahamni/Services/student_tutor_action_service.dart';
import 'package:fahamni/Courses/courses_page.dart';
import 'package:fahamni/feedback/feedback_pages.dart';
import 'package:fahamni/widgets/customnavbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../StudentHomePage/Student_homepage.dart';
import 'package:fahamni/Account_Settings_Student/account_screen.dart';
import '../models/child_model.dart';
import '../models/service_model.dart';
import '../models/tutor_model.dart';
import '../utils/image_utils.dart';

class Servicedetails extends StatefulWidget {
  final TutorModel tutor;
  final ServiceModel service;
  final ChildModel? selectedChild;
  const Servicedetails({
    super.key,
    required this.service,
    required this.tutor,
    this.selectedChild,
  });

  @override
  State<Servicedetails> createState() => _ServicedetailsState();
}

class _ServicedetailsState extends State<Servicedetails> {
  int _selectedIndex = 1;
  final StudentTutorActionService _studentTutorActionService =
      StudentTutorActionService();
  bool _isActionLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _openConversation() async {
    setState(() {
      _isActionLoading = true;
    });

    try {
      final conversation = await _studentTutorActionService
          .createOrGetConversation(tutor: widget.tutor);
      if (!mounted) {
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationPage(
            conversation: conversation,
            imageUrl: conversation.participantAvatarUrl.isNotEmpty
                ? conversation.participantAvatarUrl
                : widget.tutor.picture,
            currentUserId: conversation.participants.firstWhere(
              (participant) => participant != widget.tutor.uid,
              orElse: () => '',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  Future<void> _sendJoinRequest() async {
    setState(() {
      _isActionLoading = true;
    });

    try {
      await _studentTutorActionService.createBookingRequest(
        tutor: widget.tutor,
        service: widget.service,
        studentId: widget.selectedChild?.id,
        studentName: widget.selectedChild?.name,
        studentLevel: widget.selectedChild?.level,
      );
      if (!mounted) {
        return;
      }

      // Update local UI state for immediate feedback
      setState(() {
        final String? requestStudentId =
            widget.selectedChild?.id ?? _currentUserId;
        if (requestStudentId != null &&
            !widget.service.pendingIds.contains(requestStudentId)) {
          widget.service.pendingIds.add(requestStudentId);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Join request sent for ${widget.service.name}.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isActionLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String buttonText = 'Join Request';
    bool isActionDisabled = _isActionLoading;

    if (_currentUserId != null) {
      final String requestStudentId =
          widget.selectedChild?.id ?? _currentUserId!;
      if (widget.service.studentIds.contains(requestStudentId)) {
        buttonText = 'Joined';
        isActionDisabled = true;
      } else if (widget.service.pendingIds.contains(requestStudentId)) {
        buttonText = 'Pending';
        isActionDisabled = true;
      }
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xfff9f9f9),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          iconSize: 24,
          icon: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.black),
        ),
        title: const Text(
          "Service",
          style: TextStyle(
            fontFamily: "Inter",
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xff0f172a),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image(
                image: safeImage(
                  widget.service.picture,
                  defaultAsset: "assets/images/default_service_img.png",
                ),
                height: size.height * 0.25,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  "assets/images/default_service_img.png",
                  height: size.height * 0.25,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        widget.service.subject,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: "Inter",
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'STUDENTS',
                            widget.service.enrollednum.toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            'SESSIONS',
                            widget.service.sessionsnum.toString(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            'PRICE',
                            "${widget.service.price.toInt()}DA",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (widget.service.maxnum - widget.service.enrollednum <= 10)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              "assets/images/circle-alert.svg",
                              height: 18,
                              width: 18,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFFDD0D0D),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "${widget.service.maxnum - widget.service.enrollednum} places left",
                              style: const TextStyle(
                                color: Color(0xFFDD0D0D),
                                fontSize: 14,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildSectionContainer(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF000080),
                                size: 28,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Service Details',
                                style: TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontFamily: "Inter",
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          _buildDetailRow(
                            icon: SvgPicture.asset(
                              'assets/images/course.svg',
                              height: 20,
                              width: 20,
                            ),
                            label: 'DOMAIN',
                            value: widget.service.subject,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: const Icon(
                              Icons.school_outlined,
                              color: Color(0xFF000080),
                            ),
                            label: 'GRADE',
                            value: widget.service.level,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: const Icon(
                              Icons.access_time,
                              color: Color(0xFF000080),
                            ),
                            label: 'DURATION',
                            value: "${widget.service.duration}min/session",
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: const Icon(
                              Icons.devices_rounded,
                              color: Color(0xFF000080),
                            ),
                            label: 'COURSE TYPE',
                            value: widget.tutor.teachingMode,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: _buildDetailRow(
                                  icon: const Icon(
                                    Icons.location_on_outlined,
                                    color: Color(0xFF000080),
                                  ),
                                  label: 'LOCATION',
                                  value: widget.tutor.location,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          Mappage(initialTutor: widget.tutor),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  backgroundColor: const Color(0xFF000080),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Map',
                                  style: TextStyle(
                                    fontFamily: "Nunito",
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildSectionContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'About this Service',
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.service.description,
                            style: const TextStyle(
                              fontFamily: "Nunito",
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xFF4B5563),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildSectionContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Instructor',
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundImage: safeImage(
                                  widget.tutor.picture,
                                  defaultAsset: "assets/images/tutormale.png",
                                ),
                                radius: 32,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${widget.tutor.firstName} ${widget.tutor.lastName}",
                                      style: const TextStyle(
                                        fontFamily: "Inter",
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.tutor.expertiseDomain,
                                      style: const TextStyle(
                                        fontFamily: "Inter",
                                        fontWeight: FontWeight.w400,
                                        fontSize: 14,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF000080).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      "assets/images/star.svg",
                                      height: 14,
                                      width: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.tutor.averageRating.toString(),
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TutorProfilePage(
                                        tutorId: widget.tutor.uid,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'View profile',
                                  style: TextStyle(
                                    fontFamily: "Nunito",
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Color(0xFF000080),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _isActionLoading ? null : _openConversation,
                            icon: const Icon(Icons.message_outlined, size: 20),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFFF1F5F9),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            label: const Text(
                              'Message',
                              style: TextStyle(
                                fontFamily: "Nunito",
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: ElevatedButton.icon(
                            onPressed: isActionDisabled ? null : _sendJoinRequest,
                            icon: const ImageIcon(
                              AssetImage("assets/images/schedule.png"),
                              size: 20,
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: const Color(0xFF000080),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            label: Text(
                              buttonText,
                              style: const TextStyle(
                                fontFamily: "Nunito",
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Studenthomepage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CoursesPage()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatPage()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AccountScreen()),
            );
          } else {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

Widget _buildStatCard(String title, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontFamily: "Nunito",
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF000080),
            fontFamily: "Nunito",
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ],
    ),
  );
}

Widget _buildDetailRow({
  required Widget icon,
  required String label,
  required String value,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF000080).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SizedBox(height: 20, width: 20, child: Center(child: icon)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: "Nunito",
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontFamily: "Nunito",
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
