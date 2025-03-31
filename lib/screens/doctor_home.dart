import 'package:ai_doc/screens/video_call_doctor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/consultation.dart';
import '../models/doctor.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'login.dart';
import 'chat_screen.dart';
import 'open_consultations_screen.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Doctor info card with availability status
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<Doctor?>(
              stream: firestoreService.getDoctorProfile(authService.currentUser!.uid),
              builder: (context, snapshot) {
                bool isAvailable = snapshot.hasData ? snapshot.data!.isAvailable : false;
                
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, Dr. ${authService.currentUser?.displayName ?? "Doctor"}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Email: ${authService.currentUser?.email ?? ""}'),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Status: '),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isAvailable ? Colors.green.shade100 : Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isAvailable ? Colors.green : Colors.red,
                                )
                              ),
                              child: Text(
                                isAvailable ? 'Available' : 'Unavailable',
                                style: TextStyle(
                                  color: isAvailable ? Colors.green.shade800 : Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await firestoreService.updateDoctorAvailability(
                                    authService.currentUser!.uid, 
                                    !isAvailable
                                  );
                                  
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(isAvailable 
                                          ? 'You are now unavailable for new consultations' 
                                          : 'You are now available for new consultations'
                                        ),
                                        backgroundColor: isAvailable ? Colors.red.shade300 : Colors.green.shade300,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error updating status: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                              icon: Icon(isAvailable ? Icons.pause_circle_outline : Icons.play_circle_outline),
                              label: Text(isAvailable ? 'Go Offline' : 'Go Online'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isAvailable ? Colors.red.shade50 : Colors.green.shade50,
                                foregroundColor: isAvailable ? Colors.red.shade700 : Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }
            ),
          ),
          
          // Assigned consultations
          Expanded(
            child: StreamBuilder<List<Consultation>>(
              stream: firestoreService.getDoctorConsultations(
                authService.currentUser!.uid,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading consultations: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final consultations = snapshot.data ?? [];

                if (consultations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.medical_services_outlined, 
                          size: 72, 
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No consultations yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You haven\'t been assigned to any consultations',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context, 
                              MaterialPageRoute(
                                builder: (context) => const OpenConsultationsScreen()
                              )
                            );
                          },
                          icon: const Icon(Icons.search),
                          label: const Text('Find Open Consultations'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: consultations.length,
                  itemBuilder: (context, index) {
                    final consultation = consultations[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        title: Text(consultation.title),
                        subtitle: Text(
                          'Updated: ${consultation.updatedAt.toString().split(' ')[0]}',
                        ),
                        trailing: Icon(
                          consultation.isCompleted
                              ? Icons.check_circle
                              : Icons.pending,
                          color:
                              consultation.isCompleted ? Colors.green : Colors.orange,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>  DoctorVideo()),

                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<Doctor?>(
        stream: firestoreService.getDoctorProfile(authService.currentUser!.uid),
        builder: (context, snapshot) {
          bool isAvailable = snapshot.hasData ? snapshot.data!.isAvailable : false;
          
          return FloatingActionButton(
            child: const Icon(Icons.search),
            onPressed: () {
              if (!isAvailable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You are currently offline. Go online to accept consultations.'),
                  ),
                );
                return;
              }
              
              // View open consultations
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const OpenConsultationsScreen())
              );
            },
            backgroundColor: isAvailable ? null : Colors.grey,
          );
        }
      ),
    );
  }
}
