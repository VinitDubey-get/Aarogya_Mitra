import 'package:cloud_firestore/cloud_firestore.dart';

class Doctor {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? specialization;
  final String? qualifications;
  final DateTime createdAt;
  final bool isAvailable;

  Doctor({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.specialization,
    this.qualifications,
    required this.createdAt,
    this.isAvailable = true,
  });

  factory Doctor.fromJson(Map<String, dynamic> json, String docId) {
    // Safe conversion of timestamp with null check
    DateTime createdAtDate;
    if (json['createdAt'] != null) {
      createdAtDate = (json['createdAt'] as Timestamp).toDate();
    } else {
      createdAtDate = DateTime.now(); // Fallback to current time if null
    }
    
    return Doctor(
      id: docId,
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'],
      specialization: json['specialization'],
      qualifications: json['qualifications'],
      createdAt: createdAtDate,
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'specialization': specialization,
      'qualifications': qualifications,
      'createdAt': Timestamp.fromDate(createdAt),
      'isAvailable': isAvailable,
    };
  }
}