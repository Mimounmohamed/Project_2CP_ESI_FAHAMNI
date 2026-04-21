import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:custom_info_window/custom_info_window.dart';
import 'package:fahamni/models/tutor_model.dart';
import 'package:fahamni/widgets/explore_service.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../feedback/feedback_pages.dart';

const String _googleMapsApiKey = 'AIzaSyAsdCXmRcjXMYaLrytaPoO7oLACGdzj65E';
const LatLng _defaultMapCenter = LatLng(36.7538, 3.0588);
const String _mapLocationConsentKey = 'map_location_consent_granted';

class Mappage extends StatefulWidget {
  const Mappage({super.key});

  @override
  State<Mappage> createState() => _MappageState();
}

class _MappageState extends State<Mappage> {
  GoogleMapController? _controller;
  final CustomInfoWindowController _customInfoWindowController =
      CustomInfoWindowController();
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final List<_MappedTutor> _mappedTutors = <_MappedTutor>[];
  TutorModel? _selectedTutor;
  int? _selectedIndex;
  bool _hasLocationConsent = false;
  bool _isRequestingLocation = false;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _initializeLocationState();
    _loadTutorMarkers();
  }

  Future<void> _initializeLocationState() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final bool storedConsent =
        preferences.getBool(_mapLocationConsentKey) ?? false;
    final LocationPermission permission = await Geolocator.checkPermission();
    final bool permissionGranted =
        permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    if (!mounted) {
      return;
    }

    setState(() {
      _hasLocationConsent = storedConsent || permissionGranted;
    });

    if (permissionGranted) {
      await _getCurrentLocation(requestPermissionIfNeeded: false);
    }
  }

  Future<void> _getCurrentLocation({
    bool requestPermissionIfNeeded = false,
  }) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (requestPermissionIfNeeded &&
        (permission == LocationPermission.denied ||
            permission == LocationPermission.unableToDetermine)) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _currentPosition = null;
          if (requestPermissionIfNeeded) {
            _hasLocationConsent = false;
          }
        });
      }
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    if (!mounted) {
      return;
    }
    setState(() {
      _currentPosition = position;
      _hasLocationConsent = true;
    });
    _controller?.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );
  }

  Future<void> _requestLocationAccess() async {
    if (_isRequestingLocation) {
      return;
    }

    setState(() {
      _isRequestingLocation = true;
    });

    try {
      final SharedPreferences preferences =
          await SharedPreferences.getInstance();
      final LocationPermission permission =
          await Geolocator.requestPermission();
      final bool granted =
          permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      await preferences.setBool(_mapLocationConsentKey, granted);

      if (!mounted) {
        return;
      }

      setState(() {
        _hasLocationConsent = granted;
      });

      if (granted) {
        await _getCurrentLocation(requestPermissionIfNeeded: false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingLocation = false;
        });
      }
    }
  }

  Future<BitmapDescriptor> _buildCircularMarker(String url) async {
    const int size = 120;
    const double radius = 50;
    const double borderWidth = 5;
    const Color borderColor = Colors.white;

    Uint8List? imageBytes;
    if (url.trim().isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode >= 200 && response.statusCode < 300) {
          imageBytes = response.bodyBytes;
        }
      } catch (_) {
        imageBytes = null;
      }
    }

    imageBytes ??= (await rootBundle.load(
      'assets/images/tutormale.png',
    )).buffer.asUint8List();

    final ui.Codec codec = await ui.instantiateImageCodec(
      imageBytes,
      targetWidth: (radius * 2).toInt(),
      targetHeight: (radius * 2).toInt(),
    );
    final ui.FrameInfo frame = await codec.getNextFrame();
    final ui.Image avatarImage = frame.image;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double center = size / 2;
    final Offset centerOffset = Offset(center, center);

    canvas.drawCircle(
      centerOffset,
      radius + borderWidth,
      Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      centerOffset,
      radius + borderWidth,
      Paint()..color = borderColor,
    );
    final Path clipPath = Path()
      ..addOval(Rect.fromCircle(center: centerOffset, radius: radius));
    canvas.clipPath(clipPath);
    canvas.drawImageRect(
      avatarImage,
      Rect.fromLTWH(
        0,
        0,
        avatarImage.width.toDouble(),
        avatarImage.height.toDouble(),
      ),
      Rect.fromCircle(center: centerOffset, radius: radius),
      Paint(),
    );

    final ui.Image markerImage = await recorder.endRecording().toImage(
      size,
      size,
    );
    final ByteData? byteData = await markerImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<void> _loadTutorMarkers() async {
    final tutors = await Explore_service().getAllTutors();
    for (TutorModel tutor in tutors) {
      if (tutor.location.isEmpty) continue;
      try {
        final Location? location = await _geocodeTutorLocation(tutor.location);
        if (location == null) continue;
        final LatLng markerPosition = LatLng(
          location.latitude,
          location.longitude,
        );
        final int mappedIndex = _mappedTutors.length;
        final BitmapDescriptor icon = await _buildCircularMarker(tutor.picture);
        final marker = Marker(
          markerId: MarkerId(tutor.uid),
          position: markerPosition,
          icon: icon,
          onTap: () {
            setState(() {
              _selectedTutor = tutor;
              _selectedIndex = mappedIndex;
            });
            _sheetController.animateTo(
              0.45,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
            _controller?.animateCamera(
              CameraUpdate.newLatLng(markerPosition),
            );
          },
        );
        setState(() {
          _markers.add(marker);
          _mappedTutors.add(
            _MappedTutor(
              tutor: tutor,
              location: location,
            ),
          );
        });
      } catch (e) {
        print('Could not geocode: $e');
      }
    }
  }

  Future<Location?> _geocodeTutorLocation(String rawLocation) async {
    final String trimmed = rawLocation.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final List<String> attempts = <String>[
      trimmed,
      if (!trimmed.toLowerCase().contains('algeria')) '$trimmed, Algeria',
      if (!trimmed.toLowerCase().contains('algeria')) '$trimmed, Alger',
    ];

    for (final String query in attempts) {
      try {
        final List<Location> locations = await locationFromAddress(query);
        if (locations.isNotEmpty) {
          return locations.first;
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  String _getDistance(int index) {
    if (_currentPosition == null) return '';
    final Location location = _mappedTutors[index].location;
    final distanceInMeters = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      location.latitude,
      location.longitude,
    );
    final km = distanceInMeters / 1000;
    return km < 1
        ? '${distanceInMeters.toInt()} m away'
        : '${km.toStringAsFixed(1)} km away';
  }

  Future<void> _drawPolyline(int index) async {
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: _googleMapsApiKey,
      request: PolylineRequest(
        origin: PointLatLng(
          _currentPosition?.latitude ?? _defaultMapCenter.latitude,
          _currentPosition?.longitude ?? _defaultMapCenter.longitude,
        ),
        destination: PointLatLng(
          _mappedTutors[index].location.latitude,
          _mappedTutors[index].location.longitude,
        ),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: PolylineId('route'),
            points: result.points
                .map((p) => LatLng(p.latitude, p.longitude))
                .toList(),
            color: Color(0xFF000080),
            width: 5,
          ),
        };
        print('polyline points: ${result.points.length}');
        print('status: ${result.status}');
        print('error: ${result.errorMessage}');
      });
    }
  }

  void _openGoogleMapsDirections(int index) async {
    final lat = _mappedTutors[index].location.latitude;
    final lng = _mappedTutors[index].location.longitude;
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final LatLng initialTarget = _currentPosition == null
        ? _defaultMapCenter
        : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xfff9f9f9),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
        ),
        title: const Text(
          "Tutors Map",
          style: TextStyle(
            fontFamily: "Inter",
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xff0f172a),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 15,
            ),
            mapType: MapType.normal,
            buildingsEnabled: true,
            compassEnabled: true,
            myLocationEnabled: _currentPosition != null,
            myLocationButtonEnabled: _currentPosition != null,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) async {
              _controller = controller;
              _customInfoWindowController.googleMapController = controller;
              _controller!.animateCamera(CameraUpdate.newLatLng(initialTarget));
            },
            onCameraMove: (_) => _customInfoWindowController.onCameraMove!(),
            onTap: (_) {
              _customInfoWindowController.hideInfoWindow!();
              setState(() {
                _selectedTutor = null;
                _selectedIndex = null;
                _polylines = {};
              });
              _sheetController.animateTo(
                0.18,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
          if (_currentPosition == null)
            Positioned(
              top: 16,
              right: 16,
              child: ElevatedButton.icon(
                onPressed: _isRequestingLocation
                    ? null
                    : _requestLocationAccess,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000080),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                icon: _isRequestingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: Text(
                  _hasLocationConsent ? 'Locate me' : 'Enable location',
                  style: const TextStyle(
                    fontFamily: "Nunito",
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          CustomInfoWindow(
            controller: _customInfoWindowController,
            height: 180,
            width: MediaQuery.of(context).size.width * 0.89,
            offset: 50,
          ),
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.18,
            minChildSize: 0.18,
            maxChildSize: 0.7,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          margin: EdgeInsets.only(top: 12, bottom: 8),
                          height: 4,
                          width: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),

                      // Teacher avatars row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Center(
                          child: Text(
                            'select your favorite tutor',
                            style: TextStyle(
                              fontFamily: "Inter",
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        height: 85,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _mappedTutors.length,
                          itemBuilder: (context, index) {
                            final isSelected = _selectedIndex == index;
                            final TutorModel tutor = _mappedTutors[index].tutor;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTutor = tutor;
                                  _selectedIndex = index;
                                });
                                _controller?.animateCamera(
                                  CameraUpdate.newLatLng(
                                    LatLng(
                                      _mappedTutors[index].location.latitude,
                                      _mappedTutors[index].location.longitude,
                                    ),
                                  ),
                                );
                                _sheetController.animateTo(
                                  0.45,
                                  duration: Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Column(
                                  children: [
                                    Container(
                                      height: 56,
                                      width: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            tutor.picture,
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                        border: Border.all(
                                          color: isSelected
                                              ? Color(0xFF000080)
                                              : Colors.grey[300]!,
                                          width: isSelected ? 3 : 1.5,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      tutor.firstName,
                                      style: TextStyle(
                                        fontFamily: "Lexend",
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        fontSize: 11,
                                        color: isSelected
                                            ? Color(0xFF000080)
                                            : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Selected tutor details
                      if (_selectedTutor != null && _selectedIndex != null) ...[
                        Divider(height: 24, color: Colors.grey[200]),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF000080).withOpacity(0.1),
                                  borderRadius: BorderRadiusGeometry.circular(
                                    5,
                                  ),
                                  border: Border(
                                    left: BorderSide(
                                      color: Color(0xFF000080),
                                      width: 4,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      height: 60,
                                      width: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            _selectedTutor!.picture,
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                        border: Border.all(
                                          style: BorderStyle.none,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${_selectedTutor!.firstName} ${_selectedTutor!.lastName}',
                                            style: TextStyle(
                                              fontFamily: "Inter",
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                          Text(
                                            _selectedTutor!.expertiseDomain,
                                            style: TextStyle(
                                              fontFamily: "Nunito",
                                              fontWeight: FontWeight.w400,
                                              fontSize: 13,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(
                                          0xFF000080,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          SvgPicture.asset(
                                            "assets/images/star.svg",
                                            height: 12,
                                            width: 12,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            _selectedTutor!.averageRating
                                                .toString(),
                                            style: TextStyle(
                                              fontFamily: "Lexend",
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: Color(0xFF1E293B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              // Info rows
                              _infoRow(
                                Icons.location_on_rounded,
                                _selectedTutor!.location,
                              ),
                              SizedBox(height: 8),
                              Container(
                                margin: EdgeInsetsGeometry.symmetric(
                                  horizontal: 10,
                                ),
                                padding: EdgeInsets.fromLTRB(6, 3, 0, 3),
                                width: 130,
                                isAntiAlias: true,
                                decoration: BoxDecoration(
                                  color: Color(0xFF000080).withOpacity(0.1),
                                  borderRadius: BorderRadiusGeometry.circular(
                                    99,
                                  ),
                                ),
                                child: _infoRow(
                                  Icons.directions_walk_rounded,
                                  _currentPosition == null
                                      ? 'Enable location for distance'
                                      : _getDistance(_selectedIndex!),
                                ),
                              ),
                              SizedBox(height: 8),
                              _infoRow(
                                Icons.devices,
                                _selectedTutor!.teachingMode,
                              ),
                              SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _openGoogleMapsDirections(
                                            _selectedIndex!,
                                          ),
                                      icon: Icon(Icons.message_outlined),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsetsGeometry.fromLTRB(
                                          20,
                                          15,
                                          20,
                                          15,
                                        ),
                                        backgroundColor: Color(0xFFD2D2D2),
                                        iconColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadiusGeometry.circular(30),
                                        ),
                                      ),
                                      label: Center(
                                        child: Text(
                                          'Directions',
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
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => TutorProfilePage(tutorId: _selectedTutor!.uid),
                                          ),
                                        );

                                      },
                                      icon: Icon(
                                        Icons.person_2_outlined,
                                        color: Colors.white,
                                        size: 23,
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsetsGeometry.fromLTRB(
                                          20,
                                          15,
                                          20,
                                          15,
                                        ),
                                        backgroundColor: Color(0xFF000080),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadiusGeometry.circular(30),
                                        ),
                                      ),
                                      label: Center(
                                        child: Text(
                                          'View Profile',
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
                              ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ],
                      if (_currentPosition == null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Location permission is off. The map still works, but your current position and distance are unavailable.',
                                  style: TextStyle(
                                    fontFamily: "Nunito",
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _isRequestingLocation
                                    ? null
                                    : _requestLocationAccess,
                                child: const Text(
                                  'Enable',
                                  style: TextStyle(
                                    fontFamily: "Nunito",
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF000080),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Container(
      padding: icon == Icons.directions_walk_rounded
          ? EdgeInsets.symmetric(horizontal: 0)
          : EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Color(0xFF000080)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: "Lexend",
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: icon == Icons.directions_walk_rounded
                    ? Color(0xFF000080)
                    : Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class _MappedTutor {
  const _MappedTutor({
    required this.tutor,
    required this.location,
  });

  final TutorModel tutor;
  final Location location;
}
