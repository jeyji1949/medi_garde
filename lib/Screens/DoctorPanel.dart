import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({Key? key}) : super(key: key);

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  String doctorName = '';
  String doctorSpecialty = '';
  String clinicAddress = '';
  String phone = '';
  String bio = '';
  double consultationFees = 0.0;
  bool isAvailableForHomeVisits = false;
  List<String> workingDays = [];
  bool isLoading = true;
  bool isAvailable = false;
  String doctorId = '';
  
  // Pour les statistiques
  int totalAppointments = 0;
  int pendingAppointments = 0;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final query = await FirebaseFirestore.instance
          .collection('doctors')
          .where('email', isEqualTo: user.email)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        doctorId = doc.id;
        setState(() {
          doctorName = doc['name'] ?? '';
          doctorSpecialty = doc['specialty'] ?? '';
          clinicAddress = doc['clinicAddress'] ?? '';
          phone = doc['phone'] ?? '';
          bio = doc['bio'] ?? '';
          consultationFees = (doc['consultationFees'] ?? 0).toDouble();
          isAvailableForHomeVisits = doc['isAvailableForHomeVisits'] ?? false;
          isAvailable = doc['isAvailable'] ?? false;
          workingDays = List<String>.from(doc['workingDays'] ?? []);
          isLoading = false;
        });

        // Charger les statistiques des rendez-vous
        await _loadAppointmentStats();
      } else {
        setState(() {
          doctorName = 'Inconnu';
          doctorSpecialty = 'Non défini';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAppointmentStats() async {
    // Cette fonction pourrait être implémentée pour charger 
    // les statistiques de rendez-vous depuis Firestore
    try {
      final appointmentsQuery = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .get();
      
      int pending = 0;
      for (var doc in appointmentsQuery.docs) {
        if (doc['status'] == 'pending') {
          pending++;
        }
      }
      
      setState(() {
        totalAppointments = appointmentsQuery.docs.length;
        pendingAppointments = pending;
      });
    } catch (e) {
      // Ignorer l'erreur si la collection n'existe pas encore
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  Future<void> _toggleAvailability() async {
    if (doctorId.isNotEmpty) {
      setState(() {
        isAvailable = !isAvailable;
      });
      
      await FirebaseFirestore.instance
          .collection('doctors')
          .doc(doctorId)
          .update({'isAvailable': isAvailable});
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/role');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Docteur'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec photo de profil
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dr. $doctorName',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                doctorSpecialty,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Statut de disponibilité
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isAvailable ? Colors.green : Colors.red,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isAvailable ? Icons.check_circle : Icons.cancel,
                            color: isAvailable ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isAvailable ? 'Disponible pour consultations' : 'Non disponible',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Switch(
                            value: isAvailable,
                            activeColor: const Color(0xFF4CAF50),
                            onChanged: (value) {
                              _toggleAvailability();
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Statistiques
                    Row(
                      children: [
                        _buildStatCard(
                          'Rendez-vous\nEn Attente',
                          pendingAppointments.toString(),
                          Icons.calendar_today,
                          Colors.orange,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          'Total\nRendez-vous',
                          totalAppointments.toString(),
                          Icons.calendar_month,
                          Colors.blue,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Informations du profil
                    const Text(
                      'Informations du profil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildInfoItem(Icons.location_on, 'Adresse du cabinet', clinicAddress),
                    _buildInfoItem(Icons.phone, 'Téléphone', phone),
                    _buildInfoItem(
                      Icons.payments, 
                      'Tarif consultation', 
                      '$consultationFees FCFA'
                    ),
                    _buildInfoItem(
                      Icons.home_work,
                      'Visites à domicile',
                      isAvailableForHomeVisits ? 'Disponible' : 'Non disponible',
                      valueColor: isAvailableForHomeVisits ? Colors.green : Colors.red,
                    ),
                    
                    // Jours de travail
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.calendar_today, color: Colors.grey[600]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Jours de travail',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  children: workingDays.map((day) {
                                    return Chip(
                                      label: Text(day),
                                      backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                                      labelStyle: const TextStyle(color: Color(0xFF4CAF50)),
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Biographie
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'À propos de moi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        bio,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Bouton Modifier le profil
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigation vers l'écran de modification de profil
                          // (à implémenter)
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF4CAF50)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.edit),
                        label: const Text('Modifier mon profil'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, {Color? valueColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? Colors.grey[800],
                    fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}