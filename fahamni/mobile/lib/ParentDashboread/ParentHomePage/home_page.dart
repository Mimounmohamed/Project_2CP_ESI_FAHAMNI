import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fahamni/Account_Settings_Parent/account_screen.dart';
import 'package:fahamni/Notification_page/notification_page.dart';
import 'package:fahamni/ParentDashboread/ParentCoursePage/parent_courses_page.dart';
import 'package:fahamni/ParentDashboread/ParentExplorePage/parent_explore_page.dart';
import 'package:fahamni/Services/suspended_account_gate.dart';
import 'package:fahamni/StudentHomePage/studenthome_service.dart';
import 'package:fahamni/feedback/feedback_pages.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/models/child_model.dart';
import 'package:fahamni/models/parent_model.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:fahamni/models/user_model.dart';
import 'package:fahamni/widgets/customnavbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fahamni/ParentDashboread/ParentSchedulePage/parent_schedule_page.dart';

class Parentpage extends StatelessWidget {
  const Parentpage({super.key});

  @override
  Widget build(BuildContext context) => const Parenthomepage();
}

class Parenthomepage extends StatefulWidget {
  const Parenthomepage({super.key});

  @override
  State<Parenthomepage> createState() => _ParenthomepageState();
}

class _ParenthomepageState extends State<Parenthomepage> {
  final studenthomepage_service _service = studenthomepage_service();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> images = <String>[
    'assets/images/slide2.png',
    'assets/images/slide0.png',
    'assets/images/slide1.png',
  ];

