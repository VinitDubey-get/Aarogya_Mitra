import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  /// **Initialize Notifications**
  static Future<void> init() async {
    final AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: onNotificationTap,
    );

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    var status = await Permission.notification.status;
    print("Notification permission status: $status");

    if (status.isDenied || status.isPermanentlyDenied) {
      await Permission.notification.request();
    }

    if (await Permission.notification.isDenied) {
      await openAppSettings();
    }

    print("Notification Service Initialized!");
  }

  /// **Schedule a Notification with Stop Button**
  static Future<void> scheduleNotification(
      int id, String title, String body, DateTime time) async {
    final tz.TZDateTime scheduledTime = tz.TZDateTime.from(time, tz.local);

    print("\ud83d\udcc5 Scheduled Notification at: $scheduledTime");

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel 1',
      'Medicine Reminder',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarm'),
      actions: [
        AndroidNotificationAction(
          'STOP_ACTION',
          'Stop',
          cancelNotification: true, // ✅ Auto-dismiss
        ),
      ],
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// **Handle Notification Tap & Stop Button**
  static void onNotificationTap(NotificationResponse response) {
    if (response.actionId == 'STOP_ACTION') {
      print("\ud83d\udeab Stop button clicked!");
      Hive.box('reminders').put('status', 'done');
    }
  }
}