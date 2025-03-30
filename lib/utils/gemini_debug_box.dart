import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:ai_doc/services/gemini_service.dart';

class GeminiDebugBox extends StatefulWidget {
  final GeminiService geminiService;

  const GeminiDebugBox({super.key, required this.geminiService});

  @override
  _GeminiDebugBoxState createState() => _GeminiDebugBoxState();
}

class _GeminiDebugBoxState extends State<GeminiDebugBox> {
  String _apiStatus = 'Not Tested';
  String _apiResponse = '';
  bool _isLoading = false;

  Future<void> _testGeminiApi() async {
    setState(() {
      _isLoading = true;
      _apiStatus = 'Testing...';
    });

    try {
      // Test API with a simple prompt
      final response = await Gemini.instance.text(
        "Respond with 'API Test Successful'",
      );

      setState(() {
        _apiStatus = 'API Connection Successful';
        // Convert the response to a string explicitly
        _apiResponse = response?.toString() ?? 'No response';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _apiStatus = 'API Connection Failed';
        _apiResponse = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            _apiStatus.contains('Successful')
                ? Colors.green.shade100
                : _apiStatus.contains('Failed')
                ? Colors.red.shade100
                : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              _apiStatus.contains('Successful')
                  ? Colors.green
                  : _apiStatus.contains('Failed')
                  ? Colors.red
                  : Colors.grey,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gemini API Debug',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _testGeminiApi,
                child: Text(_isLoading ? 'Testing...' : 'Test API'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Status: $_apiStatus'),
          const SizedBox(height: 8),
          Text(
            'Response: $_apiResponse',
            style: TextStyle(
              color: Colors.grey.shade800,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
