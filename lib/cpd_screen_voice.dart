import 'package:chat_bubbles/bubbles/bubble_special_three.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:ai_doc/cpd_helper.dart';

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

  void initSpeech() async {
    enabledSpeech = await speechToText.initialize();
    setState(() {});
  }

  void startListening() async {
    await speechToText.listen(
      onResult: onSpeechResult,
      listenMode: ListenMode.dictation, // Enables continuous listening
      partialResults: true, // Allow partial speech updates
      cancelOnError: false, // Keep listening even if an error occurs
    );
    setState(() {});
  }

  void onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      speech = result.recognizedWords;
      print("Speech recognized: $speech"); // Debugging
      if (speechToText.isNotListening) {
        stopListening();
      }
    });
  }

  bool isCompleteAnswer = false;
  void stopListening() async {
    await speechToText.stop();
    isCompleteAnswer = true;
    print("Final recognized speech: $speech");
  }

  void sendAnswer() {
    if (speech.isNotEmpty) {
      setState(() {
        answers.add(speech);
        print("Saved answer: ${answers.last}");
        speech = '';

        if (counter < questions.length - 1) {
          counter++;
          print("Next question: ${questions[counter]}");
          textToSpeechFunction(questions[counter]);
        } else {
          print("All questions answered.");
        }
      });
    } else {
      print("Speech was empty, not moving to next question.");
    }
  }

  /////////////////////////////////////////////////////////////////////////

  @override
  void initState() {
    super.initState();
    initSpeech();
    textToSpeechFunction(questions[counter]);
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
                      text: questions[counter],
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
                        onTap: () {
                          if (speechToText.isNotListening) {
                            startListening();
                          } else {
                            stopListening();
                          }
                        },
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
                                ? Icons
                                    .mic // 🔴 Listening
                                : speech.isNotEmpty
                                ? Icons
                                    .restart_alt // 🔄 Restart if answer recorded
                                : Icons.mic_off, // 🎤 Mic off
                            size: 77,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(answers.toString()),
                    ),
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
                  child: IconButton(
                    onPressed: () {
                      speechToText.isNotListening ? sendAnswer() : null;
                    },
                    icon: Icon(Icons.send, size: 55),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
