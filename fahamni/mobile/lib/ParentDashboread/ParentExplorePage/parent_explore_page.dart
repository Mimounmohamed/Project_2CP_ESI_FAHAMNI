import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fahamni/Explore_map_pages/map.dart';
import 'package:fahamni/Account_Settings_Parent/account_screen.dart';
import 'package:fahamni/ParentDashboread/ParentCoursePage/parent_courses_page.dart';
import 'package:fahamni/ParentDashboread/ParentHomePage/home_page.dart';
import 'package:fahamni/ParentDashboread/ParentSchedulePage/parent_schedule_page.dart';
import 'package:fahamni/StudentHomePage/studenthome_service.dart';
import 'package:fahamni/feedback/feedback_pages.dart';
import 'package:fahamni/messaging/chat_page.dart';
import 'package:fahamni/models/child_model.dart';
import 'package:fahamni/models/parent_model.dart';
import 'package:fahamni/models/service_model.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:fahamni/widgets/customnavbar.dart';
import 'package:fahamni/widgets/explore_service.dart';
import 'package:fahamni/widgets/servicecard.dart';
import 'package:fahamni/widgets/servicedetails.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _mapLocationConsentKey = 'map_location_consent_granted';

class ParentExplorePage extends StatefulWidget {
  const ParentExplorePage({super.key});

  @override
  State<ParentExplorePage> createState() => _ParentExplorePageState();
}

class _ParentExplorePageState extends State<ParentExplorePage> {
  ParentModel? _parent;
  List<ChildModel> _children = <ChildModel>[];
  ChildModel? _selectedChild;
  final Map<String, Location?> _geocodeCache = <String, Location?>{};

  List<_RecommendedTutorEntry>? tutors;
  List<_RecommendedServiceEntry>? services;
  List<_RecommendedTutorEntry> _allTutors = <_RecommendedTutorEntry>[];
  List<_RecommendedServiceEntry> _allServices = <_RecommendedServiceEntry>[];

  String? selectedSubject;
  String? selectedMode;
  String? selectedRating;
  String? selectedPrice;
  int _selectedIndex2 = 0;

  Position? _currentPosition;
  GoogleMapController? _controller;
  int nearbyTutorsCount = 0;

  final int _selectedIndex = 1;

  // ignore: unused_field
  final studenthomepage_service _studentService = studenthomepage_service();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  final List<String> op = <String>['Subject', 'Price', 'Rating', 'Mode'];
  final List<List<String>> options = <List<String>>[
    <String>['Mathematics', 'Physics', 'English'],
    <String>['<1000', '<2000', '<2500'],
    <String>['3.5', '4', '4.5'],
    <String>['online', 'onSite'],
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _loadParentAndChildren();
    await _loadTutorsAndServices();
    await _getCurrentLocation();
    await _getDistances();
  }

