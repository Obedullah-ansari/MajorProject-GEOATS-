import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await _requestLocationPermission();

  runApp(const MyApp());
}

Future<void> _requestLocationPermission() async {
  final status = await Permission.location.request();

  if (status.isDenied) {
    debugPrint("Location permission denied");
  } else if (status.isPermanentlyDenied) {
    openAppSettings();
  }
}
