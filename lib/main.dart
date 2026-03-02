import 'package:flutter/material.dart';
// Pastikan file tempat CounterView berada di-import di sini
import 'package:logbook_app/features/onboarding/onboarding_view.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  // Wajib untuk operasi asinkron sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();
  // Load ENV
  await dotenv.load(fileName: ".env");
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