import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/consultation.dart';
import '../models/doctor.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'chat_screen.dart';

class OpenConsultationsScreen extends StatelessWidget {
  const OpenConsultationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Consultations'),
      ),
      body: StreamBuilder<Doctor?>(
        stream: firestoreService.getDoctorProfile(authService.currentUser!.uid),
        builder: (context, doctorSnapshot) {
          if (doctorSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          bool isAvailable = doctorSnapshot.hasData ? doctorSnapshot.data!.isAvailable : false;
          
          if (!isAvailable) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.offline_bolt_outlined, size: 72, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'You are currently offline',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Change your status to online to view and accept consultations',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await firestoreService.updateDoctorAvailability(
                          authService.currentUser!.uid, 
                          true
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Go Online'),
                  ),
                ],
              ),
            );
          }
          
          return StreamBuilder<List<Consultation>>(
            stream: firestoreService.getOpenConsultations(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final consultations = snapshot.data ?? [];

              if (consultations.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medical_services_outlined, size: 72, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No open consultations',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'There are currently no patients waiting for assistance',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: consultations.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final consultation = consultations[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            consultation.patientName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Created: ${consultation.createdAt.toString().split('.')[0]}',
                          ),
                          Text(
                            consultation.patientComplaint ?? 'No complaint provided',
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  _acceptConsultation(context, consultation);
                                },
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Accept Consultation'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _acceptConsultation(BuildContext context, Consultation consultation) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    // Update consultation with doctor ID and change status
    final updatedConsultation = consultation.copyWith(
      doctorId: authService.currentUser!.uid,
      status: 'assigned',
      updatedAt: DateTime.now(),
    );
    
    try {
      await firestoreService.updateConsultation(updatedConsultation);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Consultation accepted successfully!"),
        ),
      );
      
      // Navigate to chat screen with this consultation
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(consultation: updatedConsultation),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error accepting consultation: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
