import 'dart:math' as math;

import 'package:fahamni/Services/auth_.service.dart';
import 'package:fahamni/Services/review_service.dart';
import 'package:fahamni/Services/student_tutor_action_service.dart';
import 'package:fahamni/feedback/quote_request_page.dart';
import 'package:fahamni/StudentHomePage/studenthome_service.dart';
import 'package:fahamni/models/report_model.dart';
import 'package:fahamni/models/review_model.dart';
import 'package:fahamni/models/parent_model.dart';
import 'package:fahamni/models/service_model.dart';
import 'package:fahamni/models/student_model.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:fahamni/models/tutor_review_bundle.dart';
import 'package:fahamni/models/user_model.dart';
import 'package:fahamni/messaging/conversation_page.dart';
import 'package:fahamni/widgets/servicedetails.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TutorProfilePage extends StatefulWidget {
  const TutorProfilePage({super.key, required this.tutorId});

  final String tutorId;

  @override
  State<TutorProfilePage> createState() => _TutorProfilePageState();
}

class _TutorProfilePageState extends State<TutorProfilePage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final studenthomepage_service _studentHomeService = studenthomepage_service();
  final ReviewService _reviewService = ReviewService();
  final StudentTutorActionService _studentTutorActionService =
      StudentTutorActionService();
  final TextEditingController _feedbackController = TextEditingController();
  late Future<TutorReviewBundle> _bundleFuture;
  late TabController _tabController;
  double _selectedRating = 0;
  bool _isSubmitting = false;
  bool _isFavorite = false;
  bool _isFavoriteLoading = true;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _bundleFuture = _reviewService.loadTutorReviewBundle(widget.tutorId);
    _tabController = TabController(length: 3, vsync: this);
    _loadFavoriteState();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final Future<TutorReviewBundle> future = _reviewService
        .loadTutorReviewBundle(widget.tutorId);
    setState(() {
      _bundleFuture = future;
    });
    await future;
  }

  Future<void> _loadFavoriteState() async {
    try {
      final bool isFavorite = await _studentTutorActionService.isFavoriteTutor(
        widget.tutorId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isFavorite = isFavorite;
        _isFavoriteLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isFavoriteLoading = false;
      });
    }
  }

  Future<void> _submitFeedback() async {
    FocusScope.of(context).unfocus();
    final String comment = _feedbackController.text.trim();
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating first.')),
      );
      return;
    }
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write your feedback first.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _reviewService.submitReview(
        tutorId: widget.tutorId,
        rating: _selectedRating,
        comment: comment,
      );
      _feedbackController.clear();
      setState(() {
        _selectedRating = 0;
      });
      await _refresh();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback sent successfully.')),
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
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    setState(() {
      _isFavoriteLoading = true;
    });

    try {
      final bool favorite = await _studentTutorActionService
          .toggleFavoriteTutor(widget.tutorId);
      if (!mounted) {
        return;
      }
      setState(() {
        _isFavorite = favorite;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            favorite
                ? 'Tutor added to favorites.'
                : 'Tutor removed from favorites.',
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
          _isFavoriteLoading = false;
        });
      }
    }
  }

  Future<void> _showReportTutorDialog(TutorModel tutor) async {
    final TextEditingController reportController = TextEditingController();
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 40,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 360),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Report',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            icon: const Icon(
                              Icons.close,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: TextFormField(
                          controller: reportController,
                          maxLength: 200,
                          maxLines: 8,
                          decoration: InputDecoration(
                            hintText: 'Write something ...',
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            counterText: '',
                          ),
                          onChanged: (_) {
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${reportController.text.length}/200',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final String reportText = reportController
                                      .text
                                      .trim();
                                  if (reportText.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please write your report before sending.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  setState(() {
                                    isSubmitting = true;
                                  });

                                  try {
                                    await _studentTutorActionService.createReport(
                                      reportedId: tutor.uid,
                                      reportedName:
                                          '${tutor.firstName} ${tutor.lastName}'
                                              .trim(),
                                      type: ReportType.teacher,
                                      text: reportText,
                                    );
                                    if (!mounted) return;
                                    Navigator.of(dialogContext).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Report submitted successfully.',
                                        ),
                                      ),
                                    );
                                  } catch (error) {
                                    if (!mounted) return;
                                    setState(() {
                                      isSubmitting = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(error.toString())),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF000080),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: isSubmitting
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'Send',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    reportController.dispose();
  }

  Future<void> _openConversation(TutorModel tutor) async {
    setState(() {
      _isActionLoading = true;
    });

    try {
      final conversation = await _studentTutorActionService
          .createOrGetConversation(tutor: tutor);
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationPage(
            conversation: conversation,
            imageUrl: conversation.participantAvatarUrl.isNotEmpty
                ? conversation.participantAvatarUrl
                : tutor.picture,
            currentUserId: conversation.participants.firstWhere(
              (participant) => participant != tutor.uid,
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

  Future<void> _bookSpecificService({
    required TutorModel tutor,
    required ServiceModel? service,
  }) async {
    setState(() {
      _isActionLoading = true;
    });

    try {
      final UserModel? currentUser = await _authService.getCurrentUserProfile();
      StudentModel? selectedStudent;
      if (currentUser?.role == UserRole.parent) {
        selectedStudent = await _pickChildForParent();
        if (selectedStudent == null) {
          return;
        }
      }

      await _studentTutorActionService.createBookingRequest(
        tutor: tutor,
        service: service,
        studentId: selectedStudent?.uid,
        studentName: selectedStudent == null
            ? null
            : '${selectedStudent.firstName} ${selectedStudent.lastName}'.trim(),
        studentLevel: selectedStudent?.schoolLevel,
      );
      final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (service != null &&
          currentUserId != null &&
          !service.pendingIds.contains(currentUserId) &&
          !service.studentIds.contains(currentUserId)) {
        setState(() {
          service.pendingIds.add(currentUserId);
        });
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            service == null
                ? 'Booking request sent to ${tutor.firstName}.'
                : 'Booking request sent for ${service.name}.',
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
    if (children.isEmpty || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add or link a child first.')),
      );
      return null;
    }

    return showDialog<StudentModel>(
      context: context,
      builder: (context) {
        return SimpleDialog(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: FutureBuilder<TutorReviewBundle>(
            future: _bundleFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return _FeedbackErrorState(
                  message: snapshot.error.toString(),
                  onRetry: _refresh,
                );
              }

              final TutorReviewBundle bundle = snapshot.data!;
              final TutorModel tutor = bundle.tutor;
              final List<ReviewModel> previewReviews = bundle.reviews
                  .take(2)
                  .toList();

              return AnimatedPadding(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileTopBar(
                      tutorName: 'Teacher',
                      isFavorite: _isFavorite,
                      isFavoriteLoading: _isFavoriteLoading,
                      onFavoriteTap: _toggleFavorite,
                      onReportTap: () => _showReportTutorDialog(tutor),
                    ),
                    const SizedBox(height: 18),
                    _TutorHero(
                      tutor: tutor,
                      averageRating: bundle.averageRating,
                      reviewService: _reviewService,
                    ),
                    const SizedBox(height: 18),
                    TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF000080),
                      unselectedLabelColor: const Color(0xFF64748B),
                      indicatorColor: const Color(0xFF000080),
                      labelStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      tabs: const [
                        Tab(text: 'About'),
                        Tab(text: 'Services'),
                        Tab(text: 'Reviews'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refresh,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _AboutTutorTab(tutor: tutor),
                            _TutorServicesTab(
                              tutor: tutor,
                              services: bundle.services,
                              reviewService: _reviewService,
                              onBookNow: (service) => _bookSpecificService(
                                tutor: tutor,
                                service: service,
                              ),
                            ),
                            ListView(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.only(bottom: 16),
                              children: [
                                _RatingsSummaryCard(
                                  tutor: tutor,
                                  reviews: previewReviews,
                                  reviewers: bundle.reviewers,
                                  averageRating: bundle.averageRating,
                                  reviewService: _reviewService,
                                  totalReviewsCount: bundle.reviews.length,
                                  onViewAll: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => FeedbacksPage(
                                          tutorId: widget.tutorId,
                                          tutorName:
                                              '${tutor.firstName} ${tutor.lastName}'
                                                  .trim(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                                _FeedbackComposerCard(
                                  controller: _feedbackController,
                                  selectedRating: _selectedRating,
                                  onRatingChanged: (value) {
                                    setState(() {
                                      _selectedRating = value;
                                    });
                                  },
                                  onSubmit: _submitFeedback,
                                  isSubmitting: _isSubmitting,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!keyboardVisible) ...[
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isActionLoading
                                  ? null
                                  : () => _openConversation(tutor),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD9D9D9),
                                foregroundColor: const Color(0xFF1F2937),
                                minimumSize: const Size(0, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              icon: const Icon(Icons.message_outlined),
                              label: const Text(
                                'Message',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isActionLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => QuoteRequestPage(
                                            tutor: tutor,
                                            services: bundle.services,
                                          ),
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF000080),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: const Text(
                                'Quote request',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class FeedbacksPage extends StatefulWidget {
  const FeedbacksPage({
    super.key,
    required this.tutorId,
    required this.tutorName,
  });

  final String tutorId;
  final String tutorName;

  @override
  State<FeedbacksPage> createState() => _FeedbacksPageState();
}

class _FeedbacksPageState extends State<FeedbacksPage> {
  final ReviewService _reviewService = ReviewService();
  final StudentTutorActionService _studentTutorActionService =
      StudentTutorActionService();
  final Set<String> _reportingReviewIds = <String>{};

  bool get _canReportFeedback =>
      FirebaseAuth.instance.currentUser?.uid == widget.tutorId;

  Future<void> _reportFeedback(
    ReviewModel review,
    StudentModel? reviewer,
  ) async {
    if (_reportingReviewIds.contains(review.reviewId)) return;

    setState(() {
      _reportingReviewIds.add(review.reviewId);
    });

    final String reportedName = reviewer == null
        ? 'Student'
        : '${reviewer.firstName} ${reviewer.lastName}'.trim();

    try {
      await _studentTutorActionService.createReport(
        reportedId: review.reviewerId,
        reportedName: reportedName.isEmpty ? 'Student' : reportedName,
        type: ReportType.comment,
        text: review.comment,
        extraData: <String, dynamic>{
          'review_id': review.reviewId,
          'rating': review.rating,
          'reported_role': 'student',
          'reporter_role': 'teacher',
          'created_at': Timestamp.fromDate(DateTime.now()),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback reported successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _reportingReviewIds.remove(review.reviewId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Feedbacks',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: StreamBuilder<List<ReviewModel>>(
        stream: _reviewService.getTutorReviews(widget.tutorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<ReviewModel> reviews = snapshot.data ?? <ReviewModel>[];
          return FutureBuilder<Map<String, StudentModel>>(
            future: _reviewService.getReviewers(
              reviews.map((review) => review.reviewerId).toList(),
            ),
            builder: (context, reviewerSnapshot) {
              final Map<String, StudentModel> reviewers =
                  reviewerSnapshot.data ?? <String, StudentModel>{};

              if (reviews.isEmpty) {
                return const Center(
                  child: Text(
                    'No feedback yet.',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: reviews.length,
                separatorBuilder: (_, separatorIndex) =>
                    const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final ReviewModel review = reviews[index];
                  return _ReviewCard(
                    review: review,
                    reviewer: reviewers[review.reviewerId],
                    reviewService: _reviewService,
                    onReport: _canReportFeedback
                        ? () => _reportFeedback(
                            review,
                            reviewers[review.reviewerId],
                          )
                        : null,
                    isReporting: _reportingReviewIds.contains(review.reviewId),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({
    required this.tutorName,
    required this.isFavorite,
    required this.isFavoriteLoading,
    required this.onFavoriteTap,
    required this.onReportTap,
  });

  final String tutorName;
  final bool isFavorite;
  final bool isFavoriteLoading;
  final VoidCallback onFavoriteTap;
  final VoidCallback onReportTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
        ),
        Expanded(
          child: Text(
            tutorName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        _CircleIconButton(
          icon: isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          iconColor: isFavorite
              ? const Color(0xFFEF4444)
              : const Color(0xFF64748B),
          onTap: isFavoriteLoading ? null : onFavoriteTap,
          child: isFavoriteLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
        ),
        const SizedBox(width: 8),
        const _CircleIconButton(icon: Icons.share_outlined),
        const SizedBox(width: 8),
        PopupMenuButton<int>(
          onSelected: (value) {
            if (value == 0) {
              onReportTap();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem<int>(value: 0, child: Text('Report tutor')),
          ],
          icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}

class _TutorHero extends StatelessWidget {
  const _TutorHero({
    required this.tutor,
    required this.averageRating,
    required this.reviewService,
  });

  final TutorModel tutor;
  final double averageRating;
  final ReviewService reviewService;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 62,
          backgroundColor: const Color(0xFFE2E8F0),
          backgroundImage: _resolveImageProvider(tutor.picture),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                '${tutor.firstName} ${tutor.lastName}'.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.verified_outlined,
              color: Color(0xFF000080),
              size: 22,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${tutor.expertiseDomain} Specialist',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000080),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            _MetaText(
              text: '${averageRating.toStringAsFixed(1)} Rating',
              color: const Color(0xFF64748B),
              leading: const Icon(
                Icons.star_rounded,
                size: 16,
                color: Color(0xFFF4B400),
              ),
            ),
            _MetaText(
              text: reviewService.experienceLabel(tutor.yearsOfExperience),
              color: const Color(0xFF64748B),
            ),
            _MetaText(
              text: reviewService.availabilityLabel(tutor.isAvailable),
              color: tutor.isAvailable
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
            ),
          ],
        ),
      ],
    );
  }
}

class _AboutTutorTab extends StatelessWidget {
  const _AboutTutorTab({required this.tutor});

  final TutorModel tutor;

  @override
  Widget build(BuildContext context) {
    final String levelsTaught = tutor.levelsTaught.isEmpty
        ? 'Not specified'
        : tutor.levelsTaught.join(', ');

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(overscroll: false),
      child: ListView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatCard('Rating', tutor.averageRating.toStringAsFixed(1)),
              _buildStatCard('Years', '${tutor.yearsOfExperience}+'),
              _buildStatCard('Courses', '${tutor.levelsTaught.length}'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: _profileCardDecoration(),
            child: Column(
              children: [
                Row(
                  children: [
                    Transform.rotate(
                      angle: math.pi,
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFF000080),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Details & Expertise',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoCard(
                  Icons.menu_book,
                  'Expertise Domain',
                  tutor.expertiseDomain,
                ),
                _buildInfoCard(
                  Icons.school_outlined,
                  'Levels Taught',
                  levelsTaught,
                ),
                _buildInfoCard(
                  Icons.location_on_outlined,
                  'Location',
                  tutor.location,
                ),
                _buildInfoCard(
                  Icons.devices_rounded,
                  'Teaching Mode',
                  tutor.teachingMode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildTextCard(
            'Academic Background',
            tutor.academicDescription.isNotEmpty
                ? tutor.academicDescription
                : 'No academic background provided yet.',
          ),
          const SizedBox(height: 16),
          _buildTextCard(
            'Teaching Approach',
            tutor.pedagogicalDescription.isNotEmpty
                ? tutor.pedagogicalDescription
                : 'No teaching approach provided yet.',
          ),
        ],
      ),
    );
  }
}

class _TutorServicesTab extends StatelessWidget {
  const _TutorServicesTab({
    required this.tutor,
    required this.services,
    required this.reviewService,
    required this.onBookNow,
  });

  final TutorModel tutor;
  final List<ServiceModel> services;
  final ReviewService reviewService;
  final ValueChanged<ServiceModel> onBookNow;

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (services.isEmpty) {
      return const Center(
        child: Text(
          'No services yet.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(overscroll: false),
      child: ListView.builder(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 64),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final ServiceModel service = services[index];
          final String serviceMode = service.area.isNotEmpty
              ? service.area
              : tutor.teachingMode;
          final bool isJoined =
              currentUserId != null &&
              service.studentIds.contains(currentUserId);
          final bool isPending =
              currentUserId != null &&
              service.pendingIds.contains(currentUserId);
          final String actionLabel = isJoined
              ? 'Joined'
              : isPending
              ? 'Pending'
              : 'Book Now';
          final bool isActionDisabled = isJoined || isPending;

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      Servicedetails(tutor: tutor, service: service),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Card(
                elevation: 6,
                shadowColor: const Color(0xFF000080).withValues(alpha: 0.3),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ServiceHeaderImage(imagePath: service.picture),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 23,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0x19000080),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Center(
                                  child: Text(
                                    service.subject,
                                    style: const TextStyle(
                                      color: Color(0xFF000080),
                                      fontSize: 13,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w700,
                                      height: 1.50,
                                      letterSpacing: 0.50,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                service.name,
                                style: const TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontSize: 18,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  height: 1.38,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.access_time_rounded,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    '${service.duration}min session',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 14,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w400,
                                      height: 1.43,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    serviceMode,
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 14,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w400,
                                      height: 1.43,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (service.maxnum - service.enrollednum <= 10)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFDD0D0D),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${service.maxnum - service.enrollednum} places left',
                                      style: const TextStyle(
                                        color: Color(0xFFDD0D0D),
                                        fontSize: 14,
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w400,
                                        height: 1.43,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    '${service.price.toInt()}DA',
                                    style: const TextStyle(
                                      color: Color(0xFF000080),
                                      fontSize: 20,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w700,
                                      height: 1.56,
                                    ),
                                  ),
                                  const Expanded(child: SizedBox()),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 16),
                                    child: ElevatedButton(
                                      onPressed: isActionDisabled
                                          ? null
                                          : () => onBookNow(service),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF000080,
                                        ),
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size(100, 40),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          actionLabel,
                                          style: TextStyle(
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            fontSize: 15,
                                          ),
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
                    Positioned(
                      top: 15,
                      right: 16,
                      child: Container(
                        height: 25,
                        width: 50,
                        decoration: ShapeDecoration(
                          color: Colors.white.withValues(alpha: 0.90),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_border_outlined,
                                color: Color(0xFFEAB308),
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                tutor.averageRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 14,
                                  fontFamily: 'Nunito',
                                  fontWeight: FontWeight.w700,
                                  height: 1.33,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

BoxDecoration _profileCardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: const Color(0xFFF1F5F9)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF000080).withValues(alpha: 0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

Widget _buildStatCard(String title, String value) {
  return Container(
    padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
    width: 110,
    decoration: _profileCardDecoration(),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF000080),
          ),
        ),
      ],
    ),
  );
}

Widget _buildInfoCard(IconData icon, String title, String value) {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF000080).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: const Color(0xFF000080)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildTextCard(String title, String value) {
  return Container(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
    decoration: _profileCardDecoration(),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    ),
  );
}

class _ServiceHeaderImage extends StatelessWidget {
  const _ServiceHeaderImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath.trim().startsWith('http://') ||
        imagePath.trim().startsWith('https://')) {
      return Image.network(
        imagePath,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          "assets/images/default_service_img.png",
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    if (imagePath.trim().startsWith('assets/')) {
      return Image.asset(
        imagePath,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    return Image.asset(
      "assets/images/default_service_img.png",
      height: 120,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}

class _RatingsSummaryCard extends StatelessWidget {
  const _RatingsSummaryCard({
    required this.tutor,
    required this.reviews,
    required this.reviewers,
    required this.averageRating,
    required this.reviewService,
    required this.totalReviewsCount,
    required this.onViewAll,
  });

  final TutorModel tutor;
  final List<ReviewModel> reviews;
  final Map<String, StudentModel> reviewers;
  final double averageRating;
  final ReviewService reviewService;
  final int totalReviewsCount;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Ratings & Reviews',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            averageRating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(width: 6),
          _StarsRow(rating: averageRating, size: 18),
        ],
      ),
      child: Column(
        children: [
          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                'No reviews yet.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            )
          else
            ...List<Widget>.generate(reviews.length, (index) {
              final ReviewModel review = reviews[index];
              final StudentModel? reviewer = reviewers[review.reviewerId];
              return Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reviewer == null
                                    ? 'Student'
                                    : '${reviewer.firstName} ${reviewer.lastName[0]}.',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (review.isHidden)
                                const Text(
                                  'Comment hidden by admin.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFF94A3B8),
                                  ),
                                )
                              else
                                Text(
                                  '"${review.comment}"',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          reviewService.formatShortDate(review.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (index != reviews.length - 1) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 16),
                  ],
                ],
              );
            }),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onViewAll,
            child: Text(
              'View all $totalReviewsCount reviews',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF000080),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackComposerCard extends StatelessWidget {
  const _FeedbackComposerCard({
    required this.controller,
    required this.selectedRating,
    required this.onRatingChanged,
    required this.onSubmit,
    required this.isSubmitting,
  });

  final TextEditingController controller;
  final double selectedRating;
  final ValueChanged<double> onRatingChanged;
  final VoidCallback onSubmit;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Your Feedback',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: _StarSelector(
              selectedRating: selectedRating,
              onChanged: onRatingChanged,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE9EAFB),
              borderRadius: BorderRadius.circular(18),
            ),
            child: TextField(
              controller: controller,
              maxLength: 200,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              decoration: const InputDecoration(
                hintText: 'Write something...',
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                return Text(
                  '${value.text.characters.length}/200',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                foregroundColor: Colors.white,
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.reviewer,
    required this.reviewService,
    this.onReport,
    this.isReporting = false,
  });

  final ReviewModel review;
  final StudentModel? reviewer;
  final ReviewService reviewService;
  final VoidCallback? onReport;
  final bool isReporting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFE2E8F0),
                backgroundImage: reviewer == null
                    ? null
                    : _resolveImageProvider(reviewer!.picture),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reviewer == null
                          ? 'Student'
                          : '${reviewer!.firstName} ${reviewer!.lastName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    _StarsRow(rating: review.rating, size: 16),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    reviewService.formatShortDate(review.createdAt),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  if (onReport != null) ...[
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: isReporting ? null : onReport,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(isReporting ? 'Reporting...' : 'Report'),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (review.isHidden)
            const Text(
              'Comment hidden by admin.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Color(0xFF94A3B8),
              ),
            )
          else
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF475569),
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              if (trailing case final Widget trailingWidget) trailingWidget,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _FeedbackErrorState extends StatelessWidget {
  const _FeedbackErrorState({required this.message, required this.onRetry});

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
            const Icon(
              Icons.rate_review_outlined,
              size: 48,
              color: Color(0xFF000080),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                onRetry();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
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

class _MetaText extends StatelessWidget {
  const _MetaText({required this.text, required this.color, this.leading});

  final String text;
  final Color color;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 4)],
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StarSelector extends StatelessWidget {
  const _StarSelector({required this.selectedRating, required this.onChanged});

  final double selectedRating;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(5, (index) {
        final double starValue = index + 1;
        final bool isSelected = starValue <= selectedRating;
        return IconButton(
          onPressed: () => onChanged(starValue),
          icon: Icon(
            isSelected ? Icons.star_rounded : Icons.star_border_rounded,
            color: const Color(0xFFF4B400),
            size: 34,
          ),
        );
      }),
    );
  }
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.rating, required this.size});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final int fullStars = rating.round().clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(5, (index) {
        return Icon(
          index < fullStars ? Icons.star_rounded : Icons.star_border_rounded,
          color: const Color(0xFFF4B400),
          size: size,
        );
      }),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    this.iconColor = const Color(0xFF64748B),
    this.onTap,
    this.child,
  });

  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          color: Colors.white,
        ),
        child: child ?? Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

ImageProvider<Object>? _resolveImageProvider(String path) {
  final String normalized = path.trim();
  if (normalized.isEmpty) {
    return null;
  }
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return NetworkImage(normalized);
  }
  if (normalized.startsWith('assets/')) {
    return AssetImage(normalized);
  }
  return null;
}
