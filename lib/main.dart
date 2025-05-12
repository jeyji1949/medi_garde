import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medi_garde/Screens/HomeScreen.dart';
import 'package:medi_garde/Screens/OnBoardingScreen.dart';
import 'package:medi_garde/Screens/PhoneVerification.dart'; // Correct import
import 'package:medi_garde/Screens/OTPverification.dart'; // Ensure this is correctly imported
import 'package:medi_garde/Screens/SplashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyDoQEO0kQQX_FqmDgUred4eM-shMawNXlY",
          authDomain: "medigarde-89baf.firebaseapp.com",
          projectId: "medigarde-89baf",
          storageBucket: "medigarde-89baf.appspot.com",
          messagingSenderId: "327256623418",
          appId: "1:327256623418:web:1ce2066a72550e03266803",
          measurementId: "G-F6NN6MZ7LC",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    runApp(MediGardeApp(error: e.toString()));
    return;
  }

  runApp(const MediGardeApp());
}

class MediGardeApp extends StatelessWidget {
  final String? error;
  const MediGardeApp({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediGarde',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => error == null ? const SplashScreen() : ErrorScreen(error: error!),
        '/onboarding': (context) => const OnboardingScreen(),
        '/phone': (context) =>  PhoneVerificationScreen(),
        '/otp': (context) => const OTPVerificationScreen(),  // Ensure the constructor is valid
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Text('Failed to initialize Firebase: $error', textAlign: TextAlign.center),
      ),
    );
  }
}
