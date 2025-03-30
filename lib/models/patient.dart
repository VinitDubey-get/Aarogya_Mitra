import 'package:cloud_firestore/cloud_firestore.dart';

class Patient {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? phoneNumber;
  final DateTime createdAt;
  final Map<String, dynamic>? medicalHistory;

  Patient({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.createdAt,
    this.medicalHistory,
  });

  factory Patient.fromJson(Map<String, dynamic> json, String docId) {
    // Safe conversion of timestamp with null check
    DateTime createdAtDate;
    if (json['createdAt'] != null) {
      createdAtDate = (json['createdAt'] as Timestamp).toDate();
    } else {
      createdAtDate = DateTime.now(); // Fallback to current time if null
    }
    
    return Patient(
      id: docId,
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      createdAt: createdAtDate,
      medicalHistory: json['medicalHistory'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'medicalHistory': medicalHistory,
    };
  }
}