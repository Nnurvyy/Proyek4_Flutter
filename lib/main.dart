import 'package:flutter/material.dart';
// Pastikan file tempat CounterView berada di-import di sini
import 'package:logbook_app/features/onboarding/onboarding_view.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import "package:hive_flutter/hive_flutter.dart";
import 'package:logbook_app/features/logbook/models/log_model.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras = []; // Variabel global untuk menyimpan daftar kamera



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Ambil daftar kamera yang tersedia di perangkat
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error: ${e.code}\nError Message: ${e.description}');
  }

  // Wajib untuk operasi asinkron sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();
  // Load ENV
  await dotenv.load(fileName: ".env");

  await Hive.initFlutter();
  Hive.registerAdapter(LogModelAdapter());
  await Hive.openBox<LogModel>(
    'offline_logs',
  );
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key}); 

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LogBook App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const OnBoardingView(), 
    );
  }
  
}