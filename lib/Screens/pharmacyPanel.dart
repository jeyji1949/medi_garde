import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPharmacyHomeScreen extends StatefulWidget {
  const AdminPharmacyHomeScreen({super.key});

  @override
  State<AdminPharmacyHomeScreen> createState() => _AdminPharmacyHomeScreenState();
}

class _AdminPharmacyHomeScreenState extends State<AdminPharmacyHomeScreen> {
  String? pharmacyDocId;
  bool isOnDuty = false;
  String name = '';

  @override
  void initState() {
    super.initState();
    loadPharmacyData();
  }

  Future<void> loadPharmacyData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final query = await FirebaseFirestore.instance
          .collection('pharmacies')
          .where('email', isEqualTo: user.email) // Suppose que tu enregistres l'email dans Firestore
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        pharmacyDocId = doc.id;
        setState(() {
          name = doc['name'];
          isOnDuty = doc['onDuty'] ?? false;
        });
      }
    }
  }

  Future<void> toggleOnDuty() async {
    if (pharmacyDocId != null) {
      await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyDocId)
          .update({'onDuty': !isOnDuty});
      setState(() {
        isOnDuty = !isOnDuty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Espace Pharmacie')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bienvenue, $name', style: TextStyle(fontSize: 22)),
            SizedBox(height: 20),
            Text('Statut : ${isOnDuty ? "En Garde" : "Pas en Garde"}'),
            Switch(
              value: isOnDuty,
              onChanged: (val) => toggleOnDuty(),
            ),
          ],
        ),
      ),
    );
  }
}
