import 'package:hive_flutter/hive_flutter.dart';
import '../Reminder/notification_service.dart';
import '../Reminder/scheduler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InitService {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox('reminders');
    await NotificationService.init();
    // await ReminderScheduler.scheduleReminders([
    //   {"medicine name": "Paracetamol", "when to take": "morning"},
    //   {"medicine name": "Vitamin C", "when to take": "afternoon"},
    //   {"medicine name": "Antibiotic", "when to take": "evening"},
    // ]);

    // Fetch and schedule medicine reminders from prescriptions
    await _fetchAndScheduleMedicineReminders();
  }

  static Future<void> _fetchAndScheduleMedicineReminders() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('User not authenticated. Cannot fetch prescriptions.');
        return;
      }

      final String userId = currentUser.uid;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      print('Fetching consultations for user: $userId');

      // Fetch consultations for the current user
      // Consider only recent consultations (e.g., last 3 months) to avoid excessive processing
      final QuerySnapshot snapshot =
          await firestore
              .collection('consultations')
              .where('patientId', isEqualTo: userId)
              // .where('status', isEqualTo: 'completed') // Only consider completed consultations
              .orderBy('createdAt', descending: true) // Get most recent first
              // .limit(10) // Limit to most recent 10 consultations
              .get();

      print('Found ${snapshot.docs.length} consultations');

      List<Map<String, String>> allMedicines = [];

      // Process each consultation document
      for (final doc in snapshot.docs) {
        print('Processing consultation document ID: ${doc.id}');
        final consultationData = doc.data() as Map<String, dynamic>;

        // Check if consultation has a prescription
        if (consultationData.containsKey('prescription') &&
            consultationData['prescription'] != null) {
          final prescriptionData =
              consultationData['prescription'] as Map<String, dynamic>;
          print('Found prescription in consultation ${doc.id}');

          // Check if prescription has medicines
          if (prescriptionData.containsKey('medicines') &&
              prescriptionData['medicines'] != null) {
            final List<dynamic> medicines = prescriptionData['medicines'];
            print('Found ${medicines.length} medicines in prescription');

            // Process each medicine
            for (final medicine in medicines) {
              if (medicine is Map<String, dynamic>) {
                // Extract medicine name
                String medicineName =
                    (medicine['name'] ?? 'Unknown Medicine').toString();
                print('Processing medicine: $medicineName');

                // Check if timing is not empty
                if (medicine['timing'].isNotEmpty) {
                  // Split the timing string into a list by commas
                  List<String> timings =
                      medicine['timing']
                          .toString()
                          .split(',')
                          .map(
                            (timing) => timing.trim().toLowerCase(),
                          ) // Clean up extra spaces and convert to lowercase
                          .toList();

                  print('Medicine $medicineName has ${timings.length} timings');

                  // Iterate through each timing and add it to the list
                  for (var timing in timings) {
                    print('Adding $medicineName to take at $timing');
                    allMedicines.add({
                      "medicine name": medicineName,
                      "when to take": timing,
                    });
                  }
                } else {
                  // If timing is not provided, use default 'morning'
                  String timing = 'morning';
                  print('Adding $medicineName to take at $timing');
                  allMedicines.add({
                    "medicine name": medicineName,
                    "when to take": timing,
                  });
                }
              } else {
                print(
                  'Warning: Medicine entry is not in expected format: $medicine',
                );
              }
            }
          } else {
            print(
              'No medicines found in prescription for consultation ${doc.id}',
            );
          }
        } else {
          print('No prescription found for consultation ${doc.id}');
        }
      }

      // If we have medicines to schedule, call the scheduler
      if (allMedicines.isNotEmpty) {
        print('Scheduling ${allMedicines.length} medicine reminders:');
        allMedicines.forEach(
          (medicine) => print(
            '  - ${medicine["medicine name"]} at ${medicine["when to take"]}',
          ),
        );
        await ReminderScheduler.scheduleReminders(allMedicines);
      } else {
        print('No medicines found in prescriptions to schedule');
      }
    } catch (e) {
      print('Error fetching and scheduling medicine reminders: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}, message: ${e.message}');
      }
    }
  }
}
