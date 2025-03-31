import 'package:ai_doc/screens/patient_home.dart';
import 'package:ai_doc/screens/video_call.dart';
import 'package:flutter/material.dart';
import 'package:ai_doc/screens/cpd_screen_voice.dart';
import 'package:ai_doc/services/gemini_service.dart';
import 'package:provider/provider.dart';
import 'package:ai_doc/services/auth_service.dart';
import 'package:ai_doc/services/firestore_service.dart';
import 'package:ai_doc/models/consultation.dart';

class ChatScreen extends StatefulWidget {
  final Consultation? consultation;
  const ChatScreen({super.key, this.consultation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final GeminiService _geminiService = GeminiService();
  bool isWaitingForResponse = false;
  String? lastQuestion;

  @override
  void initState() {
    super.initState();
    // Start with the first question
    Future.delayed(const Duration(milliseconds: 500), () {
      _addBotMessage("What brings you in today?");
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    setState(() {
      _messages.add(
        ChatMessage(text: userMessage, isMe: true, time: DateTime.now()),
      );
      isWaitingForResponse = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Get next question from Gemini
      final nextQuestion = await _geminiService.getNextQuestion(
        userMessage,
        lastQuestion: lastQuestion,
      );

      lastQuestion = nextQuestion;

      // Check if the conversation has ended
      if (nextQuestion.contains("Thank you for providing your information")) {
        _addBotMessage(nextQuestion);
        _showSummaryDialog();
      } else {
        _addBotMessage(nextQuestion);
      }
    } catch (e) {
      print("Error getting next question: $e");
      _addBotMessage(
        "I apologize, but I'm having trouble processing your response. Could you please rephrase that?",
      );
    }
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isMe: false, time: DateTime.now()));
      isWaitingForResponse = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showSummaryDialog() {
    final List<Map<String, String>> summary = [];
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].isMe) {
        summary.add({
          "Question": i > 0 ? _messages[i - 1].text : "N/A",
          "Response": _messages[i].text,
        });
      }
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
            title: const Text("Appointment Summary"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Here's a summary of your symptoms that will be shared with your doctor:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(summary),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Close all screens and navigate back to welcome screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const PatientHomeScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  //_createNewConsultation("Consultation Title", summary);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) =>  BlackScreen()),
                  );
                },
                child: const Text("Confirm Appointment"),
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

  Future<void> _createNewConsultation(String title, String patientComplaint) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    final now = DateTime.now();
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    try {
      // Get current user's profile to fetch the name
      final userProfile = await firestoreService.getUserProfile(authService.currentUser!.uid);
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
      
      final consultationId = await firestoreService.createConsultation(consultation);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Consultation created successfully! A doctor will review it soon."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Navigate back to patient home
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PatientHomeScreen())
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.grey[100]),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),
          ),
          if (isWaitingForResponse)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Doctor is typing...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),

          // Add the Gemini Debug Box here
          // GeminiDebugBox(geminiService: _geminiService),

          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isMe ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isMe ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.time),
              style: TextStyle(
                color: message.isMe ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your answer...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: isWaitingForResponse ? null : _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: Colors.teal,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.mic, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CPDScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime time;

  ChatMessage({required this.text, required this.isMe, required this.time});
}