  Future<void> _loadParentAndChildren() async {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    final DocumentSnapshot<Map<String, dynamic>> parentDoc = await _db
        .collection('parents')
        .doc(uid)
        .get();
    final QuerySnapshot<Map<String, dynamic>> childrenQuery = await _db
        .collection('children')
        .where('parentUid', isEqualTo: uid)
        .get();

    if (!parentDoc.exists || parentDoc.data() == null) {
      throw Exception('Parent profile not found.');
    }

    final ParentModel parent = ParentModel.fromMap(parentDoc.data()!);
    final List<ChildModel> children = childrenQuery.docs
        .map((doc) => ChildModel.fromMap({...doc.data(), 'id': doc.id}))
        .toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _parent = parent;
      _children = children;

      if (_selectedChild != null &&
          !_children.any((child) => child.id == _selectedChild!.id)) {
        _selectedChild = null;
      }
      _selectedChild ??= _children.isNotEmpty ? _children.first : null;
    });
  }

  Future<void> _loadTutorsAndServices({ChildModel? child}) async {
    final List<TutorModel> teachers = await Explore_service().getAllTutors();
    final List<ServiceModel> fetchedServices = await Explore_service()
        .getAllServices();

    final Map<String, TutorModel> tutorById = {
      for (final t in teachers) t.uid: t,
    };

    final _RecommendationContext ctx = child != null
        ? _buildChildRecommendationContext(child)
        : _buildNeutralRecommendationContext();

    final List<_RecommendedTutorEntry> rankedTutors =
        teachers
            .map(
              (t) =>
                  _RecommendedTutorEntry(tutor: t, score: _scoreTutor(t, ctx)),
            )
            .toList()
          ..sort(_compareTutorEntries);

    final List<_RecommendedServiceEntry> rankedServices =
        fetchedServices
            .map((s) {
              final TutorModel? tutor = tutorById[s.tutorId];
              if (tutor == null) return null;
              return _RecommendedServiceEntry(
                service: s,
                tutor: tutor,
                score: _scoreService(s, tutor, ctx),
              );
            })
            .whereType<_RecommendedServiceEntry>()
            .toList()
          ..sort(_compareServiceEntries);

    if (!mounted) {
      return;
    }

    setState(() {
      _allTutors = rankedTutors;
      _allServices = rankedServices;
      tutors = rankedTutors;
      services = rankedServices;
    });

    applyFilters();
    await _getDistances();
  }

  _RecommendationContext _buildChildRecommendationContext(ChildModel child) {
    final Set<String> preferredSubjects = child.subjects
        .map(_normalize)
        .where((value) => value.isNotEmpty)
        .toSet();
    final Set<String> objectiveKeywords = _extractKeywords(
      '${child.speciality} ${child.grade}',
    );

    return _RecommendationContext(
      preferredSubjects: preferredSubjects,
      previousSubjects: <String>{},
      previousTutorIds: <String>{},
      previousModes: <String>{},
      favoriteTutorIds: <String>{},
      schoolLevel: _normalize(child.level),
      objectiveKeywords: objectiveKeywords,
    );
  }

  _RecommendationContext _buildNeutralRecommendationContext() {
    return const _RecommendationContext(
      preferredSubjects: <String>{},
      previousSubjects: <String>{},
      previousTutorIds: <String>{},
      previousModes: <String>{},
      favoriteTutorIds: <String>{},
      schoolLevel: '',
      objectiveKeywords: <String>{},
    );
  }

  void _onChildChanged(ChildModel? child) {
    setState(() => _selectedChild = child);
    _loadTutorsAndServices(child: child);
  }

  Future<void> _getCurrentLocation() async {
    final LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    final Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });

    _controller?.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );
  }

  Future<void> _loadLocationPreview() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final bool locationConsentGranted =
        preferences.getBool(_mapLocationConsentKey) ?? false;
    if (!locationConsentGranted) {
      return;
    }

    final LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    final Position position = await Geolocator.getCurrentPosition();
    if (!mounted) {
      return;
    }
    setState(() {
      _currentPosition = position;
    });

    _controller?.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );
  }

  Future<void> _openFullMap() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Mappage()),
    );

    if (!mounted) {
      return;
    }

    await _loadLocationPreview();
    await _getDistances();
  }

  Future<void> _getDistances() async {
    if (_currentPosition == null || tutors == null) {
      return;
    }
    int count = 0;

    for (final _RecommendedTutorEntry entry in tutors!) {
      final TutorModel tutor = entry.tutor;
      if (tutor.location.isNotEmpty) {
        final Location? location = await _geocodeTutorLocation(tutor.location);
        if (location != null) {
          final double distance =
              Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                location.latitude,
                location.longitude,
              ) /
              1000;

          if (distance < 20.0) {
            count++;
          }
        }
      }
    }
    setState(() {
      nearbyTutorsCount = count;
    });
  }

  Future<Location?> _geocodeTutorLocation(String rawLocation) async {
    final String trimmed = rawLocation.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final Location? cached = _geocodeCache[trimmed];
    if (_geocodeCache.containsKey(trimmed)) {
      return cached;
    }

    final List<String> attempts = <String>[
      trimmed,
      if (!trimmed.toLowerCase().contains('algeria')) '$trimmed, Algeria',
      if (!trimmed.toLowerCase().contains('alger')) '$trimmed, Alger, Algeria',
    ];

    for (final String query in attempts) {
      try {
        final List<Location> locations = await locationFromAddress(query);
        if (locations.isNotEmpty) {
          final Location resolved = locations.first;
          _geocodeCache[trimmed] = resolved;
          return resolved;
        }
      } catch (_) {
        continue;
      }
    }

    _geocodeCache[trimmed] = null;
    return null;
  }

  void _handleNavigation(int index) {
    if (index == 1) return;
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Parenthomepage()),
      );
    }
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ParentCoursesPage()),
      );
    }
    if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatPage()),
      );
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
    if (tutors == null || services == null || _parent == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
          'Explore',
          style: TextStyle(
            fontFamily: 'Inter',
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
          margin: const EdgeInsets.fromLTRB(16, 5, 16, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildChildSelector(),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF94A3B8),
                      spreadRadius: 0,
                      blurRadius: 3,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    applyFilters();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search subjects or teachers',
                    hintStyle: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFF94A3B8),
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                      child: SizedBox(
                        width: 115,
                        child: DropdownButtonFormField<String>(
                          initialValue: [
                            selectedSubject,
                            selectedPrice,
                            selectedRating,
                            selectedMode,
                          ][index],
                          icon: const Icon(Icons.keyboard_arrow_down_sharp),
                          iconEnabledColor: _selectedIndex2 == index
                              ? Colors.white
                              : Colors.black,
                          iconSize: 20,
                          isExpanded: true,
                          selectedItemBuilder: (context) {
                            return options[index]
                                .map(
                                  (e) => Center(
                                    child: Text(
                                      e,
                                      style: TextStyle(
                                        color: _selectedIndex2 == index
                                            ? Colors.white
                                            : Colors.black,
                                        fontFamily: 'Nunito',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                )
                                .toList();
                          },
                          hint: Center(
                            child: Text(
                              op[index],
                              style: TextStyle(
                                color: _selectedIndex2 == index
                                    ? Colors.white
                                    : Colors.black,
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: _selectedIndex2 == index
                                ? const Color(0xFF000080)
                                : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(99),
                              borderSide: _selectedIndex2 == index
                                  ? BorderSide.none
                                  : const BorderSide(color: Colors.grey),
                            ),
                          ),
                          items: options[index]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (value) {
                            _selectedIndex2 = index;
                            if (index == 0) {
                              selectedSubject = value;
                            } else if (index == 1) {
                              selectedPrice = value;
                            } else if (index == 2) {
                              selectedRating = value;
                            } else if (index == 3) {
                              selectedMode = value;
                            }
                            applyFilters();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 5,
                      spreadRadius: 0,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    if (_currentPosition != null)
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: GoogleMap(
                          onMapCreated: (controller) async {
                            _controller = controller;
                          },
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            zoom: 14,
                          ),
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                        ),
                      )
                    else
                      Image.asset(
                        'assets/images/map.png',
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 40),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/position.svg',
                              height: 25,
                              width: 25,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                nearbyTutorsCount == 0
                                    ? '$nearbyTutorsCount Tutors found near you'
                                    : 'Discover Tutors found near you',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Lexend',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                _openFullMap();
                              },
                              child: const Text(
                                'VIEW FULL MAP',
                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: Color(0xFF000080),
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'Recommended Teachers',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedChild != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF000080,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'For ${_selectedChild!.name}',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF000080),
                            ),
                          ),
                        ),
                      if (_selectedChild != null) const SizedBox(width: 8),
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
                ],
              ),
              if (tutors!.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'No results found :(',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (tutors!.length / 3).ceil(),
                    itemBuilder: (context, pageIndex) {
                      final int start = pageIndex * 3;
                      final int end = math.min(start + 3, tutors!.length);
                      final List<_RecommendedTutorEntry> pageTutors = tutors!
                          .sublist(start, end);

                      return Container(
                        width: math.min(
                          MediaQuery.of(context).size.width - 32,
                          420,
                        ),
                        margin: EdgeInsets.only(
                          right: pageIndex == (tutors!.length / 3).ceil() - 1
                              ? 0
                              : 14,
                        ),
                        child: Column(
                          children: pageTutors
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _RecommendedTeacherTile(
                                    tutor: entry.tutor,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'Recommended Services',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedChild != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF000080,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'For ${_selectedChild!.name}',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF000080),
                            ),
                          ),
                        ),
                      if (_selectedChild != null) const SizedBox(width: 8),
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
                ],
              ),
              SizedBox(
                height: 320,
                width: double.infinity,
                child: services!.isEmpty
                    ? const Center(
                        child: Text(
                          'No results found :(',
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
                        itemCount: services!.length,
                        itemBuilder: (context, index) {
                          final _RecommendedServiceEntry entry =
                              services![index];
                          final double cardWidth = math.min(
                            MediaQuery.of(context).size.width * 0.84,
                            350,
                          );
                          return SizedBox(
                            height: 430,
                            width: cardWidth,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Servicedetails(
                                      tutor: entry.tutor,
                                      service: entry.service,
                                      selectedChild: _selectedChild,
                                    ),
                                  ),
                                );
                              },
                              child: ServiceCard(
                                tutor: entry.tutor,
                                service: entry.service,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        selectedIndex: _selectedIndex,
        onTap: _handleNavigation,
      ),
    );
  }

  Widget _buildChildSelector() {
    final bool hasChildren = _children.isNotEmpty;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000080).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ChildModel>(
          value: hasChildren ? _selectedChild : null,
          isExpanded: true,
          hint: Text(
            hasChildren ? 'Select a Child' : 'No children linked',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF6B7280),
          ),
          items: _children
              .map(
                (child) => DropdownMenuItem<ChildModel>(
                  value: child,
                  child: Text(
                    child.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: hasChildren ? _onChildChanged : null,
        ),
      ),
    );
  }

  void applyFilters() {
    final String query = _searchController.text.toLowerCase();

    setState(() {
      services = _allServices.where((entry) {
        final ServiceModel s = entry.service;
        final TutorModel tutor = entry.tutor;
        final bool matchSubject =
            selectedSubject == null ||
            s.subject.toLowerCase() == selectedSubject!.toLowerCase() ||
            tutor.expertiseDomain.toLowerCase() ==
                selectedSubject!.toLowerCase();
        final bool matchPrice =
            selectedPrice == null ||
            s.price <= double.parse(selectedPrice!.replaceAll('<', ''));
        final bool matchSearch =
            query.isEmpty ||
            s.name.toLowerCase().contains(query) ||
            s.subject.toLowerCase().contains(query) ||
            s.description.toLowerCase().contains(query) ||
            tutor.firstName.toLowerCase().contains(query) ||
            tutor.lastName.toLowerCase().contains(query) ||
            s.price.toString().toLowerCase().contains(query);
        final bool matchMode =
            selectedMode == null || tutor.teachingMode == selectedMode;
        final bool matchRating =
            selectedRating == null ||
            tutor.averageRating >=
                double.parse(selectedRating!.replaceAll(',', '.'));

        return matchSubject &&
            matchPrice &&
            matchMode &&
            matchRating &&
            matchSearch;
      }).toList();

      tutors = _allTutors.where((entry) {
        final TutorModel t = entry.tutor;
        final bool matchMode =
            selectedMode == null || t.teachingMode == selectedMode;
        final bool matchSubject =
            selectedSubject == null ||
            t.expertiseDomain.toLowerCase() == selectedSubject!.toLowerCase();
        final bool matchRating =
            selectedRating == null ||
            t.averageRating >=
                double.parse(selectedRating!.replaceAll(',', '.'));
        final bool matchSearch =
            query.isEmpty ||
            t.firstName.toLowerCase().contains(query) ||
            t.lastName.toLowerCase().contains(query) ||
            t.expertiseDomain.toLowerCase().contains(query) ||
            t.averageRating.toString().toLowerCase().contains(query);
        return matchMode && matchRating && matchSubject && matchSearch;
      }).toList();
    });
  }

  double _scoreTutor(TutorModel tutor, _RecommendationContext context) {
    double score = 0;
    final String expertise = _normalize(tutor.expertiseDomain);
    final Set<String> tutorLevels = tutor.levelsTaught.map(_normalize).toSet();
    final Set<String> tutorKeywords = _extractKeywords(
      '${tutor.expertiseDomain} ${tutor.academicDescription} ${tutor.pedagogicalDescription}',
    );

    if (context.favoriteTutorIds.contains(tutor.uid)) score += 30;
    if (context.previousTutorIds.contains(tutor.uid)) score += 24;
    if (context.preferredSubjects.contains(expertise)) score += 26;
    if (context.previousSubjects.contains(expertise)) score += 22;
    if (context.schoolLevel.isNotEmpty &&
        tutorLevels.contains(context.schoolLevel)) {
      score += 16;
    }
    if (context.previousModes.contains(_normalize(tutor.teachingMode))) {
      score += 8;
    }
    score += _keywordOverlapScore(
      context.objectiveKeywords,
      tutorKeywords,
      maxBonus: 14,
    );
    if (tutor.isAvailable) score += 8;
    score += tutor.averageRating * 3.5;
    score += math.min(tutor.yearsOfExperience.toDouble(), 12);

    return score;
  }

  double _scoreService(
    ServiceModel service,
    TutorModel tutor,
    _RecommendationContext context,
  ) {
    double score = 0;
    final String subject = _normalize(service.subject);
    final Set<String> serviceKeywords = _extractKeywords(
      '${service.name} ${service.subject} ${service.description} ${service.area} ${service.level}',
    );

    if (context.preferredSubjects.contains(subject)) score += 30;
    if (context.previousSubjects.contains(subject)) score += 26;
    if (context.favoriteTutorIds.contains(tutor.uid)) score += 20;
    if (context.previousTutorIds.contains(tutor.uid)) score += 16;
    if (context.schoolLevel.isNotEmpty &&
        _normalize(service.level) == context.schoolLevel) {
      score += 18;
    }
    if (context.previousModes.contains(_normalize(service.area)) ||
        context.previousModes.contains(_normalize(tutor.teachingMode))) {
      score += 8;
    }
    score += _keywordOverlapScore(
      context.objectiveKeywords,
      serviceKeywords,
      maxBonus: 16,
    );
    if (service.isActive) score += 8;
    score += tutor.averageRating * 3;
    score += math.max(service.maxnum - service.enrollednum, 0) * 0.3;

    return score;
  }

  int _compareTutorEntries(_RecommendedTutorEntry a, _RecommendedTutorEntry b) {
    final int scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) return scoreCompare;
    return b.tutor.averageRating.compareTo(a.tutor.averageRating);
  }

  int _compareServiceEntries(
    _RecommendedServiceEntry a,
    _RecommendedServiceEntry b,
  ) {
    final int scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) return scoreCompare;
    return b.tutor.averageRating.compareTo(a.tutor.averageRating);
  }

  String _normalize(String value) => value.trim().toLowerCase();

  Set<String> _extractKeywords(String text) {
    final Set<String> stopWords = <String>{
      'the',
      'and',
      'for',
      'with',
      'from',
      'that',
      'this',
      'your',
      'you',
      'are',
      'about',
      'into',
      'online',
      'onsite',
      'course',
      'courses',
      'study',
      'learn',
      'want',
    };

    return text
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((token) => token.length >= 3 && !stopWords.contains(token))
        .toSet();
  }

  double _keywordOverlapScore(
    Set<String> source,
    Set<String> target, {
    required double maxBonus,
  }) {
    if (source.isEmpty || target.isEmpty) {
      return 0;
    }
    final int overlap = source.intersection(target).length;
    return math.min(overlap * 4.0, maxBonus);
  }
}

