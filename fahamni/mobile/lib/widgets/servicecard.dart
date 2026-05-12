import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../models/service_model.dart';
import '../models/tutor_model.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import '../models/parent_model.dart';
import 'package:fahamni/Services/auth_.service.dart';
import 'package:fahamni/Services/student_tutor_action_service.dart';
import '../StudentHomePage/studenthome_service.dart';
import '../utils/image_utils.dart';

class ServiceCard extends StatefulWidget {
  const ServiceCard({
    super.key,
    required this.tutor,
    required this.service,
    this.showBookButton = true,
    this.primaryActionLabel = 'Book Now',
    this.onPrimaryAction,
    this.trailingActions,
    this.bottomContentPadding = 0,
  });

  final TutorModel tutor;
  final ServiceModel service;
  final bool showBookButton;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final Widget? trailingActions;
  final double bottomContentPadding;

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
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

  Future<void> _sendJoinRequest() async {
    setState(() {
      _isActionLoading = true;
    });

    try {
      StudentModel? selectedStudent;
      final UserModel? currentUser = await _authService.getCurrentUserProfile();
      if (currentUser?.role == UserRole.parent) {
        selectedStudent = await _pickChildForParent();
        if (selectedStudent == null) {
          return;
        }
      }
      final bool isParent = currentUser?.role == UserRole.parent;

      await _studentTutorActionService.createBookingRequest(
        tutor: widget.tutor,
        service: widget.service,
        studentId: isParent ? selectedStudent?.uid : _currentUserId,
        studentName:
            (isParent ? null : null) ??
            (selectedStudent == null
                ? null
                : '${selectedStudent.firstName} ${selectedStudent.lastName}'
                      .trim()),
        studentLevel: isParent
            ? selectedStudent?.schoolLevel
            : null,
      );
      if (!mounted) {
        return;
      }

      // Update local UI state for immediate feedback
      setState(() {
        final String? requestStudentId =
            (isParent ? selectedStudent?.uid : null) ??
            _currentUserId;
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
    final int placesLeft = widget.service.maxnum - widget.service.enrollednum;
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    String actionLabel = widget.primaryActionLabel;
    bool isActionDisabled = _isActionLoading;

    if (currentUserId != null) {
      if (widget.service.studentIds.contains(currentUserId)) {
        actionLabel = 'Joined';
        isActionDisabled = true;
      } else if (widget.service.pendingIds.contains(currentUserId)) {
        actionLabel = 'Pending';
        isActionDisabled = true;
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000080).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _ServiceHeaderImage(imagePath: widget.service.picture),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          widget.tutor.averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 11,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + widget.bottomContentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF000080).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.service.subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF000080),
                              fontSize: 10,
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: const Color(0xFFF1F5F9),
                        backgroundImage: safeImage(
                          widget.tutor.picture,
                          defaultAsset: widget.tutor.gender.name == 'female'
                              ? 'assets/images/tutorfemale.png'
                              : 'assets/images/tutormale.png',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${widget.tutor.firstName} ${widget.tutor.lastName}",
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 12,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${widget.service.duration} min session',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 18,
                    child: placesLeft <= 10 
                      ? Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$placesLeft places left',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 11,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        )
                      : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${widget.service.price.toInt()}DA',
                        style: const TextStyle(
                          color: Color(0xFF000080),
                          fontSize: 16,
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      if (widget.trailingActions != null) widget.trailingActions!,
                      if (widget.showBookButton)
                        ElevatedButton(
                          onPressed: isActionDisabled
                                ? null
                                : _sendJoinRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF000080),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(70, 32),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            actionLabel,
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
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
    );
  }
}

class _ServiceHeaderImage extends StatelessWidget {
  const _ServiceHeaderImage({required this.imagePath});
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: double.infinity,
      child: Image(
        image: safeImage(imagePath, defaultAsset: 'assets/images/default_service_img.png'),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/images/default_service_img.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
