import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/init_service.dart';  // 👈 Initialization class
import 'login.dart';
import 'chat_screen.dart';
import 'user_reminders.dart';  // 👈 Reminder screen import
import 'past_consultations.dart'; // 👈 New import for past consultations

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  _PatientHomeScreenState createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // User information card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${authService.currentUser?.displayName ?? "Patient"}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Email: ${authService.currentUser?.email ?? ""}'),
                  ],
                ),
              ),
            ),
          ),

          // Buttons Section
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.health_and_safety_outlined,
                    size: 100,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Need medical consultation?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Connect with a doctor by starting a new consultation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 🔥 Start Consultation Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ChatScreen()),
                      );
                    },
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('START CONSULTATION'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔥 Your Prescriptions Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ReminderScreen()),
                      );
                    },
                    icon: const Icon(Icons.medical_services_outlined),
                    label: const Text('YOUR PRESCRIPTIONS'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                      backgroundColor: Colors.green,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔥 Past Consultations Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const PastConsultationsScreen()),
                      );
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('PAST CONSULTATIONS'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(fontSize: 16),
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
