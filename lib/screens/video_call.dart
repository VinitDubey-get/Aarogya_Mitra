import 'package:flutter/material.dart';

class BlackScreen extends StatelessWidget {
  const BlackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Black background

      body: Center( // Keeps the screen pure black
        child: Text(
          'Video Call',
          style:  TextStyle(color:Colors.white,fontSize: 20),

        ),
      )

    );
  }
}
