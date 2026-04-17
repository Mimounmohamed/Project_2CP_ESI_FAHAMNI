import 'package:carousel_slider/carousel_slider.dart';
import 'package:fahamni/StudentHomePage/studenthome_service.dart';
import 'package:fahamni/Explore_map_pages/explorepage.dart';
import 'package:fahamni/feedback/feedback_pages.dart';
import 'package:fahamni/Notification_page/notification_page.dart';
import 'package:fahamni/Courses/courses_page.dart';
import 'package:fahamni/Courses/schedule_page.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/models/session_model.dart';
import 'package:fahamni/models/student_model.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:fahamni/models/user_model.dart';
import 'package:fahamni/student_profile/student_account_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fahamni/widgets/customnavbar.dart';
import 'package:intl/intl.dart';

class Studentpage extends StatelessWidget {
  const Studentpage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      ),
      home: const Studenthomepage(),
    );
  }
}

class Studenthomepage extends StatefulWidget {
  const  Studenthomepage({super.key});
  @override
  State<Studenthomepage> createState() => _StudenthomepageState();
}

class _StudenthomepageState extends State<Studenthomepage> {
  List<String> images = [
    'assets/images/slide2.png',
    'assets/images/slide0.png',
    'assets/images/slide1.png',
  ];
  final List<Map<String, dynamic>> teachers = [
    {
      'name': 'Sami',
      'image': 'https://randomuser.me/api/portraits/women/44.jpg',
    },
    {
      'name': 'Sami',
      'image': 'https://randomuser.me/api/portraits/men/32.jpg',
    },
    {
      'name': 'Sami',
      'image': 'https://randomuser.me/api/portraits/women/68.jpg',
    },
    {
      'name': 'Sami',
      'image': 'https://randomuser.me/api/portraits/men/75.jpg',
    },
    {
      'name': 'Sami',
      'image': 'https://randomuser.me/api/portraits/women/17.jpg',
    },
    {
      'name': 'Sami',
      'image': 'https://randomuser.me/api/portraits/men/52.jpg',
    },
  ];
  int currentindex=0;
  int counter = 0;
  int minutes = 0;
  String ? mode ;
  StudentModel ? student ;
  int _selectedIndex = 0;
  TutorModel ? sessiontutor;
  List<TutorModel> ? favoriteTutors = [];
  List<SessionModel> ? courses = [];
  SessionModel? _nextCourse;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadStudent();
  }
  Future<void> loadStudent() async {
  try {
    final data = await studenthomepage_service().getStudentData();
    final tutors = await studenthomepage_service().getFavoriteTeachers(data.favoriteTeachers);
    final sessions = await studenthomepage_service().getCourses(data.Courses);
    sessions.sort((a,b) => _sessionDateTime(a).compareTo(_sessionDateTime(b)));
    final DateTime now = DateTime.now();
    final SessionModel? nextSession = sessions.cast<SessionModel?>().firstWhere(
      (session) => session != null && _sessionDateTime(session).isAfter(now),
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
      minutes = nextSession.endTime.difference(nextSession.startTime).inMinutes;
    }
  } catch (e) {
    if (!mounted) return;
    setState(() {
      student = StudentModel(  // set a fallback so spinner stops
        uid: '', firstName: 'Error', lastName: '',
        email: '', phone: '', location: '',
        gender: Gender.male, birthday: DateTime.now(),
        accountStatus: AccountStatus.validated,
        picture: '', schoolLevel: '', learningObjectives: '',
        preferredSubjects: [], favoriteTeachers: [], Courses: [],
      );
    });
    debugPrint('loadStudent error: $e');
  }
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
          margin: EdgeInsets.fromLTRB(16, 5, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row with avatar and icons
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if(student!.picture != "")
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage(student!.picture),
                  )
                  else
                    if (student!.gender == Gender.male)
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage('assets/images/studentmale.png'),
                     )
                    else
                     CircleAvatar(
                       radius: 25,
                       backgroundImage: AssetImage('assets/images/studentfemale.png'),
                       backgroundColor: Colors.white,
                     ),
                  SizedBox(width: 5),
                  Expanded( // Wrap with Expanded to take available space
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 300),
                          child: Text(
                            '${student?.firstName} ${student?.lastName} ',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFF1F2937),
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          '${student?.role.name}',
                          style: TextStyle(
                            color: const Color(0xFF000080),
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
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
                    icon: ImageIcon(
                      AssetImage('assets/images/bell.png'),
                      color: Colors.black,
        ),
                    iconSize: 35,
                  ),
                ],
              ),
              SizedBox(height: 5),

              // Search row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded( // Expanded makes TextField take full width
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(80),
                        boxShadow: [ BoxShadow(
                          color: Color(0xFF000080).withOpacity(0.61),
                          spreadRadius: 0,
                          blurRadius: 5,
                          offset: const Offset(0,0),
                          blurStyle: BlurStyle.normal,

                        )
                        ],
                      ),
                      child: TextField(
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: 'Search for Teacher/module...',
                          hintStyle: TextStyle(
                            fontFamily: "Nunito",
                            fontWeight: FontWeight.w600,
                            fontSize: 14 ,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(80),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 0,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),

                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: Center(
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: (){},
                        icon: const ImageIcon(
                          AssetImage('assets/images/search.png'),
                          color: Colors.black,
                        ),
                        iconSize: 32,
                      ),
                    ),
                  )
                ],
              ),


              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(-0, 0),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                    
                    
                    child:CarouselSlider(items: images.map((item) =>
                    Stack(
                      children: [
                        Container(
                        margin: const EdgeInsets.all(5),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(image: AssetImage(item),fit: BoxFit.cover),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF000080).withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 10,
                                offset: Offset(0, 0),
                              )
                            ]
                        ),
                        ),
                        Positioned(
                            bottom: 18,
                            left: 23,
                            child: Container(
                             constraints: const BoxConstraints(minHeight: 35, minWidth: 100),
                             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                             decoration: BoxDecoration(
                               color: Colors.white,
                               borderRadius: BorderRadius.circular(8),
                             ),
                              child: Center(
                                child: Text(
                                    'En Profiter',
                                   style: TextStyle(
                                     color: Color(0xFF000080),
                                     fontFamily: "Nunito",
                                     fontWeight: FontWeight.w700,
                                   ),
                                ),
                              ),
                            )
                        )
                      ],
                    )).toList(),
                      options: CarouselOptions(
                        height: 200,
                        autoPlay: true,
                        autoPlayInterval: Duration(seconds: 3),
                        autoPlayAnimationDuration: Duration(milliseconds: 800),
                        enlargeCenterPage: true,
                        aspectRatio: 16/9,
                        viewportFraction: 0.95,
                        enlargeFactor: 0.2,
                        enableInfiniteScroll: true,
                        clipBehavior: Clip.none,
                        padEnds: true,
                        onPageChanged: (index,reason){
                          setState(() {
                            currentindex  = index ;
                          });
                        }
                      )
                  ),),),
                  SizedBox(
                    height: 5,
                  ),
                  //dots slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: images.asMap().entries.map((item) => Container(
                      height: 12,
                      width: 12,
                      margin: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentindex == item.key ? Color(0xFF000080) : Colors.grey,
                      ),
                    )).toList(),
                  )
                ],
              ),

              // Online teachers
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                        'Favorite Teachers',
                         style: TextStyle(
                           color: Colors.black,
                           fontFamily: "Inter",
                           fontSize: 20,
                           fontWeight: FontWeight.w600,
                         ),

                    ),
                  ),
                  GestureDetector(
                    onTap: (){
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CoursesPage()),
                      );
                    },
                    child: Text(
                      'See All',
                       style: TextStyle(
                         fontFamily: "Nunito",
                         fontSize: 17,
                         fontWeight: FontWeight.w600,
                         color: Color(0xFF000080),
                       ),
                    ),

                  )
                ],
              ),
             SizedBox(
               height: 100,
               child:
               favoriteTutors?.length == 0 ?
                     const Center(
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
                   :    
               ListView.builder(
                 scrollDirection: Axis.horizontal,
                 shrinkWrap: true,
                 itemCount: favoriteTutors?.length,
                 itemBuilder: (context, index) {
                   return Column(
                       children: [
                         Padding(
                           padding: const EdgeInsets.all(8.0),
                           child: GestureDetector(
                             onTap: () {
                               final TutorModel? tutor = favoriteTutors?[index];
                               if (tutor == null) {
                                 return;
                               }
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(
                                   builder: (_) => TutorProfilePage(tutorId: tutor.uid),
                                 ),
                               ).then((_) => loadStudent());
                             },
                             child: Stack(
                               children: [
                                 Container(
                                   height:60,
                                   width:60,
                                   decoration: BoxDecoration(
                                   shape: BoxShape.circle,
                                   image: DecorationImage(
                                       image: NetworkImage((favoriteTutors?[index].picture).toString()),
                                       fit : BoxFit.cover ),
                                   ),
                                 ),
                                 Positioned(
                                   left: 40 ,
                                   top:45 ,
                                   child: Container(
                                     height:14,
                                     width:14,
                                     decoration: BoxDecoration(
                                       shape: BoxShape.circle,
                                       color: Colors.white,
                                     ),
                                     child: Center(
                                       child: SvgPicture.asset(
                                        "assets/images/heart.svg",
                                  
                                        
                                       ),
                                     ),
                                   ),

                                   ),
                               ],
                             ),
                           )
                         ),
                         Text(
                           (favoriteTutors?[index].firstName).toString(),
                             style: TextStyle(
                              color: Colors.black,
                             fontFamily: "Nunito",
                             fontWeight: FontWeight.w500,
                             fontSize: 16,
                             ),
                         )
                       ],
                   );
                 },
               ),
             ),
              SizedBox(height: 10,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      'Course Schedule',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: "Inter",
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),

                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SchedulePage()),
                      );
                    },
                    child: Text(
                      'See All',
                      style: TextStyle(
                        fontFamily: "Nunito",
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: Color(0xFF000080),
                      ),
                    ),
                  )
                ],
              ),
              if(courses?.isEmpty ?? true)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.menu_book_rounded, size: 52, color: Color(0xFF000080).withValues(alpha: 0.25)),
                        SizedBox(height: 12),
                        Text(
                          "Start your Journey",
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Book a session to see it here",
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.grey.withValues(alpha: 0.8),
                          ),
                        ),
                        SizedBox(height: 16),
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
                            backgroundColor: Color(0xFF000080),
                            foregroundColor: Colors.white,
                            minimumSize: Size(160, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            'Explore Tutors',
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              else if(sessiontutor != null && _nextCourse != null)
                _NextCourseCard(
                  session: _nextCourse!,
                  tutor: sessiontutor!,
                  minutes: minutes,
                  onJoin: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SchedulePage()),
                    );
                  },
                )
              else if(courses?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF000080),
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
        ), // SingleChildScrollView
      ),
      bottomNavigationBar: CustomBottomNavbar(
          selectedIndex: _selectedIndex,
          onTap: (index){
            if (index == 1) {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => Explorepage(student: student!) ),
              );
            }
            else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CoursesPage()),
              );
            }
            else if (index == 3) {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => ChatPage() ),
              );
            }
            else if (index == 4) {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => const StudentAccountPage()),
              ).then((_) => loadStudent());
            }
            else{
              setState(() {
                _selectedIndex = index ;
              });
            }
          })
    );
  }
}

