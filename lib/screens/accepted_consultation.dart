import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class AcceptedConsultation extends StatefulWidget {
  final String consultationId;
  const AcceptedConsultation({super.key, required this.consultationId, required String doctorId});

  @override
  _AcceptedConsultationState createState() => _AcceptedConsultationState();
}

class _AcceptedConsultationState extends State<AcceptedConsultation> {
  final TextEditingController _textController = TextEditingController();
  List<Map<String, dynamic>> medicines = [];
  List<String> labTests = [];
  String selectedCategory = "Medicine";
  bool morning = false;
  bool afternoon = false;
  bool night = false;

  bool isLoading = true;
  Map<String, dynamic>? consultationData;
  PrescriptionModel? prescriptionData;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    fetchConsultationData();
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

          if (data.containsKey('prescription') && data['prescription'] != null) {
            prescriptionData = PrescriptionModel.fromJson(data['prescription']);
            medicines = prescriptionData!.medicines;
            labTests = prescriptionData!.labTests;
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
    }
  }

  Future<void> sendPrescription() async {
    try {
      String? doctorId = FirebaseAuth.instance.currentUser?.uid;

      if (doctorId == null) {
        print("Error: Doctor not authenticated");
        return;
      }

      await _firestore.collection("consultations").doc(widget.consultationId).update({
        "doctorId": doctorId,
        "prescription": {
          "medicines": medicines.map((med) => med).toList(),
          "labTests": labTests,
          "timestamp": FieldValue.serverTimestamp(),
        },
        "isCompleted": true,
      });

      print("✅ Prescription updated successfully");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Prescription updated successfully")),
      );
    } catch (e) {
      print("❌ Error updating prescription: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating prescription: $e")),
      );
    }
  }

  void addItem() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        if (selectedCategory == "Medicine") {
          medicines.add({
            'name': _textController.text,
            'timing': _formatTimings(morning, afternoon, night),
          });
        } else {
          labTests.add(_textController.text);
        }
        _textController.clear();
        morning = false;
        afternoon = false;
        night = false;
      });
    }
  }

  String _formatTimings(bool morning, bool afternoon, bool night) {
    List<String> timings = [];
    if (morning) timings.add("Morning");
    if (afternoon) timings.add("Afternoon");
    if (night) timings.add("Night");
    return timings.isEmpty ? "Not specified" : timings.join(", ");
  }

  void removeItem(int index) {
    setState(() {
      if (selectedCategory == "Medicine") {
        medicines.removeAt(index);
      } else {
        labTests.removeAt(index);
      }
    });
  }

  Future<String> _fetchDoctorName(String doctorId) async {
    try {
      final doctorDoc = await _firestore.collection('doctors').doc(doctorId).get();
      if (doctorDoc.exists) {
        final data = doctorDoc.data();
        return data?['name'] ?? 'Unknown Doctor';
      }
      return 'Unknown Doctor';
    } catch (e) {
      print('Error fetching doctor name: $e');
      return 'Unknown Doctor';
    }
  }

  Future<void> generateAndSavePDF() async {
    final ByteData imageData = await rootBundle.load('assets/logo.png');
    final Uint8List logoBytes = imageData.buffer.asUint8List();
    String doctorName = await _fetchDoctorName(consultationData!['doctorId'] ?? '');
    
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Arogya Mitra Prescription",
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Image(
                    pw.MemoryImage(logoBytes),
                    width: 100,
                    height: 100,
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Text(
                "Date: ${DateTime.now().toLocal().toString().split(' ')[0]}",
                style: pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 10),
              pw.Text("Doctor: Dr. $doctorName"),
              pw.Text("Patient: ${consultationData!['patientName'] ?? 'N/A'}"),
              if (prescriptionData?.medicines.isNotEmpty ?? false) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  "Medicines:",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                ...prescriptionData!.medicines.map((med) => 
                  pw.Text("- ${med['name']} (Timing: ${med['timing']})"),
                ),
              ],
              if (prescriptionData?.labTests.isNotEmpty ?? false) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  "Lab Tests:",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                ...prescriptionData!.labTests.map((test) => 
                  pw.Text("- $test")
                ),
              ],
              pw.SizedBox(height: 20),
              pw.Divider(),
            ],
          );
        },
      ),
    );

    Directory? directory = await getApplicationDocumentsDirectory();
    String filePath = "${directory.path}/prescription_${widget.consultationId}.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    OpenFile.open(filePath);
  }

  void showPrescriptionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: EdgeInsets.all(16),
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    CupertinoSegmentedControl<String>(
                      groupValue: selectedCategory,
                      onValueChanged: (value) {
                        setModalState(() => selectedCategory = value);
                      },
                      selectedColor: Colors.blue,
                      unselectedColor: Colors.white,
                      borderColor: Colors.blue,
                      children: {
                        "Medicine": Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text("Medicine"),
                        ),
                        "Lab Test": Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text("Lab Test"),
                        ),
                      },
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        labelText:
                            selectedCategory == "Medicine"
                                ? "Enter Medicine"
                                : "Enter Lab Test",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (selectedCategory == "Medicine")
                      Column(
                        children: [
                          CheckboxListTile(
                            title: Text("Morning"),
                            value: morning,
                            onChanged:
                                (val) => setModalState(() => morning = val!),
                          ),
                          CheckboxListTile(
                            title: Text("Afternoon"),
                            value: afternoon,
                            onChanged:
                                (val) => setModalState(() => afternoon = val!),
                          ),
                          CheckboxListTile(
                            title: Text("Night"),
                            value: night,
                            onChanged:
                                (val) => setModalState(() => night = val!),
                          ),
                        ],
                      ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        if (_textController.text.isNotEmpty) {
                          setState(() {
                            if (selectedCategory == "Medicine") {
                              medicines.add({
                                'name': _textController.text,
                                'timing': _formatTimings(
                                  morning,
                                  afternoon,
                                  night,
                                ),
                              });
                            } else {
                              labTests.add(_textController.text);
                            }
                            _textController.clear();
                            morning = false;
                            afternoon = false;
                            night = false;
                          });
                        }
                        setModalState(() {});
                      },
                      child: Text("Add"),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child:
                          selectedCategory == "Medicine"
                              ? _buildList(medicines, setModalState)
                              : _buildList(
                                labTests.map((e) => {'name': e}).toList(),
                                setModalState,
                              ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        sendPrescription();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text(
                        "Save",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> items,
    StateSetter setModalState,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            title: Text(items[index]['name']),
            subtitle:
                items[index].containsKey('timing')
                    ? Text("Timing: ${items[index]['timing']}")
                    : null,
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setModalState(() => removeItem(index));
              },
            ),
          ),
        );
      },
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
            Text(
              'Current Prescription',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            // Medicines Section
            const Text(
              'Medicines:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (prescriptionData?.medicines.isNotEmpty ?? false)
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
              const Text('No medicines prescribed', 
                style: TextStyle(fontStyle: FontStyle.italic)),
            
            const SizedBox(height: 20),
            
            // Lab Tests Section
            const Text(
              'Lab Tests:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (prescriptionData?.labTests.isNotEmpty ?? false)
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
              const Text('No lab tests recommended', 
                style: TextStyle(fontStyle: FontStyle.italic)),
            
            // Prescription Timestamp
            if (consultationData?['prescription']?['timestamp'] != null)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Prescription Manager"),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: generateAndSavePDF,
          ),
        ],
      ),
      body: isLoading 
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Show consultation info
                  if (consultationData != null) ...[
                    Card(
                      child: ListTile(
                        title: Text('Patient: ${consultationData?['patientName'] ?? 'N/A'}'),
                        subtitle: Text('Status: ${consultationData?['status'] ?? 'N/A'}'),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                  // Show prescription if exists
                  if (prescriptionData != null)
                    _buildPrescriptionCard(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showPrescriptionSheet,
        child: Icon(Icons.edit),
        tooltip: 'Edit Prescription',
      ),
    );
  }
}

class PrescriptionModel {
  final List<Map<String, dynamic>> medicines;
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
