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
  final String patientName; // Added patient name field

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
    this.patientName = 'Unknown Patient', // Default value
  });

  factory Consultation.fromJson(Map<String, dynamic> json, String docId) {
    // Safe conversion of timestamps with null checks
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
    
    return Consultation(
      id: docId,
      patientId: json['patientId'] ?? '',
      doctorId: json['doctorId'],
      title: json['title'] ?? 'New Consultation',
      status: json['status'] ?? 'open',
      createdAt: createdAtDate ?? DateTime.now(), // Fallback to current time if null
      updatedAt: updatedAtDate ?? DateTime.now(), // Fallback to current time if null
      patientComplaint: json['patientComplaint'],
      consultationDate: consultationDateValue,
      isCompleted: json['isCompleted'] ?? false,
      patientName: json['patientName'] ?? 'Unknown Patient', // Include patient name
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
      'consultationDate': consultationDate != null ? Timestamp.fromDate(consultationDate!) : null,
      'isCompleted': isCompleted,
      'patientName': patientName, // Include patient name
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
    );
  }
}