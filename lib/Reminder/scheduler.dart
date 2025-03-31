import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';

class ReminderScheduler {
  static Future<void> scheduleReminders(List<Map<String, String>> remindersData) async {
    var box = Hive.box('reminders');
    box.clear(); // 🗑️ Purane reminders hatao

    Map<String, DateTime> scheduleTimes = {
      "morning": DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 15, 50),
      "afternoon": DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 15, 51),
      "evening": DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 19, 0),
    };


    for (int i = 0; i < remindersData.length; i++) {
      String medicine = remindersData[i]['medicine name']!;
      String timeCategory = remindersData[i]['when to take']!;

      if (scheduleTimes.containsKey(timeCategory)) {
        DateTime scheduleTime = scheduleTimes[timeCategory]!;

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
}
