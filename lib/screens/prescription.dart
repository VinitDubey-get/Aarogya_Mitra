import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionModel {
  final List<Map<String, dynamic>> medicines; // Medicine name with timings
  final List<String> labTests;

  PrescriptionModel({
    required this.medicines,
    required this.labTests,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> medicinesList = [];
    if (json['medicines'] != null) {
      (json['medicines'] as List).forEach((medicine) {
        if (medicine is Map<String, dynamic>) {
          medicinesList.add(medicine);
        }
      });
    }

    return PrescriptionModel(
      medicines: medicinesList,
      labTests: json['labTests'] != null ? List<String>.from(json['labTests']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicines': medicines,
      'labTests': labTests,
    };
  }
}

class Prescription extends StatefulWidget {
  final String consultationId;
  const Prescription({super.key, required this.consultationId});

  @override
  State<Prescription> createState() => _PrescriptionState();
}

class _PrescriptionState extends State<Prescription> {
  bool isLoading = true;
  Map<String, dynamic>? consultationData;
  PrescriptionModel? prescriptionData;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache to store doctor information to avoid redundant fetches
  Map<String, String> _doctorCache = {};

  @override
  void initState() {
    super.initState();
    fetchConsultationData();
  }

  // Fetch doctor information from Firestore
  Future<String> _fetchDoctorName(String doctorId) async {
    // Check if doctor info is already in cache
    if (_doctorCache.containsKey(doctorId)) {
      return _doctorCache[doctorId]!;
    }

    try {
      final doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();

      if (doctorDoc.exists) {
        String doctorName = doctorDoc['name'] ?? 'Unknown Doctor';

        // Store in cache for future use
        _doctorCache[doctorId] = doctorName;
        return doctorName;
      } else {
        return 'Unknown Doctor';
      }
    } catch (e) {
      print('Error fetching doctor info: $e');
      return 'Unknown Doctor';
    }
  }

  Future<void> fetchConsultationData() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      DocumentSnapshot consultationDoc = await _firestore
          .collection('consultations')
          .doc(widget.consultationId)
          .get();
      
      if (consultationDoc.exists) {
        final data = consultationDoc.data() as Map<String, dynamic>;
        
        setState(() {
          consultationData = data;
          
          // Parse prescription data if it exists
          if (data.containsKey('prescription') && data['prescription'] != null) {
            prescriptionData = PrescriptionModel.fromJson(data['prescription']);
          }
          
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation not found')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching consultation: ${e.toString()}')),
      );
      print('Error fetching consultation: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : consultationData == null
              ? const Center(child: Text('No consultation data found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildConsultationInfoCard(),
                      const SizedBox(height: 20),
                      prescriptionData != null
                          ? _buildPrescriptionCard()
                          : const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  'No prescription data available for this consultation',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildConsultationInfoCard() {
    // Format timestamp to readable date if available
    String formattedDate = 'N/A';
    if (consultationData!.containsKey('createdAt') && consultationData!['createdAt'] != null) {
      try {
        Timestamp timestamp = consultationData!['createdAt'] as Timestamp;
        DateTime dateTime = timestamp.toDate();
        formattedDate = '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
      } catch (e) {
        print('Error formatting date: $e');
      }
    }

    // Get doctorId from consultation data
    String doctorId = consultationData!['doctorId'] ?? '';

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   'Consultation ID: ${widget.consultationId}',
            //   style: const TextStyle(fontWeight: FontWeight.bold),
            // ),
            const SizedBox(height: 10),
            Text('Date: $formattedDate'),
            const SizedBox(height: 10),
            FutureBuilder<String>(
              future: doctorId.isNotEmpty ? _fetchDoctorName(doctorId) : Future.value('Unknown Doctor'),
              builder: (context, snapshot) {
                String doctorName = snapshot.connectionState == ConnectionState.waiting
                    ? 'Loading...'
                    : snapshot.data ?? 'Unknown Doctor';
                return Text('Doctor: Dr. $doctorName');
              },
            ),
            const SizedBox(height: 10),
            Text('Patient: ${consultationData!['patientName'] ?? 'N/A'}'),
            const SizedBox(height: 10),
            Text('Status: ${consultationData!['status'] ?? 'N/A'}'),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prescription Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            
            // Medicines Section
            const Text(
              'Medicines:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (prescriptionData!.medicines.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: prescriptionData!.medicines.length,
                itemBuilder: (context, index) {
                  final medicine = prescriptionData!.medicines[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine['name'] ?? 'Unnamed Medicine',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text('Timing: ${medicine['timing'] ?? 'Not specified'}'),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              const Text('No medicines prescribed', style: TextStyle(fontStyle: FontStyle.italic)),
            
            const SizedBox(height: 20),
            
            // Lab Tests Section
            const Text(
              'Lab Tests:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (prescriptionData!.labTests.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: prescriptionData!.labTests.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        prescriptionData!.labTests[index],
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  );
                },
              )
            else
              const Text('No lab tests recommended', style: TextStyle(fontStyle: FontStyle.italic)),
            
            // Prescription Timestamp
            if (consultationData!.containsKey('prescription') && 
                consultationData!['prescription'] is Map && 
                consultationData!['prescription'].containsKey('timestamp'))
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  'Prescribed on: ${_formatTimestamp(consultationData!['prescription']['timestamp'])}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
    }
    return 'Date not available';
  }
}
