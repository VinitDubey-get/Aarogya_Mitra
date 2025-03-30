import 'package:flutter/material.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  bool isActive = false;

  void toggleActivation() {
    setState(() {
      isActive = !isActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        centerTitle: true,
        backgroundColor: isActive ? Colors.green : Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [isActive ? Colors.green.shade50 : Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.medical_services, size: 100, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Doctor Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Manage your patient consultations',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 30),

              // Activation Status Container
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  isActive ? 'Status: Active' : 'Status: Inactive',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                ),
              ),
              
              const SizedBox(height: 15),
              
              // Activation Toggle Button
              ElevatedButton(
                onPressed: toggleActivation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? Colors.red : Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  isActive ? 'Click to Deactivate' : 'Click to Activate',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Pending consultations card
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pending Consultations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No pending consultations',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      Icon(Icons.queue, size: 48, color: Colors.blue),
                    ],
                  ),
                ),
              ),
              
              // Completed consultations card
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completed Consultations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No completed consultations',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      Icon(Icons.check_circle, size: 48, color: Colors.green),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
