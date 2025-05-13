import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminPharmacyFormScreen extends StatefulWidget {
  const AdminPharmacyFormScreen({super.key});

  @override
  State<AdminPharmacyFormScreen> createState() => _AdminPharmacyFormScreenState();
}

class _AdminPharmacyFormScreenState extends State<AdminPharmacyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _openingHoursController = TextEditingController();
  final _closingHoursController = TextEditingController();
  final _managerNameController = TextEditingController();
  
  bool _is24Hours = false;
  bool _isOnDuty = false;
  bool _isLoading = false;
  
  // Liste des services offerts
  final Map<String, bool> _services = {
    'Livraison à domicile': false,
    'Préparation de médicaments': false,
    'Conseils nutritionnels': false,
    'Tests rapides': false,
    'Vaccination': false,
  };

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _openingHoursController.dispose();
    _closingHoursController.dispose();
    _managerNameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Récupérer la liste des services activés
        final List<String> activeServices = _services.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();
            
        await FirebaseFirestore.instance.collection('pharmacies').add({
          'name': _nameController.text.trim(),
          'location': _locationController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': FirebaseAuth.instance.currentUser?.email ?? _emailController.text.trim(),
          'managerName': _managerNameController.text.trim(),
          'openingHours': _openingHoursController.text.trim(),
          'closingHours': _closingHoursController.text.trim(),
          'is24Hours': _is24Hours,
          'onDuty': _isOnDuty,
          'services': activeServices,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pharmacie enregistrée avec succès'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );

        Navigator.pushReplacementNamed(context, '/pharmacyPanel');
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
    {TextInputType keyboardType = TextInputType.text}
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextFormField(
        controller: controller,
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
        title: const Text("Profil Pharmacie"),
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
                    'Enregistrement Pharmacie',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Champs du formulaire
                  _buildFormField(_nameController, 'Nom de la pharmacie', Icons.local_pharmacy),
                  _buildFormField(_managerNameController, 'Nom du pharmacien responsable', Icons.person),
                  _buildFormField(_locationController, 'Adresse / Localisation', Icons.location_on),
                  _buildFormField(_phoneController, 'Numéro de téléphone', Icons.phone, keyboardType: TextInputType.phone),
                  _buildFormField(_emailController, 'Email de contact', Icons.email, keyboardType: TextInputType.emailAddress),
                  
                  // Heures d'ouverture et fermeture
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16, right: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextFormField(
                            controller: _openingHoursController,
                            enabled: !_is24Hours,
                            decoration: const InputDecoration(
                              labelText: 'Heure d\'ouverture',
                              prefixIcon: Icon(Icons.access_time, color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            validator: (value) => _is24Hours || value != null && value.isNotEmpty ? null : 'Champ requis',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16, left: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextFormField(
                            controller: _closingHoursController,
                            enabled: !_is24Hours,
                            decoration: const InputDecoration(
                              labelText: 'Heure de fermeture',
                              prefixIcon: Icon(Icons.access_time, color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            validator: (value) => _is24Hours || value != null && value.isNotEmpty ? null : 'Champ requis',
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Option 24/24
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.all_inclusive, color: Colors.grey),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('Ouvert 24h/24')),
                        Switch(
                          value: _is24Hours,
                          activeColor: const Color(0xFF4CAF50),
                          onChanged: (value) {
                            setState(() {
                              _is24Hours = value;
                              if (value) {
                                _openingHoursController.text = "00:00";
                                _closingHoursController.text = "24:00";
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Option de garde
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_hospital, color: Colors.grey),
                        const SizedBox(width: 10),
                        const Expanded(child: Text('Actuellement de garde')),
                        Switch(
                          value: _isOnDuty,
                          activeColor: const Color(0xFF4CAF50),
                          onChanged: (value) {
                            setState(() {
                              _isOnDuty = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Services proposés
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Services proposés',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ..._services.entries.map((entry) {
                          return CheckboxListTile(
                            title: Text(entry.key),
                            value: entry.value,
                            activeColor: const Color(0xFF4CAF50),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (bool? value) {
                              setState(() {
                                _services[entry.key] = value ?? false;
                              });
                            },
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  
                  // Bouton d'envoi
                  const SizedBox(height: 20),
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