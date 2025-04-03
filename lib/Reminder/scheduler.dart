import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';

class ReminderScheduler {
  static Future<void> scheduleReminders(List<Map<String, String>> remindersData) async {
    var box = Hive.box('reminders');
    box.clear(); // 🗑️ Purane reminders hatao
    // print(remindersData);

    Map<String, DateTime> scheduleTimes = {
      "morning": DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 9, 0),
      "afternoon": DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 14, 0),
      // "evening": DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 20, 0),
      "night": DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 20, 0),
      "not specified": DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 18, 33),
    };


    for (int i = 0; i < remindersData.length; i++) {
      String medicine = remindersData[i]['medicine name']!;
      String timeCategory = remindersData[i]['when to take']!;

      // Default time if category not found
      DateTime scheduleTime = scheduleTimes["not specified"]!;
      
      if (scheduleTimes.containsKey(timeCategory)) {
        scheduleTime = scheduleTimes[timeCategory]!;
      }
      
      await NotificationService.scheduleNotification(
        i + 1,
        "Time to take your medicine",
        "Take $medicine",
        scheduleTime,
      );

      // ✅ Save reminders in Hive for UI display
      box.add({
        'medicine': medicine,
        'time': DateFormat.jm().format(scheduleTime), // Convert to 12-hour format
      });
    }
  }
}
