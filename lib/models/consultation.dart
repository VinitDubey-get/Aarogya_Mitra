import 'package:cloud_firestore/cloud_firestore.dart';

class Consultation {
  final String id;
  final String patientId;
  final String? doctorId;
  final String title;
  final String status; // 'open', 'assigned', 'completed'
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? patientComplaint;
  final DateTime? consultationDate;
  final bool isCompleted;
  final String patientName;
  final Prescription? prescription; // Added prescription field

  Consultation({
    required this.id,
    required this.patientId,
    this.doctorId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.patientComplaint,
    this.consultationDate,
    this.isCompleted = false,
    this.patientName = 'Unknown Patient',
    this.prescription, // Initialize prescription
  });

  factory Consultation.fromJson(Map<String, dynamic> json, String docId) {
    DateTime? createdAtDate;
    if (json['createdAt'] != null) {
      createdAtDate = (json['createdAt'] as Timestamp).toDate();
    }

    DateTime? updatedAtDate;
    if (json['updatedAt'] != null) {
      updatedAtDate = (json['updatedAt'] as Timestamp).toDate();
    }

    DateTime? consultationDateValue;
    if (json['consultationDate'] != null) {
      consultationDateValue = (json['consultationDate'] as Timestamp).toDate();
    }

    Prescription? prescriptionValue;
    if (json['prescription'] != null) {
      prescriptionValue = Prescription.fromJson(json['prescription']);
    }

    return Consultation(
      id: docId,
      patientId: json['patientId'] ?? '',
      doctorId: json['doctorId'],
      title: json['title'] ?? 'New Consultation',
      status: json['status'] ?? 'open',
      createdAt: createdAtDate ?? DateTime.now(),
      updatedAt: updatedAtDate ?? DateTime.now(),
      patientComplaint: json['patientComplaint'],
      consultationDate: consultationDateValue,
      isCompleted: json['isCompleted'] ?? false,
      patientName: json['patientName'] ?? 'Unknown Patient',
      prescription: prescriptionValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'doctorId': doctorId,
      'title': title,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'patientComplaint': patientComplaint,
      'consultationDate': consultationDate != null
          ? Timestamp.fromDate(consultationDate!)
          : null,
      'isCompleted': isCompleted,
      'patientName': patientName,
      'prescription': prescription?.toJson(),
    };
  }

  Consultation copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? title,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? patientComplaint,
    DateTime? consultationDate,
    bool? isCompleted,
    String? patientName,
    Prescription? prescription,
  }) {
    return Consultation(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      title: title ?? this.title,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      patientComplaint: patientComplaint ?? this.patientComplaint,
      consultationDate: consultationDate ?? this.consultationDate,
      isCompleted: isCompleted ?? this.isCompleted,
      patientName: patientName ?? this.patientName,
      prescription: prescription ?? this.prescription,
    );
  }
}

class Prescription {
  final List<Map<String, dynamic>> medicines; // Medicine name with timings
  final List<String> labTests;

  Prescription({
    required this.medicines,
    required this.labTests,
  });

  factory Prescription.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> medicinesList = [];
    if (json['medicines'] != null) {
      json['medicines'].forEach((medicine) {
        if (medicine is Map<String, dynamic>) {
          medicinesList.add(medicine);
        }
      });
    }

    return Prescription(
      medicines: medicinesList,
      labTests: json['lab_tests'] != null ? List<String>.from(json['lab_tests']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicines': medicines,
      'lab_tests': labTests,
    };
  }
}


class ConsultationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'consultations';

  Future<String> saveConsultation(Consultation consultation) async {
    try {
      if (consultation.id.isNotEmpty) {
        await _firestore
            .collection(_collectionName)
            .doc(consultation.id)
            .update(consultation.toJson());
        return consultation.id;
      } else {
        DocumentReference docRef =
        await _firestore.collection(_collectionName).add(consultation.toJson());
        return docRef.id;
      }
    } catch (e) {
      print("Error saving consultation: $e");
      throw Exception("Failed to save consultation: $e");
    }
  }
}