import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fahamni/Account_Settings_Parent/account_screen.dart';
import 'package:fahamni/Account_Settings_Parent/linked_childs_screen.dart';
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
import '../../utils/image_utils.dart';
import '../../StudentHomePage/favorite_teachers_page.dart';

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
  List<ChildModel> linkedChildren = <ChildModel>[];
  List<TutorModel> favoriteTutors = <TutorModel>[];
  int currentIndex = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    loadParent();
  }

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
      final List<ChildModel> children = await _fetchChildren(parentData.uid);
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

  ImageProvider<Object> _avatarProvider(ParentModel p) {
    return safeImage(
      p.picture,
      defaultAsset: p.gender == Gender.female
          ? 'assets/images/parentfemale.png'
          : 'assets/images/parentmale.png',
    );
  }

  ImageProvider<Object> _childAvatarProvider(ChildModel child) {
    return safeImage(
      child.picture,
      defaultAsset: child.isFemale
          ? 'assets/images/childgirl.png'
          : 'assets/images/chidboy.png',
    );
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
      ).then((_) => loadParent());
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
                        backgroundImage: _avatarProvider(parent!),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${parent?.firstName} ${parent?.lastName}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'PARENT',
                              style: const TextStyle(
                                color: Color(0xFF000080),
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationPage(),
                            ),
                          );
                        },
                        icon: const ImageIcon(
                          AssetImage('assets/images/bell.png'),
                          color: Colors.black,
                        ),
                        iconSize: 28,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Search bar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: const Color(0xFFF1F5F9),
                          ),
                          child: const TextField(
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              hintText: 'Search for Teacher/Module...',
                              hintStyle: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                              ),
                              prefixIcon: Icon(Icons.search, color: Color(0xFF64748B)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Carousel
                  CarouselSlider(
                    items: images
                        .map(
                          (item) => Stack(
                            children: <Widget>[
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 5),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  image: DecorationImage(
                                    image: AssetImage(item),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 15,
                                left: 20,
                                child: ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF000080),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text(
                                    'En Profiter',
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                    options: CarouselOptions(
                      height: 180,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      viewportFraction: 0.9,
                      onPageChanged: (index, reason) {
                        setState(() => currentIndex = index);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: images.asMap().entries.map((entry) {
                      return Container(
                        width: currentIndex == entry.key ? 20 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: currentIndex == entry.key
                              ? const Color(0xFF000080)
                              : const Color(0xFFCBD5E1),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 25),

                  // ── Linked Children ──────────────────────────────────────────
                  Row(
                    children: <Widget>[
                      const Expanded(
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
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LinkedChildsScreen(),
                            ),
                          ).then((_) => loadParent());
                          // Handle "See All" tap
                        },
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
                  const SizedBox(height: 10),

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
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: <Widget>[
                                  CircleAvatar(
                                    radius: 25,
                                    backgroundImage: _childAvatarProvider(
                                      child,
                                    ),
                                    backgroundColor: const Color(0xFFF1F5F9),
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
                  const SizedBox(height: 20),

                  // ── Favorite Teachers ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      const Text(
                        'Favorite Teachers',
                        style: TextStyle(
                          color: Colors.black,
                          fontFamily: "Inter",
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FavoriteTeachersPage(
                                favoriteTutors: favoriteTutors,
                              ),
                            ),
                          ).then((_) => loadParent());
                        },
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            fontFamily: "Nunito",
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF000080),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: favoriteTutors.isEmpty
                        ? const Center(
                            child: Text(
                              'No favorite teachers yet',
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: favoriteTutors.length,
                            itemBuilder: (context, index) {
                              final tutor = favoriteTutors[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 15),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => TutorProfilePage(
                                          tutorId: tutor.uid,
                                        ),
                                      ),
                                    ).then((_) => loadParent());
                                  },
                                  child: Column(
                                    children: <Widget>[
                                      Stack(
                                        children: <Widget>[
                                          CircleAvatar(
                                            radius: 35,
                                            backgroundImage: safeImage(
                                              tutor.picture,
                                              defaultAsset: tutor.gender == Gender.female
                                                ? 'assets/images/tutorfemale.png'
                                                : 'assets/images/tutormale.png',
                                            ),
                                          ),
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black12,
                                                    blurRadius: 4,
                                                  )
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.favorite,
                                                color: Colors.red,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        tutor.firstName,
                                        style: const TextStyle(
                                          color: Color(0xFF1F2937),
                                          fontFamily: "Nunito",
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 20),

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
                  const SizedBox(height: 20),
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