class _RecommendationContext {
  const _RecommendationContext({
    required this.preferredSubjects,
    required this.previousSubjects,
    required this.previousTutorIds,
    required this.previousModes,
    required this.favoriteTutorIds,
    required this.schoolLevel,
    required this.objectiveKeywords,
  });

  final Set<String> preferredSubjects;
  final Set<String> previousSubjects;
  final Set<String> previousTutorIds;
  final Set<String> previousModes;
  final Set<String> favoriteTutorIds;
  final String schoolLevel;
  final Set<String> objectiveKeywords;
}

class _RecommendedTutorEntry {
  const _RecommendedTutorEntry({required this.tutor, required this.score});

  final TutorModel tutor;
  final double score;
}

class _RecommendedServiceEntry {
  const _RecommendedServiceEntry({
    required this.service,
    required this.tutor,
    required this.score,
  });

  final ServiceModel service;
  final TutorModel tutor;
  final double score;
}

class _RecommendedTeacherTile extends StatelessWidget {
  const _RecommendedTeacherTile({required this.tutor});

  final TutorModel tutor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TutorProfilePage(tutorId: tutor.uid),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.05),
              blurRadius: 2,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                tutor.picture,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/tutormale.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tutor.firstName} ${tutor.lastName}',
                    style: const TextStyle(
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tutor.expertiseDomain,
                    style: const TextStyle(
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            'assets/images/position.svg',
                            height: 12,
                            width: 12,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF64748B),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            tutor.location,
                            style: const TextStyle(
                              fontFamily: 'Lexend',
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        tutor.isAvailable ? 'Available' : 'Busy',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: tutor.isAvailable
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: ShapeDecoration(
                color: const Color(0xFF000080).withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/images/star.svg',
                    height: 12,
                    width: 12,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    tutor.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 12,
                      fontFamily: 'Lexend',
                      fontWeight: FontWeight.w700,
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
