import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();

  int timer = 60; // Initial timer for OTP resend
  late String verificationId; // Store the verificationId from the previous screen

  // Method to send OTP verification
  void verifyOTP(String verificationId, String smsCode, BuildContext context) async {
    PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : ${e.toString()}")));
    }
  }

  // Method to resend OTP code on the web using reCAPTCHA
  void resendOTP(BuildContext context) async {
    String phoneNumber = "+1234567890"; // Replace with actual phone number

    // Firebase's verification on the web handles reCAPTCHA automatically now
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto sign-in when verification is completed
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur : ${e.message}")));
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          this.verificationId = verificationId;
          timer = 60; // Reset the timer
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Handle timeout if needed
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Retrieve verificationId passed from the previous screen
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    verificationId = args?['verificationId'] ?? '';

    // Timer countdown logic
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (timer == 0) {
        t.cancel();
      } else {
        setState(() => timer--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', height: 100),
              const SizedBox(height: 10),
              const Text(
                'Votre pharmacie de garde, toujours à portée de main !',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              const Text(
                'Veuillez entrer le code à 6 chiffres envoyé à votre téléphone',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black45),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _codeController,
                maxLength: 6,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '------',
                  counterText: '',
                  filled: true,
                  fillColor: Color(0xffeafae9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                ),
                style: const TextStyle(letterSpacing: 10, fontSize: 24),
              ),
              ElevatedButton(
                onPressed: () {
                  String smsCode = _codeController.text.trim();
                  verifyOTP(verificationId, smsCode, context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF66aa88),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Vérifier'),
              ),
              const SizedBox(height: 20),
              timer == 0
                  ? TextButton(
                      onPressed: () {
                        resendOTP(context); // Call resend OTP method
                      },
                      child: const Text('Renvoyer le code'),
                    )
                  : Text('Renvoyer le code dans ${timer}s', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
