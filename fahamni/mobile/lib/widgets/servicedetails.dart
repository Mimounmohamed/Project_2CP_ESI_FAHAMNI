import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/messaging/conversation_page.dart';
import 'package:fahamni/Services/auth_.service.dart';
import 'package:fahamni/Services/student_tutor_action_service.dart';
import 'package:fahamni/Courses/courses_page.dart';
import 'package:fahamni/feedback/feedback_pages.dart';
import 'package:fahamni/widgets/customnavbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../StudentHomePage/Student_homepage.dart';
import 'package:fahamni/Account_Settings_Student/account_screen.dart';
import '../StudentHomePage/studenthome_service.dart';
import '../models/child_model.dart';
import '../models/parent_model.dart';
import '../models/service_model.dart';
import '../models/student_model.dart';
import '../models/tutor_model.dart';
import '../models/user_model.dart';

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
  final AuthService _authService = AuthService();
  final studenthomepage_service _studentHomeService = studenthomepage_service();
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
      StudentModel? selectedStudent;
      final UserModel? currentUser = await _authService.getCurrentUserProfile();
      if (currentUser?.role == UserRole.parent &&
          widget.selectedChild == null) {
        selectedStudent = await _pickChildForParent();
        if (selectedStudent == null) {
          return;
        }
      }

      await _studentTutorActionService.createBookingRequest(
        tutor: widget.tutor,
        service: widget.service,
        studentId: widget.selectedChild?.id ?? selectedStudent?.uid,
        studentName:
            widget.selectedChild?.name ??
            (selectedStudent == null
                ? null
                : '${selectedStudent.firstName} ${selectedStudent.lastName}'
                      .trim()),
        studentLevel:
            widget.selectedChild?.level ?? selectedStudent?.schoolLevel,
      );
      if (!mounted) {
        return;
      }

      // Update local UI state for immediate feedback
      setState(() {
        final String? requestStudentId =
            widget.selectedChild?.id ?? selectedStudent?.uid ?? _currentUserId;
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

  Future<StudentModel?> _pickChildForParent() async {
    final UserModel? profile = await _authService.getCurrentUserProfile();
    if (profile?.role != UserRole.parent) {
      return null;
    }

    final ParentModel parent = profile as ParentModel;
    List<StudentModel> children = await _studentHomeService.getLinkedChildren(
      parent.childrenUids,
    );
    if (children.isEmpty) {
      children = await _studentHomeService.getChildrenForParent(parent.uid);
    }
    if (!mounted) {
      return null;
    }
    if (children.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add or link a child first.')),
      );
      return null;
    }

    return showDialog<StudentModel>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select a child'),
        children: children
            .map(
              (child) => SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(child),
                child: Text(
                  child.firstName.isNotEmpty
                      ? '${child.firstName} ${child.lastName}'.trim()
                      : child.uid,
                ),
              ),
            )
            .toList(),
      ),
    );
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xfff9f9f9),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          iconSize: 24,
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
        ),
        title: const Text(
          "Service",
          style: TextStyle(
            fontFamily: "Inter",
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xff0f172a),
            height: 23 / 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              if (widget.service.picture != "")
                Image.network(
                  widget.service.picture,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              else
                Image.asset(
                  "assets/images/default_service_img.png",
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              SizedBox(height: 5),
              Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        widget.service.subject,
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: "Inter",
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double cardWidth =
                            (constraints.maxWidth - 146) / 2;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatCard(
                              'STUDENTS',
                              widget.service.enrollednum.toString(),
                              cardWidth,
                            ),
                            _buildStatCard(
                              'SESSIONS',
                              widget.service.sessionsnum.toString(),
                              cardWidth,
                            ),
                            _buildStatCard(
                              'PRICE',
                              "${widget.service.price.toInt()}DA",
                              cardWidth,
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 15),
                    if (widget.service.maxnum - widget.service.enrollednum <=
                        10)
                      Row(
                        children: [
                          SvgPicture.asset(
                            "assets/images/circle-alert.svg",
                            height: 20,
                            width: 20,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFFDD0D0D),
                              BlendMode.srcIn,
                            ),
                          ),
                          SizedBox(width: 5),
                          Text(
                            "${widget.service.maxnum - widget.service.enrollednum} places left",
                            style: TextStyle(
                              color: const Color(0xFFDD0D0D),
                              fontSize: 14,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w400,
                              height: 1.43,
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF000080).withValues(alpha: 0.2),
                            spreadRadius: 0.5,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Column fro the Services details
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF000080),
                                size: 30,
                              ),
                              SizedBox(width: 5),
                              Text(
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
                          SizedBox(height: 15),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(
                                    0xFF000080,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: SvgPicture.asset(
                                  'assets/images/course.svg',
                                  height: 20,
                                  width: 20,
                                ),
                              ),
                              SizedBox(width: 10),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DOMAIN',
                                    style: TextStyle(
                                      fontFamily: "Nunito",
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    widget.service.subject,
                                    style: TextStyle(
                                      fontFamily: "Nunito",
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(
                                    0xFF000080,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.school_outlined,
                                  color: Color(0xFF000080),
                                ),
                              ),
                              SizedBox(width: 10),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'GRADE',
                                    style: TextStyle(
                                      fontFamily: "Nuntio",
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    widget.service.level,
                                    style: TextStyle(
                                      fontFamily: "Nunito",
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 13),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(
                                    0xFF000080,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.access_time,
                                  color: Color(0xFF000080),
                                ),
                              ),
                              SizedBox(width: 10),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Duration',
                                    style: TextStyle(
                                      fontFamily: "Nunito",
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "${widget.service.duration}min/session",
                                    style: TextStyle(
                                      fontFamily: "Nunito",
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 13),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(
                                    0xFF000080,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.devices_rounded,
                                  color: Color(0xFF000080),
                                ),
                              ),
                              SizedBox(width: 10),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'COURSE TYPE',
                                    style: TextStyle(
                                      fontFamily: "Nunito",
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    widget.tutor.teachingMode,
                                    style: TextStyle(
                                      fontFamily: "Nunito",
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  SizedBox(height: 13),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(
                                    0xFF000080,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFF000080),
                                ),
                              ),
                              SizedBox(width: 10),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'LOCATION',
                                    style: TextStyle(
                                      fontFamily: "Nunito",
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    widget.tutor.location,
                                    style: TextStyle(
                                      fontFamily: "Nunito",
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 70),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                                  backgroundColor: Color(0xFF000080),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'See on map',
                                    style: TextStyle(
                                      fontFamily: "Nunito",
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF000080).withValues(alpha: 0.2),
                            spreadRadius: 0.5,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        // Column for the About this Service
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About this Service',
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            widget.service.description,
                            style: TextStyle(
                              fontFamily: "Nunito",
                              fontWeight: FontWeight.w400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF000080).withValues(alpha: 0.2),
                            spreadRadius: 0.5,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        // Column fro the Tutor
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instructor',
                            style: TextStyle(
                              color: Color(0xFF1F2937),
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(
                                  widget.tutor.picture,
                                ),
                                radius: 30,
                              ),
                              SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.tutor.firstName,
                                      style: TextStyle(
                                        fontFamily: "Inter",
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      widget.tutor.expertiseDomain,
                                      style: TextStyle(
                                        fontFamily: "Inter",
                                        fontWeight: FontWeight.w400,
                                        fontSize: 15,
                                        color: Color(0xFF464653),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          height: 25,
                                          width: 50,
                                          decoration: ShapeDecoration(
                                            color: Color(
                                              0xFF000080,
                                            ).withValues(alpha: 0.1),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                          child: Center(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                SvgPicture.asset(
                                                  "assets/images/star.svg",
                                                  height: 12,
                                                  width: 12,
                                                ),
                                                SizedBox(width: 2),
                                                Text(
                                                  widget.tutor.averageRating
                                                      .toString(),
                                                  style: TextStyle(
                                                    color: const Color(
                                                      0xFF1E293B,
                                                    ),
                                                    fontSize: 14,
                                                    fontFamily: 'Lexend',
                                                    fontWeight: FontWeight.w700,
                                                    height: 1.33,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    TutorProfilePage(
                                                      tutorId: widget.tutor.uid,
                                                    ),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            side: BorderSide(
                                              color: Color(
                                                0xFF000080,
                                              ).withValues(alpha: 0.2),
                                            ),
                                            padding: EdgeInsets.all(10),
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'View profile',
                                              style: TextStyle(
                                                fontFamily: "Nunito",
                                                fontWeight: FontWeight.w700,
                                                fontSize: 18,
                                                color: Color(0xFF000080),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _isActionLoading
                              ? null
                              : _openConversation,
                          icon: Icon(Icons.message_outlined),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
                            backgroundColor: Color(0xFFD2D2D2),
                            iconColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          label: Center(
                            child: Text(
                              'Message',
                              style: TextStyle(
                                fontFamily: "Nunito",
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: isActionDisabled ? null : _sendJoinRequest,
                          icon: ImageIcon(
                            AssetImage("assets/images/schedule.png"),
                            color: Colors.white,
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
                            backgroundColor: Color(0xFF000080),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          label: Center(
                            child: Text(
                              buttonText,
                              style: TextStyle(
                                fontFamily: "Nunito",
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
}

Widget _buildStatCard(String title, String value, double width) {
  return Container(
    height: 80,
    width: width,
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Color(0xFF000080).withValues(alpha: 0.2),
          spreadRadius: 0.5,
          blurRadius: 4,
          offset: Offset(0, 1),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: Color(0xFF64748B),
            fontFamily: "Nunito",
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            color: Color(0xFF000080),
            fontFamily: "Nunito",
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ],
    ),
  );
}