// ---------------------------------------------------------------------------
// Next Course Card — polished, responsive schedule card
// ---------------------------------------------------------------------------

class _NextCourseCard extends StatelessWidget {
  const _NextCourseCard({
    required this.session,
    required this.tutor,
    required this.minutes,
    required this.onJoin,
  });

  final dynamic session;   // SessionModel
  final dynamic tutor;     // TutorModel
  final int minutes;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final bool isOnline = session.type == 'online';
    final Color typeColor = isOnline ? const Color(0xFF16A34A) : const Color(0xFF475569);
    final Color typeBg = isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9);

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 10, 0, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: const Border(
          left: BorderSide(color: Color(0xFF000080), width: 5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000080).withValues(alpha: 0.15),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: label + type badge ──────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6324EB).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'NEXT COURSE',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: Color(0xFF000080),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: typeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    session.type,
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: typeColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Subject title ─────────────────────────────────────────
            Text(
              tutor.expertiseDomain,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1F2937),
                fontFamily: 'Inter',
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            // ── Date row ─────────────────────────────────────────────
            Row(
              children: [
                SvgPicture.asset(
                  'assets/images/time.svg',
                  height: 17,
                  width: 17,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF475569), BlendMode.srcIn),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEE, dd MMM yyyy').format(session.date),
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Time row ─────────────────────────────────────────────
            Row(
              children: [
                SvgPicture.asset(
                  'assets/images/time.svg',
                  height: 17,
                  width: 17,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF000080), BlendMode.srcIn),
                ),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('HH:mm').format(session.startTime)} – '
                  '${DateFormat('HH:mm').format(session.endTime)}  ($minutes min)',
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Tutor row ─────────────────────────────────────────────
            Row(
              children: [
                SvgPicture.asset(
                  'assets/images/person.svg',
                  height: 17,
                  width: 17,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF475569), BlendMode.srcIn),
                ),
                const SizedBox(width: 8),
                Text(
                  '${tutor.firstName} ${tutor.lastName}'.trim(),
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontFamily: 'Lexend',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Join button ───────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'View My Sessions',
                  style: TextStyle(
                    fontFamily: 'Lexend',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
