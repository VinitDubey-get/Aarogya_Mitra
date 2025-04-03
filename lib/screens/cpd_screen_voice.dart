import 'package:ai_doc/screens/patient_home.dart';
import 'package:ai_doc/screens/video_call.dart';
import 'package:chat_bubbles/bubbles/bubble_special_three.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:ai_doc/services/gemini_service.dart';
import 'package:ai_doc/utils/const.dart';
import 'package:provider/provider.dart';
import 'package:ai_doc/services/auth_service.dart';
import 'package:ai_doc/services/firestore_service.dart';
import 'package:ai_doc/models/consultation.dart';

class CPDScreen extends StatefulWidget {
  const CPDScreen({super.key});

  @override
  State<CPDScreen> createState() => _CPDScreenState();
}

class _CPDScreenState extends State<CPDScreen> {
  /////////////////////////////////////////////////////////////////////////
  /// Text to speech
  FlutterTts flutterTts = FlutterTts();
  textToSpeechFunction(String text) {
    flutterTts.speak(text);
  }

  /////////////////////////////////////////////////////////////////////////
  /// Speech to Text
  SpeechToText speechToText = SpeechToText();
  bool enabledSpeech = false;
  String speech = '';
  final GeminiService _geminiService = GeminiService();
  String? lastQuestion;
  List<String> patientAnswers = []; // List to store all patient answers
  List<String> questionsAsked = []; // List to store all questions asked
  late final authService;

  void initSpeech() async {
    enabledSpeech = await speechToText.initialize();
    setState(() {});
  }

  void startListening() async {
    await speechToText.listen(
      onResult: onSpeechResult,
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
    );
    setState(() {});
  }

  void stopListening() async {
    await speechToText.stop();
    setState(() {});
  }

