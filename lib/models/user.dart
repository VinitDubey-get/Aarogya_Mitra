import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String userType; // 'doctor' or 'patient'
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json, String docId) {
    return AppUser(
      id: docId,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      userType: json['userType'] ?? '',
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'userType': userType,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
