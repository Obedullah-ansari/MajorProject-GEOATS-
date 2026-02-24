import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocation_attendance/screens/login_page.dart';
import 'package:geolocation_attendance/screens/manual_check_in.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../service/location_service.dart';
import 'attendance_history.dart';
import 'work_hours_page.dart';

class HomeScreen extends StatefulWidget {
  User? user;

  HomeScreen({required this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double? latitude;
  double? longitude;
  bool isCheckedIn = false;
  bool isInsideOffice = false;
  bool isGpsEnabled = true;

  final LocationService locationService = LocationService();
  late StreamSubscription<Position> _positionStreamSubscription;

  @override
  @override
  @override
  void initState() {
    super.initState();

    locationService.setStatusCallback((checkedIn, insideOffice) {
      setState(() {
        isCheckedIn = checkedIn;
        isInsideOffice = insideOffice;
      });
    });

    locationService.startListeningToOfficeLocations();

    _checkGpsStatus(); // ⭐ NEW
    _startLocationTracking();

    // ⭐ Auto-update if user turns GPS on/off
    Geolocator.getServiceStatusStream().listen((status) {
      setState(() {
        isGpsEnabled = status == ServiceStatus.enabled;
      });
    });
  }

  Future<void> _checkGpsStatus() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();

    setState(() {
      isGpsEnabled = enabled;
    });
  }

  void _startLocationTracking() {
    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position position) async {
          print(
            '📍 LOCATION UPDATE: ${position.latitude}, ${position.longitude}',
          );

          setState(() {
            latitude = position.latitude;
            longitude = position.longitude;
          });

          await locationService.handleCheckInOut(
            widget.user!,
            LatLng(latitude!, longitude!),
          );
        });
  }

  @override
  void dispose() {
    _positionStreamSubscription.cancel();
    locationService.stopListeningToOfficeLocations();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff17EAD9), Color(0xff6078EA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Employee Attendance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCheckInStatusCard(),

            SizedBox(height: 20),

            _buildGpsStatusCard(),

            SizedBox(height: 20),

            _buildMap(),

            SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                 childAspectRatio: 1.6,
                children: [
                  _buildActionCard(
                    icon: Icons.edit_location,
                    label: "Manual Check-In/Out",
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ManualAttendancePage(user: widget.user),
                        ),
                      );

                      if (result == 'checked_in') {
                        setState(() {
                          isCheckedIn = true;
                        });
                      }

                      if (result == 'checked_out') {
                        setState(() {
                          isCheckedIn = false;
                        });
                      }
                    },
                    color: Colors.purpleAccent,
                  ),

                  _buildActionCard(
                    icon: Icons.access_time,
                    label: "Working Hours",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) =>
                              UserWorkHoursPage(userId: widget.user!.uid),
                        ),
                      );
                    },
                    color: Colors.blueAccent,
                  ),
                  _buildActionCard(
                    icon: Icons.history,
                    label: "Attendance History",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) =>
                              AttendanceHistoryPage(userId: widget.user!.uid),
                        ),
                      );
                    },
                    color: Color(0xff1BCEDF),
                  ),
                  _buildActionCard(
                    icon: Icons.settings,
                    label: "Settings",
                    onTap: () {},
                    color: Color(0xff000000),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Check-In Status Card and other widgets remain unchanged
  Widget _buildCheckInStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isCheckedIn
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isCheckedIn ? Icons.check_circle : Icons.cancel,
              color: isCheckedIn ? Colors.green : Colors.red,
              size: 40,
            ),
            SizedBox(width: 16),
            Text(
              isCheckedIn ? 'You are Checked In' : 'You are Checked Out',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isCheckedIn ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGpsStatusCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isGpsEnabled
              ? Colors.green.withOpacity(0.1)
              : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isGpsEnabled ? Icons.gps_fixed : Icons.gps_off,
              color: isGpsEnabled ? Colors.green : Colors.red,
              size: 36,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                isGpsEnabled
                    ? "GPS is ON Geolocation working"
                    : "GPS is OFF Please turn ON location",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isGpsEnabled ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Map Section
  Widget _buildMap() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: latitude != null && longitude != null
          ? FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(latitude!, longitude!),
                initialZoom: 16,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.attendance.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(latitude!, longitude!),
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color), // ⭐ slightly bigger icon
              SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
