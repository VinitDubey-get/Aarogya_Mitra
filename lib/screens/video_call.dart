import 'dart:async';
import 'dart:io';
import 'package:ai_doc/screens/doctor_home.dart';
import 'package:ai_doc/screens/prescription.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import 'open_consultations_screen.dart';

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final String token; // Optional, needed if your app uses tokens
  final String appId;
  final bool isPatient;


  const VideoCallScreen({
    Key? key,
    required this.channelName,
    this.token = '',
    required this.appId,
    required this.isPatient,
  }) : super(key: key);

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;
  bool _muted = false;
  bool _videoDisabled = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // Request permissions
    await [Permission.microphone, Permission.camera].request();

    // Create RTC engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: widget.appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    // Register callbacks
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          debugPrint("Local user joined: ${connection.localUid}");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          debugPrint("Remote user joined: $remoteUid");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          debugPrint("Remote user left: $remoteUid");
          setState(() {
            _remoteUid = null;
          });
        },
        onTokenPrivilegeWillExpire: (connection, token) async {
          debugPrint('[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
          // You would implement token renewal here
        },
      ),
    );

    // Set client role and enable video
    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine.enableVideo();
    await _engine.startPreview();

    // Join the channel
    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: 0,  // 0 means auto-assign
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Video Call: ${widget.channelName}'),
      //   centerTitle: true,
      // ),
      body: (widget.isPatient)?Stack(
        children: [
          // Remote video
          Center(
            child: _remoteUid != null
                ? AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.channelName),
              ),
            )
                : const Center(
              child: Text(
                'Waiting for doctor...',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          // Local video
          Positioned(
            right: 20,
            top: 20,
            child: SizedBox(
              width: 120,
              height: 180,
              child: _localUserJoined
                  ? AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              )
                  : const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          // Control buttons
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mute button
                RawMaterialButton(
                  onPressed: _onToggleMute,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  fillColor: _muted ? Colors.redAccent : Colors.white,
                  child: Icon(
                    _muted ? Icons.mic_off : Icons.mic,
                    color: _muted ? Colors.white : Colors.blueAccent,
                    size: 20,
                  ),
                ),
                // End call button
                RawMaterialButton(
                  onPressed: _onCallEnd,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(15),
                  fillColor: Colors.redAccent,
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                // Toggle camera button
                RawMaterialButton(
                  onPressed: _onToggleVideo,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  fillColor: _videoDisabled ? Colors.redAccent : Colors.white,
                  child: Icon(
                    _videoDisabled ? Icons.videocam_off : Icons.videocam,
                    color: _videoDisabled ? Colors.white : Colors.blueAccent,
                    size: 20,
                  ),
                ),
                // Switch camera button
                RawMaterialButton(
                  onPressed: _onSwitchCamera,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  fillColor: Colors.white,
                  child: const Icon(
                    Icons.switch_camera,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ):Stack(   // doctor video call screen
        children: [
          // Remote video
          Center(
            child: _remoteUid != null
                ? AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _engine,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.channelName),
              ),
            )
                : const Center(
              child: Text(
                'Waiting for patient...',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
          // Local video
          Positioned(
            right: 20,
            top: 20,
            child: SizedBox(
              width: 120,
              height: 180,
              child: _localUserJoined
                  ? AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _engine,
                  canvas: const VideoCanvas(uid: 0),
                ),
              )
                  : const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          // Control buttons
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Mute button
                RawMaterialButton(
                  onPressed: _onToggleMute,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  fillColor: _muted ? Colors.redAccent : Colors.white,
                  child: Icon(
                    _muted ? Icons.mic_off : Icons.mic,
                    color: _muted ? Colors.white : Colors.blueAccent,
                    size: 20,
                  ),
                ),
                // End call button
                RawMaterialButton(
                  onPressed: _onCallEnd,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(15),
                  fillColor: Colors.redAccent,
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                // Toggle camera button
                RawMaterialButton(
                  onPressed: _onToggleVideo,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  fillColor: _videoDisabled ? Colors.redAccent : Colors.white,
                  child: Icon(
                    _videoDisabled ? Icons.videocam_off : Icons.videocam,
                    color: _videoDisabled ? Colors.white : Colors.blueAccent,
                    size: 20,
                  ),
                ),
                // Switch camera button
                RawMaterialButton(
                  onPressed: _onSwitchCamera,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  fillColor: Colors.white,
                  child: const Icon(
                    Icons.switch_camera,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
              bottom: 150,
              right: 10,
              child: RawMaterialButton(
    onPressed: showPrescriptionSheet,
    shape: const CircleBorder(),
    padding: const EdgeInsets.all(10),
    fillColor: Colors.green,
    child: Icon(Icons.edit,
    color: Colors.white,
    size: 44,
    ),
    ))
        ],
      ),
    );
  }

  void _onToggleMute() {
    setState(() {
      _muted = !_muted;
    });
    _engine.muteLocalAudioStream(_muted);
  }

  void _onToggleVideo() {
    setState(() {
      _videoDisabled = !_videoDisabled;
    });
    _engine.muteLocalVideoStream(_videoDisabled);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  void _onCallEnd() {
    if(widget.isPatient){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Prescription()));
    }else{
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>DoctorHomeScreen()));
    }
  }

  /// prescription functionality

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

  Future<void> sendPrescription(String patientId, List<Map<String, dynamic>> medicines, List<String> labTests) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Fetch the latest consultation for the patient
      QuerySnapshot querySnapshot = await firestore
          .collection("consultations")
          .where("patientId", isEqualTo: patientId)
          .orderBy("createdAt", descending: true)  // Requires an index
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("No active consultations found for this patient.");
        return;
      }

      // Get the latest consultation ID
      String consultationId = querySnapshot.docs.first.id;

      // Update the prescription field
      await firestore.collection("consultations").doc(consultationId).update({
        "prescription": {
          "medicines": medicines.map((med) => med).toList(), // Ensure correct format
          "labTests": labTests,
          "timestamp": FieldValue.serverTimestamp(),
        }
      });

      print("✅ Prescription updated successfully for consultation: $consultationId");
    } catch (e) {
      print("❌ Error updating prescription: $e");
    }
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

    // OpenFile.open(filePath);
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
                      onPressed: (){
                        // generateAndSavePDF();
                        sendPrescription(widget.channelName, medicines, labTests);

                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: Text("Send", style: TextStyle(color: Colors.white)),
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

}