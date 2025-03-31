import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class DoctorVideo extends StatefulWidget {
  const DoctorVideo({super.key});

  @override
  _DoctorVideoState createState() => _DoctorVideoState();
}

class _DoctorVideoState extends State<DoctorVideo> {
  final TextEditingController _textController = TextEditingController();
  List<Map<String, dynamic>> medicines = [];
  List<String> labTests = [];
  String selectedCategory = "Medicine";
  bool morning = false;
  bool afternoon = false;
  bool night = false;

  void addItem() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        if (selectedCategory == "Medicine") {
          medicines.add({
            'name': _textController.text,
            'timing': _formatTimings(morning, afternoon, night),
          });
        } else {
          labTests.add(_textController.text);
        }
        _textController.clear();
        morning = false;
        afternoon = false;
        night = false;
      });
    }
  }

  String _formatTimings(bool morning, bool afternoon, bool night) {
    List<String> timings = [];
    if (morning) timings.add("Morning");
    if (afternoon) timings.add("Afternoon");
    if (night) timings.add("Night");
    return timings.isEmpty ? "Not specified" : timings.join(", ");
  }

  void removeItem(int index) {
    setState(() {
      if (selectedCategory == "Medicine") {
        medicines.removeAt(index);
      } else {
        labTests.removeAt(index);
      }
    });
  }

  Future<void> generateAndSavePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "My Prescription App",
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text("Dr. John Doe", style: pw.TextStyle(fontSize: 18)),
              pw.Text("Specialist in General Medicine"),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Text(
                "Date: ${DateTime.now().toLocal().toString().split(' ')[0]}",
                style: pw.TextStyle(fontSize: 16),
              ),
              pw.SizedBox(height: 10),
              if (medicines.isNotEmpty) ...[
                pw.Text("Medicines:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                for (var med in medicines)
                  pw.Text("- ${med['name']} (Timing: ${med['timing']})"),
              ],
              pw.SizedBox(height: 10),
              if (labTests.isNotEmpty) ...[
                pw.Text("Lab Tests:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                for (var test in labTests) pw.Text("- $test"),
              ],
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.Text(
                "Dr. John Doe\n(Signature)",
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );

    Directory? directory = await getApplicationDocumentsDirectory();
    String filePath = "${directory.path}/prescription.pdf";
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    OpenFile.open(filePath);
  }

  void showPrescriptionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: EdgeInsets.all(16),
                height: MediaQuery.of(context).size.height * 0.6,
                child: Column(
                  children: [
                    CupertinoSegmentedControl<String>(
                      groupValue: selectedCategory,
                      onValueChanged: (value) {
                        setModalState(() => selectedCategory = value);
                      },
                      selectedColor: Colors.blue,
                      unselectedColor: Colors.white,
                      borderColor: Colors.blue,
                      children: {
                        "Medicine": Padding(padding: const EdgeInsets.all(8), child: Text("Medicine")),
                        "Lab Test": Padding(padding: const EdgeInsets.all(8), child: Text("Lab Test")),
                      },
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        labelText: selectedCategory == "Medicine" ? "Enter Medicine" : "Enter Lab Test",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (selectedCategory == "Medicine")
                      Column(
                        children: [
                          CheckboxListTile(
                            title: Text("Morning"),
                            value: morning,
                            onChanged: (val) => setModalState(() => morning = val!),
                          ),
                          CheckboxListTile(
                            title: Text("Afternoon"),
                            value: afternoon,
                            onChanged: (val) => setModalState(() => afternoon = val!),
                          ),
                          CheckboxListTile(
                            title: Text("Night"),
                            value: night,
                            onChanged: (val) => setModalState(() => night = val!),
                          ),
                        ],
                      ),
                    SizedBox(height: 10),
                    ElevatedButton(onPressed: addItem, child: Text("Add")),
                    SizedBox(height: 10),
                    Expanded(
                      child: selectedCategory == "Medicine"
                          ? _buildList(medicines, setModalState)
                          : _buildList(labTests.map((e) => {'name': e}).toList(), setModalState),
                    ),
                    ElevatedButton(
                      onPressed: generateAndSavePDF,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: Text("Generate PDF", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, StateSetter setModalState) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            title: Text(items[index]['name']),
            subtitle: items[index].containsKey('timing')
                ? Text("Timing: ${items[index]['timing']}")
                : null,
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setModalState(() => removeItem(index));
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Prescription Manager")),
      floatingActionButton: FloatingActionButton(
        onPressed: showPrescriptionSheet,
        child: Icon(Icons.edit),
      ),
    );
  }
}
