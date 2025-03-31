import 'package:hive_flutter/hive_flutter.dart';
import '../Reminder/notification_service.dart';
import '../Reminder/scheduler.dart';

class InitService {
  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox('reminders');
    await NotificationService.init();
    await ReminderScheduler.scheduleReminders([
      {"medicine name": "Paracetamol", "when to take": "morning"},
      {"medicine name": "Vitamin C", "when to take": "afternoon"},
      {"medicine name": "Antibiotic", "when to take": "evening"},
    ]);
  }
}
