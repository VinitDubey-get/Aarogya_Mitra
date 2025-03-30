// import 'dart:convert';
import 'package:flutter_gemini/flutter_gemini.dart';

class GeminiService {
  final Gemini gemini = Gemini.instance;
  final List<Content> chatHistory = [];
  static const int maxHistoryLength = 10;
  String? lastFallbackQuestion;
  int questionCount = 0;
  static const int maxQuestions = 5;

  GeminiService() {
    _initializeSystemPrompt();
  }

  void _initializeSystemPrompt() {
    final systemPrompt = Content(
      parts: [
        Part.text(
          "You are an AI healthcare assistant helping patients before they visit a doctor. "
          "Ask 4-5 focused follow-up questions to gather key medical information. "
          "Keep responses concise, empathetic, and professional. "
          "Never repeat the same question unless asked to clarify. "
          "After 4-5 questions, If you don't understand any of the patient's response then ask again politely.",
        ),
      ],
      role: "model",
    );

    chatHistory.add(systemPrompt);
    print("\n=== Gemini Service Initialized ===");
  }

  Future<String> getNextQuestion(
    String patientResponse, {
    String? lastQuestion,
  }) async {
    try {
      if (questionCount >= maxQuestions) {
        return "Thank you for providing your information. A doctor will review your symptoms and get back to you soon.";
      }

      // Save patient response to chat history
      chatHistory.add(
        Content(
          parts: [Part.text(patientResponse)],
          role: "user",
        ),
      );

      // Create a simple prompt for the next question
      final prompt = "Based on the patient's response, ask a precise follow-up medical question. "
          "This should be question #${questionCount + 1} out of $maxQuestions. "
          "Make sure it's different from previous questions."
          "Example format: 'Question?'";

      // Send the request using gemini.chat() with content list
      final List<Content> contents = [...chatHistory];
      contents.add(
        Content(
          parts: [Part.text(prompt)],
          role: "user",
        ),
      );
      
    
      final response = await gemini.chat(contents);

      if (response != null && response.output != null) {
        final String nextQuestion = response.output!;
        
        // Validate the question
        if (nextQuestion.isEmpty || nextQuestion.length < 10 || !nextQuestion.contains('?')) {
          return "Can you tell me more about your symptoms?";
        }

        // Add the response to chat history
        chatHistory.add(
          Content(parts: [Part.text(nextQuestion)], role: "model"),
        );

        // Maintain history length
        if (chatHistory.length > maxHistoryLength) {
          chatHistory.removeAt(1);
        }

        questionCount++;
        return nextQuestion;
      } else {
        throw Exception("Invalid response from Gemini API.");
      }
    } catch (e) {
      print("Error with Gemini API: $e");
      return "An error occurred while generating the next question. Please try again.";
    }
  }

  Future<String> generateSummary() async {
    try {
      final prompt = "Summarize the patient's symptoms and concerns for a doctor's review.";

      // Copy chat history and add the summary request
      final List<Content> contents = [...chatHistory];
      contents.add(
        Content(
          parts: [Part.text(prompt)],
          role: "user",
        ),
      );

      final response = await gemini.chat(contents);

      if (response != null && response.output != null) {
        return response.output!;
      } else {
        throw Exception("Invalid response from Gemini API.");
      }
    } catch (e) {
      print("Error generating summary: $e");
      return "Unable to generate summary. Please try again.";
    }
  }

  void resetChat() {
    chatHistory.removeRange(1, chatHistory.length);
    lastFallbackQuestion = null;
    questionCount = 0;
    print("Chat history reset.");
  }
}
