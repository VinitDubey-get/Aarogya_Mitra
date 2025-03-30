import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'login.dart';
import 'patient_home.dart';
import 'doctor_home.dart';
import 'const.dart';

void main() {
  // Initialize Gemini with API key from constants
  Gemini.init(apiKey: AppConstants.geminiApiKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/patient': (context) => const PatientHomeScreen(),
        '/doctor': (context) => const DoctorHomeScreen(),
      },
    );
  }
}
