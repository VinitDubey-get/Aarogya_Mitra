import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String consultationId;
  final String senderId;
  final String senderType; // 'doctor', 'patient', 'ai'
  final String senderName;
  final String content;
  final DateTime timestamp;
  final String messageType; // 'text', 'image', 'audio', etc.

  Message({
    required this.id,
    required this.consultationId,
    required this.senderId,
    required this.senderType,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.messageType = 'text',
  });

  factory Message.fromJson(Map<String, dynamic> json, String docId) {
    // Safe conversion of timestamp with null check
    DateTime timestampDate;
    if (json['timestamp'] != null) {
      timestampDate = (json['timestamp'] as Timestamp).toDate();
    } else {
      timestampDate = DateTime.now(); // Fallback to current time if null
    }
    
    return Message(
      id: docId,
      consultationId: json['consultationId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderType: json['senderType'] ?? '',
      senderName: json['senderName'] ?? '',
      content: json['content'] ?? '',
      timestamp: timestampDate,
      messageType: json['messageType'] ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consultationId': consultationId,
      'senderId': senderId,
      'senderType': senderType,
      'senderName': senderName,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'messageType': messageType,
    };
  }
}
