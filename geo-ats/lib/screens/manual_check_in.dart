import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class ManualAttendancePage extends StatefulWidget {
  final User? user;

  ManualAttendancePage({required this.user});

  @override
  _ManualAttendancePageState createState() =>
      _ManualAttendancePageState();
}

class _ManualAttendancePageState
    extends State<ManualAttendancePage> {
  bool isCheckedIn = false;
  String? userName;
  String locationStatus = "Checking location...";
  bool isLocationLoaded = false;  
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadCheckInStatus();
    _determineLocation();
  }

  // 🔹 Load user name
  Future<void> _loadUserName() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user!.uid)
        .get();

    if (doc.exists) {
      setState(() {
        userName = doc['name'];
      });
    }
  }

  // 🔹 Load last check-in status
  Future<void> _loadCheckInStatus() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('checkins')
        .where('user_id', isEqualTo: widget.user!.uid)
        .orderBy('check_in_time', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        isCheckedIn =
            snapshot.docs.first['status'] == 'checked_in';
      });
    }
  }

  // 🔹 Detect if inside office or offsite
  Future<void> _determineLocation() async {
    currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    final offices = await FirebaseFirestore.instance
        .collection('officeLocations')
        .get();

    bool insideOffice = false;
    String officeName = "";

    for (var doc in offices.docs) {
      double lat = doc['latitude'];
      double lng = doc['longitude'];
      int radius = doc['radius'];

      double distance = Geolocator.distanceBetween(
        currentPosition!.latitude,
        currentPosition!.longitude,
        lat,
        lng,
      );

      if (distance <= radius) {
        insideOffice = true;
        officeName = doc['office_name'];
        break;
      }
    }

    setState(() {
  locationStatus =
      insideOffice ? officeName : "Offsite Location";
  isLocationLoaded = true;   
});
  }

  // 🔥 MANUAL CHECK-IN
  Future<void> _manualCheckIn() async {
    if (currentPosition == null) return;

    await FirebaseFirestore.instance.collection('checkins').add({
      'user_id': widget.user!.uid,
      'user_name': userName,
      'office_name': locationStatus,
      'status': 'checked_in',
      'latitude': currentPosition!.latitude,
      'longitude': currentPosition!.longitude,
      'check_in_time': Timestamp.now(),
    });

    setState(() {
      isCheckedIn = true;
    });
     Navigator.pop(context, 'checked_in');
  }

  // 🔥 MANUAL CHECK-OUT
  Future<void> _manualCheckOut() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('checkins')
        .where('user_id', isEqualTo: widget.user!.uid)
        .where('status', isEqualTo: 'checked_in')
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      snapshot.docs.first.reference.update({
        'status': 'checked_out',
        'check_out_time': Timestamp.now(),
      });
    }

    setState(() {
      isCheckedIn = false;
    });
      Navigator.pop(context, 'checked_out');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manual Attendance"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text(
              userName != null
                  ? "Welcome $userName"
                  : "Loading...",
              style:
                  TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            Text(
              locationStatus,
              style: TextStyle(
                fontSize: 20,
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 40),

            isLocationLoaded
    ? (isCheckedIn
        ? ElevatedButton(
            onPressed: _manualCheckOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding:
                  EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
            child: Text("Manual Check-Out"),
          )
        : ElevatedButton(
            onPressed: _manualCheckIn,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding:
                  EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            ),
            child: Text("Manual Check-In"),
          ))
    : Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text(
            "Fetching location...",
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
          ],
        ),
      ),
    );
  }
}