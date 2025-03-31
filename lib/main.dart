import 'package:ai_doc/screens/splash_screen.dart';
import 'package:ai_doc/screens/user_reminders.dart';
import 'package:ai_doc/utils/const.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/login.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'Reminder/notification_service.dart';
import 'Reminder/scheduler.dart';
import '../services/init_service.dart';
void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  Gemini.init(apiKey: AppConstants.geminiApiKey);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
      ],
      child: MaterialApp(
        title: 'AI Doc',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: SplashScreen(),
      ),
    );
  }
}