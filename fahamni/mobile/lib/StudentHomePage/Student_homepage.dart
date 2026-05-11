import 'package:carousel_slider/carousel_slider.dart';
import 'package:fahamni/StudentHomePage/studenthome_service.dart';
import 'package:fahamni/Explore_map_pages/explorepage.dart';
import 'package:fahamni/feedback/feedback_pages.dart';
import 'package:fahamni/Notification_page/notification_page.dart';
import 'package:fahamni/Courses/courses_page.dart';
import 'package:fahamni/Courses/schedule_page.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/Services/suspended_account_gate.dart';
import 'package:fahamni/models/session_model.dart';
import 'package:fahamni/models/student_model.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:fahamni/models/user_model.dart';
import 'package:fahamni/Account_Settings_Student/account_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fahamni/widgets/customnavbar.dart';
import 'package:intl/intl.dart';
import '../utils/image_utils.dart';
import 'favorite_teachers_page.dart';

class Studentpage extends StatelessWidget {
  const Studentpage({super.key});

  @override
  Widget build(BuildContext context) => const Studenthomepage();
}

class Studenthomepage extends StatefulWidget {
  const Studenthomepage({super.key});
  @override
  State<Studenthomepage> createState() => _StudenthomepageState();
}

class _StudenthomepageState extends State<Studenthomepage> {
  List<String> images = [
    'assets/images/slide2.png',
    'assets/images/slide0.png',
    'assets/images/slide1.png',
  ];
  
  int currentindex = 0;
  int counter = 0;
  int minutes = 0;
  String? mode;
  StudentModel? student;
  int _selectedIndex = 0;
  TutorModel? sessiontutor;
  List<TutorModel>? favoriteTutors = [];
  List<SessionModel>? courses = [];
  SessionModel? _nextCourse;
  @override
  void initState() {
    super.initState();
    loadStudent();
  }

  Future<void> loadStudent() async {
    try {
      final data = await studenthomepage_service().getStudentData();
      final tutors = await studenthomepage_service().getFavoriteTeachers(
        data.favoriteTeachers,
      );
      final sessions = await studenthomepage_service().getCourses(data.Courses);
      sessions.sort(
        (a, b) => _sessionDateTime(a).compareTo(_sessionDateTime(b)),
      );
      final DateTime now = DateTime.now();
      final SessionModel? nextSession = sessions
          .cast<SessionModel?>()
          .firstWhere(
            (session) =>
                session != null && _sessionDateTime(session).isAfter(now),
            orElse: () => sessions.isNotEmpty ? sessions.first : null,
          );
      final tutor = nextSession != null
          ? await studenthomepage_service().getTutorData(nextSession.tutorId)
          : null;
      if (!mounted) return;
      setState(() {
        student = data;
        favoriteTutors = tutors;
        courses = sessions;
        sessiontutor = tutor;
        _nextCourse = nextSession;
      });
      if (nextSession != null) {
        minutes = nextSession.endTime
            .difference(nextSession.startTime)
            .inMinutes;
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        student = StudentModel(
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
          picture: '',
          schoolLevel: '',
          learningObjectives: '',
          preferredSubjects: [],
          favoriteTeachers: [],
          Courses: [],
          grade: '',
          speciality: '',
        );
      });
      debugPrint('loadStudent error: $e');
    }
  }

  ImageProvider _resolveStudentAvatar(StudentModel s) {
    return safeImage(
      s.picture,
      defaultAsset: s.gender == Gender.female
          ? 'assets/images/studentfemale.png'
          : 'assets/images/studentmale.png',
    );
  }

  DateTime _sessionDateTime(SessionModel session) {
    return DateTime(
      session.date.year,
      session.date.month,
      session.date.day,
      session.startTime.hour,
      session.startTime.minute,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (student == null) {
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
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: _resolveStudentAvatar(student!),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${student?.firstName} ${student?.lastName}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              '${student?.role.name.toUpperCase()}',
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

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: const Color(0xFFF1F5F9),
                          ),
                          child: TextField(
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              hintText: 'Search for Teacher/module...',
                              hintStyle: const TextStyle(
                                fontFamily: "Nunito",
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                              ),
                              prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  CarouselSlider(
                    items: images
                        .map(
                          (item) => Stack(
                            children: [
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
                                      fontFamily: "Nunito",
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
                        setState(() {
                          currentindex = index;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: images.asMap().entries.map((entry) {
                      return Container(
                        width: currentindex == entry.key ? 20 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: currentindex == entry.key
                              ? const Color(0xFF000080)
                              : const Color(0xFFCBD5E1),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                                favoriteTutors: favoriteTutors ?? [],
                              ),
                            ),
                          ).then((_) => loadStudent());
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
                    child: (favoriteTutors?.isEmpty ?? true)
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
                            itemCount: favoriteTutors?.length,
                            itemBuilder: (context, index) {
                              final tutor = favoriteTutors![index];
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
                                    ).then((_) => loadStudent());
                                  },
                                  child: Column(
                                    children: [
                                      Stack(
                                        children: [
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Course Schedule',
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
                              builder: (_) => const SchedulePage(),
                            ),
                          );
                        },
                        child: const Text(
                          'See All',
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
                  if (courses?.isEmpty ?? true)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 48,
                            color: const Color(0xFF000080).withOpacity(0.2),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "No courses scheduled",
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Explorepage(student: student!),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF000080),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("Explore Tutors", style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    )
                  else if (sessiontutor != null && _nextCourse != null)
                    _NextCourseCard(
                      session: _nextCourse!,
                      tutor: sessiontutor!,
                      minutes: minutes,
                      onJoin: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SchedulePage(),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomNavbar(
          selectedIndex: _selectedIndex,
          onTap: (index) {
            if (index == _selectedIndex) return;
            if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Explorepage(student: student!)),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CoursesPage()),
              );
            } else if (index == 3) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ChatPage()),
              );
            } else if (index == 4) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AccountScreen()),
              ).then((_) => loadStudent());
            } else {
              setState(() {
                _selectedIndex = index;
              });
            }
          },
        ),
      ),
    );
  }
}

class _NextCourseCard extends StatelessWidget {
  const _NextCourseCard({
    required this.session,
    required this.tutor,
    required this.minutes,
    required this.onJoin,
  });

  final dynamic session;
  final dynamic tutor;
  final int minutes;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final bool isOnline = session.type == 'online';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000080).withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF000080).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'NEXT SESSION',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    color: Color(0xFF000080),
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session.type.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isOnline ? const Color(0xFF16A34A) : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            tutor.expertiseDomain,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEE, dd MMM yyyy').format(session.date),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time_outlined, size: 16, color: Color(0xFF000080)),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('HH:mm').format(session.startTime)} - ${DateFormat('HH:mm').format(session.endTime)} ($minutes min)',
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000080),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'View Sessions',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