  void toggleListening() {
    if (speechToText.isListening) {
      stopListening();
    } else {
      startListening();
    }
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      speech = result.recognizedWords;
      print("Speech recognized: $speech");
      if (speechToText.isNotListening) {
        stopListening();
      }
    });
  }

  bool isCompleteAnswer = false;

  void sendAnswer() async {
    if (speech.isNotEmpty) {
      setState(() {
        print("Saved answer: $speech");
        patientAnswers.add(speech); // Store the answer in our list
      });

      try {
        // Get next question from Gemini
        final nextQuestion = await _geminiService.getNextQuestion(
          speech,
          lastQuestion: lastQuestion,
        );

        if (nextQuestion.isNotEmpty) {
          setState(() {
            questionsAsked.add(nextQuestion); // Store the question
            lastQuestion = nextQuestion;
          });

          // Check if the conversation has ended
          if (nextQuestion.contains(
            "Thank you for providing your information",
          )) {
            textToSpeechFunction(nextQuestion);
            _showSummaryDialog();
          } else {
            textToSpeechFunction(nextQuestion);
          }
        } else {
          throw Exception("Empty response from Gemini");
        }
      } catch (e) {
        print("Error getting next question: $e");
        // Generate a contextual error message
        String errorMessage =
            "I apologize, but I'm having trouble understanding your response. ";
        if (speech.length < 5) {
          errorMessage += "Could you please provide more details?";
        } else {
          errorMessage += "Could you please rephrase that?";
        }
        textToSpeechFunction(errorMessage);
      }

      setState(() {
        speech = '';
      });
    } else {
      print("Speech was empty, not moving to next question.");
      textToSpeechFunction(
        "I didn't catch that. Could you please speak again?",
      );
    }
  }

  void _showSummaryDialog() {
    final List<Map<String, String>> summary = [];

    // Ensure we only include valid question-answer pairs
    int minLength = patientAnswers.length;

    for (int i = 0; i < minLength; i++) {
      summary.add({
        "Question": i < questionsAsked.length ? questionsAsked[i] : "N/A",
        "Response": patientAnswers[i],
      });
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Your Responses"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: summary.length,
              itemBuilder: (context, index) {
                final item = summary[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Q: ${item['Question']}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("A: ${item['Response']}"),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showAppointmentSummary();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("Book Your Appointment"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createNewConsultation(
    String title,
    String patientComplaint,
  ) async {
    authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );

    final now = DateTime.now();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get current user's profile to fetch the name
      final userProfile = await firestoreService.getUserProfile(
        authService.currentUser!.uid,
      );
      final patientName = userProfile['name'] ?? 'Unknown Patient';

      final consultation = Consultation(
        id: '', // This will be assigned by Firestore
        patientId: authService.currentUser!.uid,
        doctorId: null, // Will be assigned when a doctor accepts
        title: title,
        status: 'open',
        createdAt: now,
        updatedAt: now,
        patientComplaint: patientComplaint,
        patientName: patientName, // Add patient name
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      final consultationId = await firestoreService.createConsultation(
        consultation,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Consultation created successfully! A doctor will review it soon.",
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate back to patient home
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PatientHomeScreen()),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error creating consultation: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAppointmentSummary() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Generate summary from Gemini
      final summary = await _geminiService.generateSummary();

      // Close loading dialog
      Navigator.of(context).pop();

      // Show summary dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            // title: const Text("Appointment Summary"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    "Your Appointment is registered. Join video consultation room.",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Close all screens and navigate back to welcome screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const PatientHomeScreen(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _createNewConsultation("consultation request", summary);
                  //_createNewConsultation("Consultation Title", summary);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => VideoCallScreen(
                            channelName: authService.currentUser!.uid,
                            token: AppConstants.token,
                            appId: AppConstants.appId,
                            isPatient: true,
                          ),
                    ),
                  );
                },
                child: const Text("Join In"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text("Failed to generate summary: $e"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Close"),
              ),
            ],
          );
        },
      );
    }
  }

  /////////////////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();
    initSpeech();
    // Initialize text-to-speech settings
    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    // flutterTts.setSpeechRate(0.9);

    // Start the conversation
    const initialQuestion = "What brings you in today?";
    textToSpeechFunction(initialQuestion);
    lastQuestion = initialQuestion;
    questionsAsked.add(initialQuestion); // Add initial question to the list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(44),
                    bottomRight: Radius.circular(44),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 100),
                    BubbleSpecialThree(
                      text: lastQuestion ?? "What brings you in today?",
                      isSender: false,
                      color: Colors.blue.shade200,
                    ),
                    SizedBox(height: 10),
                    BubbleSpecialThree(
                      text:
                          speechToText.isNotListening && speech.isEmpty
                              ? "Tap on mic to answer..."
                              : speech.isEmpty
                              ? "..."
                              : speech,
                      textStyle:
                          speechToText.isNotListening && speech.isEmpty
                              ? TextStyle(color: Colors.black38)
                              : TextStyle(),
                      color:
                          speechToText.isNotListening && speech.isEmpty
                              ? Colors.amber.shade200
                              : Colors.green.shade200,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: toggleListening,
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color:
                                speechToText.isListening
                                    ? Colors.redAccent
                                    : Colors.green,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    speechToText.isListening
                                        ? Colors.red
                                        : Colors.green,
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            speechToText.isListening
                                // speech.isEmpty
                                ? Icons.mic
                                : speech.isEmpty
                                ? Icons.mic_off
                                : Icons.restart_alt,
                            size: 77,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                CircleAvatar(
                  radius: 44,
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(Icons.cancel, size: 55),
                  ),
                ),
                CircleAvatar(
                  radius: 44,
                  child:
                      (speechToText.isNotListening)
                          ? IconButton(
                            onPressed: null,
                            icon: Icon(Icons.send, size: 55),
                          )
                          : IconButton(
                            onPressed: () {
                              speechToText.isNotListening ? sendAnswer() : null;
                            },
                            icon: Icon(Icons.send, size: 55),
                          ),
                ),
              ],
            ),
            SizedBox(height: 10),
            // Debug section for patient answers
            // Container(
            //   height: 150,
            //   padding: EdgeInsets.all(8),
            //   decoration: BoxDecoration(
            //     color: Colors.grey.shade200,
            //     borderRadius: BorderRadius.circular(10),
            //   ),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       Text(
            //         'Debug - Patient Answers:',
            //         style: TextStyle(
            //           fontWeight: FontWeight.bold,
            //           color: Colors.grey.shade700,
            //         ),
            //       ),
            //       SizedBox(height: 8),
            //       Expanded(
            //         child: SingleChildScrollView(
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children:
            //                 patientAnswers.asMap().entries.map((entry) {
            //                   return Padding(
            //                     padding: EdgeInsets.symmetric(vertical: 4),
            //                     child: Text(
            //                       '${entry.key + 1}. ${entry.value}',
            //                       style: TextStyle(fontSize: 12),
            //                     ),
            //                   );
            //                 }).toList(),
            //           ),
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
