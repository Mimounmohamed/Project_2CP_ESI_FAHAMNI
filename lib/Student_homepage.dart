import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:untitled/customnavbar.dart';
import 'dart:ui';

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
    'assets/slide2.png',
    'assets/slide0.png',
    'assets/slide1.png',
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.fromLTRB(16, 5, 16, 0), // Added right margin
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align to start
            children: [
              // First row with avatar and icons
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: AssetImage('assets/profile.jpg'),
                  ),
                  SizedBox(width: 5),
                  Expanded( // Wrap with Expanded to take available space
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 300),
                          child: Text(
                            'Bedoui Wassim',
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
                          'Student',
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
                    onPressed: () {},
                    icon: ImageIcon(
                      AssetImage('assets/bell.png'),
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
                  SizedBox(width: 2,),
                  Container(
                    height: 70,
                    width: 50,
                    child: Center(
                      child: IconButton(
                          onPressed: (){},
                          icon: ImageIcon(
                              AssetImage('assets/search.png'),
                            color: Colors.black,
                          ),
                          iconSize: 40,
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
                        margin: EdgeInsets.all(5),
                        width: 398,
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
                            top: 140 ,
                            left: 23,
                            child: Container(
                             // padding: EdgeInsets.fromLTRB(8, 0, 8, 0),
                             height: 35,
                             width: 100,
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
                           fontSize: 20,
                           fontWeight: FontWeight.bold,
                         ),

                    ),
                  ),
                  GestureDetector(
                    onTap: (){},
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
               child: ListView.builder(
                 scrollDirection: Axis.horizontal,
                 shrinkWrap: true,
                 itemCount: teachers.length,
                 itemBuilder: (context, index) {
                   return Column(
                       children: [
                         Padding(
                           padding: const EdgeInsets.all(8.0),
                           child: GestureDetector(
                             onTap: (){},
                             child: Stack(
                               children: [
                                 Container(
                                   height:60,
                                   width:60,
                                   decoration: BoxDecoration(
                                   shape: BoxShape.circle,
                                   image: DecorationImage(
                                       image: NetworkImage(teachers[index]['image']),
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
                                        "assets/heart.svg",
                                  
                                        
                                       ),
                                     ),
                                   ),

                                   ),
                               ],
                             ),
                           )
                         ),
                         Text(
                             teachers[index]['name'],
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
                    onTap: (){},
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
              Container(
                margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
                height: 230,
                width: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                    border: Border(
                      left: BorderSide(
                        color: Color(0xFF000080), // Your custom color
                        width: 5, // Border width
                        style: BorderStyle.solid, // solid is default
                      ),
                    ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF000080).withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(2, 3),
                    )
                  ]
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 20,
                            width: 120,
                            decoration: BoxDecoration(
                              color: Color(0xFF6324EB).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                              child: Text(
                                  'NEXT COURSE',
                                  style: TextStyle(
                                    fontFamily: "Nunito",
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF000080),
                                    letterSpacing: 1,
                                  ),
                              ),
                            ),
                          ),
                          SizedBox(width: 150,),
                          Container(
                            height: 25,
                            width:70,
                            decoration: BoxDecoration(
                              color: Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
                              child: Center(
                                child: Text(
                                    '•Online',
                                  style: TextStyle(
                                    fontFamily: "Nunito",
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF16A34A),
                                    height: 1.25,
                                  ),

                                    ),
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 10,),
                      SizedBox(
                        width: 200,
                        height: 28,
                        child: Text(
                            'Mathématiques',
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: "Inter",
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                        ),
                      ),
                      SizedBox(height: 10,),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                            SvgPicture.asset(
                                "assets/person.svg",
                              height: 20,
                              width: 20,
                              color: Color(0xFF475569),
                            ),

                          SizedBox(width: 10,),
                          Text('Dr.Zegour',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontFamily: "Lexend",
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                          ),
                          )
                        ],
                      ),
                      SizedBox(height: 15,),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            "assets/time.svg",
                            height: 20,
                            width: 20,
                            color: Color(0xFF475569),
                          ),
                          SizedBox(width: 10,),
                          Text('14:00 - 15:30 (90 min)',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontFamily: "Lexend",
                              fontWeight: FontWeight.w400,
                              fontSize: 15,
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 28,),
                      Container(
                        height: 48,
                        width: 370,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: ImageIcon(
                            AssetImage('assets/Icon.png'),

                          ),

                          label: Text(
                              'Join the course',
                              style: TextStyle(
                                fontFamily: "Lexend",
                                fontSize: 16,
                                fontWeight: FontWeight.w700
                              ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF000080), // Your dark color
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          //  minimumSize: Size(324, 48), // Minimum width and height
                          ),
                        ),
                      )
                    ],
                  
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.fromLTRB(8, 0, 8, 20),
        height: 70,
        width: 400,
        decoration: BoxDecoration(
          color: Color(0xFF94A3B8).withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
        ),
            child:ClipRRect(
    borderRadius: BorderRadius.circular(30),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // 👈 the glass blur
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2), // 👈 grey glass tint
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 15 , vertical: 10),
              child:const CustomBottomNavbar(),
            ),
      ),
    ),
  ),
        ),
    );
  }
}