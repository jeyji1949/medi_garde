import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class PhoneVerificationScreen extends StatelessWidget {
  final TextEditingController _phoneController = TextEditingController();
  
  PhoneVerificationScreen({super.key});

  Future<void> sendOTP(String phoneNumber, BuildContext context) async {
  try {
    if (kIsWeb) {
      print('Web: Sending OTP for phone number: $phoneNumber');
      // L'API Web de Firebase Auth se charge automatiquement de recaptcha
      await FirebaseAuth.instance.signInWithPhoneNumber(
        phoneNumber,
      ).then((confirmationResult) {
        print('OTP sent successfully! Confirmation result received.');
        Navigator.pushNamed(context, '/otp', arguments: {
          'confirmationResult': confirmationResult,
          'phoneNumber': phoneNumber,
        });
      });
    } else {
      print('Non-web: Sending OTP for phone number: $phoneNumber');
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          print('Auto sign-in completed.');
          // Auto-sign (Android uniquement)
          FirebaseAuth.instance.signInWithCredential(credential)
            .then((_) => Navigator.pushReplacementNamed(context, '/home'));
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Verification failed: ${e.message}');
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erreur : ${e.message}")));
        },
        codeSent: (String verificationId, int? resendToken) {
          print('OTP sent successfully! Verification ID: $verificationId');
          Navigator.pushNamed(context, '/otp', arguments: {
            'verificationId': verificationId,
            'phoneNumber': phoneNumber,
            'resendToken': resendToken,
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Auto retrieval timeout for verification ID: $verificationId');
        },
        timeout: const Duration(seconds: 120),
      );
    }
  } catch (e) {
    print('Error during OTP send: ${e.toString()}');
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : ${e.toString()}")));
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logomediGarde.png', height: 100),
            const SizedBox(height: 10),
            const Text(
              'Votre pharmacie de garde, toujours à portée de main !',
              style: TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Nous enverrons un SMS pour vérifier votre numéro.',
              style: TextStyle(fontSize: 13, color: Colors.black45),
              textAlign: TextAlign.center,
            ),
            Row(
              children: [
                const Text('+212', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Numéro de téléphone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                )
              ],
            ),
            ElevatedButton(
              onPressed: () {
                final phoneNumber = '+212${_phoneController.text.trim()}';
                print('Button pressed. Phone number: $phoneNumber');
                sendOTP(phoneNumber, context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF66aa88),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Envoyer le code'),
            ),
            const SizedBox(height: 20),
            const Text(
              'En vous inscrivant, vous acceptez nos conditions d\'utilisation et notre politique de confidentialité.',
              style: TextStyle(fontSize: 12, color: Colors.black45),
              textAlign: TextAlign.center,
            ),
            // Si c'est Web, il faut avoir ce div dans le HTML
            if (kIsWeb)
              const SizedBox(
                height: 0,
                child: HtmlElementView(viewType: 'recaptcha-container'),
              ),
          ],
        ),
      ),
    );
  }
}
