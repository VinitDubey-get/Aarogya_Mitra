import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseDebugHelper {
  // Debug method to print all fields of a document
  static void printDocumentFields(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      print('Document ${doc.id} has no data');
      return;
    }

    print('Document ${doc.id} fields:');
    data.forEach((key, value) {
      print('  $key: $value (${value?.runtimeType})');
    });
  }

  // Validate a consultation document
  static bool isValidConsultation(Map<String, dynamic> data) {
    final requiredFields = ['patientId', 'title', 'status'];
    
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        print('Missing required field: $field');
        return false;
      }
    }

    // Check timestamp fields
    if (data['createdAt'] == null) {
      print('Missing createdAt timestamp');
      return false;
    }
    
    if (data['updatedAt'] == null) {
      print('Missing updatedAt timestamp');
      return false;
    }

    return true;
  }

  // Method to display debug info in the UI
  static Widget buildDebugCard(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    return Card(
      color: Colors.amber[100],
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug: Document ${doc.id}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            if (data != null)
              ...data.entries.map((entry) => Text(
                '${entry.key}: ${_formatValue(entry.value)}',
                style: const TextStyle(fontFamily: 'monospace'),
              )),
            if (data == null) const Text('No data in document'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                printDocumentFields(doc);
              },
              child: const Text('Print Details to Console'),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatValue(dynamic value) {
    if (value == null) {
      return 'null';
    } else if (value is Timestamp) {
      return '${value.toDate()} (Timestamp)';
    } else {
      return '$value (${value.runtimeType})';
    }
  }
}
