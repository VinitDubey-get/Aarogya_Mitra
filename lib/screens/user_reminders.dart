import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  @override
  Widget build(BuildContext context) {
    var box = Hive.box('reminders'); // ✅ Get reminders from Hive

    return Scaffold(
      appBar: AppBar(title: Text("Medicine Reminders")),
      body: box.isEmpty
          ? Center(child: Text("No reminders scheduled!"))
          : ListView.builder(
        itemCount: box.length,
        itemBuilder: (context, index) {
          var reminder = box.getAt(index); // 🔥 Fetch each reminder
          print(reminder);
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(reminder['medicine'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: Text("Time: ${reminder['time']}"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, color: Colors.blue),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        box.deleteAt(index); // 🔥 Delete the reminder
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
