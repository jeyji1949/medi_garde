import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:medi_garde/Screens/DoctorPanel.dart';
import 'package:medi_garde/Screens/HomeScreen.dart';
import 'package:medi_garde/Screens/OnBoardingScreen.dart';
import 'package:medi_garde/Screens/PhoneVerification.dart'; // Correct import
import 'package:medi_garde/Screens/OTPverification.dart'; // Ensure this is correctly imported
import 'package:medi_garde/Screens/SplashScreen.dart';
import 'package:medi_garde/Screens/doctor_screen.dart';
import 'package:medi_garde/Screens/loginScreen.dart';
import 'package:medi_garde/Screens/pharmacie_screen.dart';
import 'package:medi_garde/Screens/pharmacyPanel.dart';
import 'package:medi_garde/Screens/signupScreen.dart';
import 'package:medi_garde/Screens/user_type_selection_screen.dart';

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
      // Pour Android, utiliser les options de android.json
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBbT08IKH4e58dETQ15sFj_GNCVXxoonRM',
          appId: '1:327256623418:android:ffba31468038297f266803',
          messagingSenderId: '327256623418',
          projectId: 'medigarde-89baf',
          storageBucket: 'medigarde-89baf.appspot.com',
        ),
      );
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
        '/': (context) =>
            error == null ? const SplashScreen() : ErrorScreen(error: error!),
        '/onboarding': (context) => const OnboardingScreen(),
        '/signup': (context) => SignUpScreen(),
        '/login': (context) => LoginScreen(), // Ensure the constructor is valid
        '/home': (context) => const HomeScreen(),
        '/role': (context) => const UserTypeSelectionScreen(),
        '/pharmacyForm': (context) => const AdminPharmacyFormScreen(),
        '/doctorForm': (context) => const AdminDoctorFormScreen(),
        '/pharmacyPanel': (context) => const AdminPharmacyHomeScreen(),
        '/doctorPanel': (context) => const DoctorHomeScreen(),
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
        child: Text('Failed to initialize Firebase: $error',
            textAlign: TextAlign.center),
      ),
    );
  }
}
