import 'package:ai_doc/screens/splash_screen.dart';
import 'package:ai_doc/utils/const.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import '../services/init_service.dart';
import 'screens/patient_home.dart';
import 'screens/doctor_home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Gemini.init(apiKey: AppConstants.geminiApiKey);
  await InitService.initialize(); // for Reminders
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasData && snapshot.data != null) {
              return FutureBuilder<String?>(
                future:
                    Provider.of<AuthService>(
                      context,
                      listen: false,
                    ).getUserType(),
                builder: (context, userTypeSnapshot) {
                  if (userTypeSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final userType = userTypeSnapshot.data;
                  if (userType == 'doctor') {
                    return const DoctorHomeScreen();
                  } else {
                    return const PatientHomeScreen();
                  }
                },
              );
            }

            return SplashScreen();
          },
        ),
      ),
    );
  }
}
