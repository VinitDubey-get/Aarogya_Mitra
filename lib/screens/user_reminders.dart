import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../services/init_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  late Box box;
  bool _isLoading = false; // Add loading state

  @override
  void initState() {
    super.initState();
    box = Hive.box('reminders');
  }

  void _refreshReminders() async {
    setState(() {
      _isLoading = true; // Show loading
    });

    try {
      await InitService.initialize();
      setState(() {
        box = Hive.box('reminders');
        _isLoading = false; // Hide loading
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // Hide loading even on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing reminders: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Medicine Reminders"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshReminders,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : box.isEmpty
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
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
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
