import 'package:flutter/material.dart';

class UserTypeSelectionScreen extends StatelessWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logomediGarde.png', height: 120),
              const SizedBox(height: 40),
              const Text(
                'Vous êtes...',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4CAF50)),
              ),
              const SizedBox(height: 40),
              _buildUserTypeButton(
                context,
                label: 'Utilisateur',
                icon: Icons.person,
                route: '/login',
              ),
              const SizedBox(height: 20),
              _buildUserTypeButton(
                context,
                label: 'Pharmacie',
                icon: Icons.local_pharmacy,
                route: '/pharmacyForm',
              ),
              const SizedBox(height: 20),
              _buildUserTypeButton(
                context,
                label: 'Docteur',
                icon: Icons.medical_services,
                route: '/doctorForm',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeButton(BuildContext context, {required String label, required IconData icon, required String route}) {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pushNamed(context, route);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4CAF50),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minimumSize: const Size.fromHeight(50),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18)),
    );
  }
}
