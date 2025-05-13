import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDoctorFormScreen extends StatefulWidget {
  const AdminDoctorFormScreen({super.key});

  @override
  State<AdminDoctorFormScreen> createState() => _AdminDoctorFormScreenState();
}

class _AdminDoctorFormScreenState extends State<AdminDoctorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _specialityController = TextEditingController();
  final _clinicAddressController = TextEditingController();

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('doctors').add({
          'name': _nameController.text.trim(),
          'speciality': _specialityController.text.trim(),
          'clinicAddress': _clinicAddressController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Docteur enregistré')),
        );

        Navigator.pushReplacementNamed(context, '/doctorpanel');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Formulaire Docteur")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom du docteur'),
                validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _specialityController,
                decoration: const InputDecoration(labelText: 'Spécialité'),
                validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _clinicAddressController,
                decoration: const InputDecoration(labelText: 'Adresse du cabinet'),
                validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Valider'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