  ParentModel? parent;
  // FIXED: children now come from the `children` collection as ChildModel,
  // not from `students` as StudentModel.
  List<ChildModel> linkedChildren = <ChildModel>[];
  List<TutorModel> favoriteTutors = <TutorModel>[];
  int currentIndex = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    loadParent();
  }

  // ---------------------------------------------------------------------------
  // FIXED: fetch children from the `children` Firestore collection using
  // parentUid, instead of looking them up in `students` by childrenUids.
  // ---------------------------------------------------------------------------
  Future<List<ChildModel>> _fetchChildren(String parentUid) async {
    final query = await _db
        .collection('children')
        .where('parentUid', isEqualTo: parentUid)
        .get();
    return query.docs.map((doc) => ChildModel.fromMap(doc.data())).toList();
  }

  Future<void> loadParent() async {
    try {
      final ParentModel parentData = await _service.getParentData();

      // Fetch children directly from `children` collection by parentUid.
      final List<ChildModel> children = await _fetchChildren(parentData.uid);

      // Load favorite tutors for this parent (treat parent like student).
      final List<TutorModel> tutors = await _service.getFavoriteTeachers(
        parentData.favoriteTeachers,
      );

      if (!mounted) return;

      setState(() {
        parent = parentData;
        linkedChildren = children;
        favoriteTutors = tutors;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        parent = ParentModel(
          uid: '',
          firstName: 'Error',
          lastName: '',
          email: '',
          phone: '',
          location: '',
          gender: Gender.male,
          birthday: DateTime.now(),
          accountStatus: AccountStatus.validated,
          isSuspended: false,
          childrenUids: const <String>[],
          favoriteTeachers: const <String>[],
          picture: '',
        );
      });
      debugPrint('loadParent error: $e');
    }
  }

  Widget _notificationButton(String? userId) {
    Widget button({bool hasUnread = false}) {
      return IconButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationPage()),
          );
        },
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const ImageIcon(
              AssetImage('assets/images/bell.png'),
              color: Colors.black,
            ),
            if (hasUnread)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        iconSize: 35,
      );
    }

    if (userId == null || userId.isEmpty) {
      return button();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection('notifications')
          .where('receiver_id', isEqualTo: userId)
          .where('is_read', isEqualTo: false)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        return button(hasUnread: (snapshot.data?.docs.isNotEmpty ?? false));
      },
    );
  }

  ImageProvider<Object> _avatarProvider({
    required String picture,
    required Gender gender,
  }) {
    if (picture.isNotEmpty) {
      if (picture.startsWith('http')) return NetworkImage(picture);
      return AssetImage(picture);
    }
    if (gender == Gender.male) {
      return const AssetImage('assets/images/parentmale.png');
    }
    return const AssetImage('assets/images/parentfemale.png');
  }

  ImageProvider<Object> _childAvatarProvider(ChildModel child) {
    if (child.picture.isNotEmpty) {
      if (child.picture.startsWith('http')) return NetworkImage(child.picture);
      return AssetImage(child.picture);
    }
    return child.isFemale
        ? const AssetImage('assets/images/childgirl.png')
        : const AssetImage('assets/images/chidboy.png');
  }

  void _openSchedulePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ParentSchedulePage()),
    );
  }

  void _handleBottomNavigation(int index) {
    if (index == _selectedIndex) return;

    if (index == 0) {
      setState(() => _selectedIndex = index);
      return;
    }

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ParentExplorePage()),
      );
      return;
    }

    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ParentCoursesPage()),
      );
      return;
    }

    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatPage()),
      );
      return;
    }

    if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ParentAccountScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (parent == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return SuspendedAccountGate(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 5, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Header row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: _avatarProvider(
                          picture: parent!.picture,
                          gender: parent!.gender,
                        ),
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 300),
                              child: Text(
                                '${parent?.firstName} ${parent?.lastName} ',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const Text(
                              'Parent',
                              style: TextStyle(
                                color: Color(0xFF000080),
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _notificationButton(parent?.uid),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search bar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(80),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: const Color(
                                  0xFF000080,
                                ).withValues(alpha: 0.2),
                                spreadRadius: 0,
                                blurRadius: 3,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: TextField(
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              hintText: 'Search for Teacher/Module...',
                              hintStyle: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(80),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 0,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 50,
                        width: 50,
                        child: Center(
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {},
                            icon: const ImageIcon(
                              AssetImage('assets/images/search.png'),
                              color: Colors.black,
                            ),
                            iconSize: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Carousel
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: CarouselSlider(
                          items: images
                              .map(
                                (item) => Stack(
                                  children: <Widget>[
                                    Container(
                                      margin: const EdgeInsets.all(5),
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        image: DecorationImage(
                                          image: AssetImage(item),
                                          fit: BoxFit.cover,
                                        ),
                                        boxShadow: <BoxShadow>[
                                          BoxShadow(
                                            color: const Color(
                                              0xFF000080,
                                            ).withValues(alpha: 77),
                                            spreadRadius: 1,
                                            blurRadius: 10,
                                            offset: const Offset(0, 0),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 18,
                                      left: 23,
                                      child: Container(
                                        constraints: const BoxConstraints(
                                          minHeight: 35,
                                          minWidth: 100,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'En Profiter',
                                            style: TextStyle(
                                              color: Color(0xFF000080),
                                              fontFamily: 'Nunito',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                          options: CarouselOptions(
                            height: 200,
                            autoPlay: true,
                            autoPlayInterval: const Duration(seconds: 3),
                            autoPlayAnimationDuration: const Duration(
                              milliseconds: 800,
                            ),
                            enlargeCenterPage: true,
                            aspectRatio: 16 / 9,
                            viewportFraction: 0.95,
                            enlargeFactor: 0.2,
                            enableInfiniteScroll: true,
                            clipBehavior: Clip.none,
                            padEnds: true,
                            onPageChanged: (index, reason) {
                              setState(() => currentIndex = index);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: images
                            .asMap()
                            .entries
                            .map(
                              (item) => Container(
                                height: 12,
                                width: 12,
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: currentIndex == item.key
                                      ? const Color(0xFF000080)
                                      : Colors.grey,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── Linked Children ──────────────────────────────────────────
                  Row(
                    children: const <Widget>[
                      Expanded(
                        child: Text(
                          'Linked Children',
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'See All',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF000080),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // FIXED: render ChildModel cards using child.displayName and
                  // child.subtitle — no more StudentModel field reads.
                  if (linkedChildren.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'No linked children yet.',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: linkedChildren
                          .map(
                            (child) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                  width: 1,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: const Color.fromARGB(
                                      255,
                                      0,
                                      0,
                                      128,
                                    ).withValues(alpha: 0.2),
                                    blurRadius: 3,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundImage: _childAvatarProvider(
                                      child,
                                    ),
                                    backgroundColor: const Color(0xFFF3F4F6),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          child.displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 20,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          child.subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Nunito',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 17,
                                            color: Color(0xFF000080),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 8),

                  // ── Favorite Teachers ────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Favorite Teachers',
                          style: TextStyle(
                            color: Color(0xFF1F2937),
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF000080),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 100,
                    child: favoriteTutors.isEmpty
                        ? const Center(
                            child: Text(
                              'NO Favorite Teachers :(',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            itemCount: favoriteTutors.length,
                            itemBuilder: (context, index) {
                              return Column(
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GestureDetector(
                                      onTap: () {
                                        final TutorModel tutor =
                                            favoriteTutors[index];
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TutorProfilePage(
                                              tutorId: tutor.uid,
                                            ),
                                          ),
                                        ).then((_) => loadParent());
                                      },
                                      child: Stack(
                                        children: <Widget>[
                                          Container(
                                            height: 60,
                                            width: 60,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                  favoriteTutors[index].picture,
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            left: 40,
                                            top: 45,
                                            child: Container(
                                              height: 14,
                                              width: 14,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                              ),
                                              child: Center(
                                                child: SvgPicture.asset(
                                                  'assets/images/heart.svg',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Text(
                                    favoriteTutors[index].firstName,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),

                  // ── Schedule CTA ─────────────────────────────────────────────
                  const Text(
                    'Courses Schedule',
                    style: TextStyle(
                      color: Color(0xFF1F2937),
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _openSchedulePage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF000080),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Check Full Schedule',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomNavbar(
          selectedIndex: _selectedIndex,
          onTap: _handleBottomNavigation,
        ),
      ),
    );
  }
}
