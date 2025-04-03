import 'package:ai_doc/screens/accepted_consultation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/consultation.dart';
import '../models/doctor.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'login.dart';
import 'open_consultations_screen.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      body: Column(
        children: [
          // Doctor info card with availability status
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              color: Colors.blue,
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                top: 32,
                right: 16,
                left: 16,
                bottom: 16,
              ),
              child: StreamBuilder<Doctor?>(
                stream: firestoreService.getDoctorProfile(
                  authService.currentUser!.uid,
                ),
                builder: (context, snapshot) {
                  bool isAvailable =
                      snapshot.hasData ? snapshot.data!.isAvailable : false;

                  return Card(
                    color: Colors.blue[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: Icon(Icons.person, size: 40),
                            title: Text(
                              'Welcome, Dr. ${authService.currentUser?.displayName ?? "Doctor"}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${authService.currentUser?.email ?? ""}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            trailing: IconButton(
                              onPressed: () async {
                                await authService.signOut();
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              icon: Icon(Icons.logout_outlined, size: 34),
                            ),
                          ),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Text('Status: '),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isAvailable
                                          ? Colors.green.shade100
                                          : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isAvailable ? Colors.green : Colors.red,
                                  ),
                                ),
                                child: Text(
                                  isAvailable ? 'Available' : 'Unavailable',
                                  style: TextStyle(
                                    color:
                                        isAvailable
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    await firestoreService
                                        .updateDoctorAvailability(
                                          authService.currentUser!.uid,
                                          !isAvailable,
                                        );

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isAvailable
                                                ? 'You are now unavailable for new consultations'
                                                : 'You are now available for new consultations',
                                          ),
                                          backgroundColor:
                                              isAvailable
                                                  ? Colors.red.shade300
                                                  : Colors.green.shade300,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error updating status: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                icon: Icon(
                                  isAvailable
                                      ? Icons.pause_circle_outline
                                      : Icons.play_circle_outline,
                                ),
                                label: Text(
                                  isAvailable ? 'Go Offline' : 'Go Online',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      isAvailable
                                          ? Colors.red.shade50
                                          : Colors.green.shade50,
                                  foregroundColor:
                                      isAvailable
                                          ? Colors.red.shade700
                                          : Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Your Assigned Consultations",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
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
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
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
                                builder:
                                    (context) =>
                                        const OpenConsultationsScreen(),
                              ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: ListTile(
                        leading: Icon(Icons.document_scanner_outlined),
                        title: Text(consultation.title),
                        subtitle: Text(
                          'Updated: ${consultation.updatedAt.toString().split(' ')[0]}',
                        ),
                        trailing: Icon(
                          consultation.isCompleted
                              ? Icons.check_circle
                              : Icons.pending,
                          color:
                              consultation.isCompleted
                                  ? Colors.green
                                  : Colors.orange,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AcceptedConsultation(
                                consultationId: consultation.id,
                                doctorId: authService.currentUser!.uid,
                              ),
                            ),
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
          bool isAvailable =
              snapshot.hasData ? snapshot.data!.isAvailable : false;

          return FloatingActionButton(
            child: const Icon(Icons.search),
            onPressed: () {
              if (!isAvailable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'You are currently offline. Go online to accept consultations.',
                    ),
                  ),
                );
                return;
              }

              // View open consultations
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OpenConsultationsScreen(),
                ),
              );
            },
            backgroundColor: isAvailable ? null : Colors.grey,
          );
        },
      ),
    );
  }
}
