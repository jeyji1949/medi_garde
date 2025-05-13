import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();
  
  // Nouveaux champs
  final _consultationFeesController = TextEditingController();
  bool _isAvailableForHomeVisits = false;
  List<String> _workingDays = [];
  
  // Liste des jours de la semaine
  final List<String> _allDays = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 
    'Vendredi', 'Samedi', 'Dimanche'
  ];

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _specialityController.dispose();
    _clinicAddressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _consultationFeesController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        
        await FirebaseFirestore.instance.collection('doctors').add({
          'name': _nameController.text.trim(),
          'specialty': _specialityController.text.trim(),
          'clinicAddress': _clinicAddressController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': user?.email ?? _emailController.text.trim(),
          'bio': _bioController.text.trim(),
          'consultationFees': double.tryParse(_consultationFeesController.text) ?? 0.0,
          'isAvailableForHomeVisits': _isAvailableForHomeVisits,
          'workingDays': _workingDays,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Docteur enregistré avec succès'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );

        Navigator.pushReplacementNamed(context, '/doctorPanel');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildFormField(
    TextEditingController controller, 
    String label, 
    IconData icon, 
    {bool isMultiline = false, 
    TextInputType keyboardType = TextInputType.text}
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: isMultiline ? 3 : 1,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Ce champ est requis' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Docteur"),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Image.asset('assets/images/logomediGarde.png', height: 80),
                  ),
                  
                  // Titre
                  const Text(
                    'Enregistrement Docteur',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Champs du formulaire
                  _buildFormField(_nameController, 'Nom complet', Icons.person),
                  _buildFormField(_specialityController, 'Spécialité', Icons.medical_services),
                  _buildFormField(_clinicAddressController, 'Adresse du cabinet', Icons.location_on),
                  _buildFormField(_phoneController, 'Numéro de téléphone', Icons.phone, keyboardType: TextInputType.phone),
                  _buildFormField(_emailController, 'Email de contact', Icons.email, keyboardType: TextInputType.emailAddress),
                  _buildFormField(_consultationFeesController, 'Tarif consultation (FCFA)', Icons.payments, keyboardType: TextInputType.number),
                  _buildFormField(_bioController, 'Biographie professionnelle', Icons.description, isMultiline: true),
                  
                  // Visites à domicile
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.home_work, color: Colors.grey),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('Disponible pour visites à domicile')),
                        Switch(
                          value: _isAvailableForHomeVisits,
                          activeColor: const Color(0xFF4CAF50),
                          onChanged: (value) {
                            setState(() {
                              _isAvailableForHomeVisits = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Jours de travail
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey),
                            SizedBox(width: 10),
                            Text('Jours de travail', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _allDays.map((day) {
                            final isSelected = _workingDays.contains(day);
                            return FilterChip(
                              label: Text(day),
                              selected: isSelected,
                              selectedColor: const Color(0xFF4CAF50).withOpacity(0.2),
                              checkmarkColor: const Color(0xFF4CAF50),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _workingDays.add(day);
                                  } else {
                                    _workingDays.remove(day);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  
                  // Bouton d'envoi
                  const SizedBox(height: 24),
                  _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
                    : ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Enregistrer',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}