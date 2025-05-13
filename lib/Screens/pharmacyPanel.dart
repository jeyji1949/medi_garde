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
  String location = '';
  String phone = '';
  String managerName = '';
  String openingHours = '';
  String closingHours = '';
  bool is24Hours = false;
  List<String> services = [];

  bool isLoading = true;
  int totalProducts = 0;
  int lowStockProducts = 0;

  @override
  void initState() {
    super.initState();
    loadPharmacyData();
  }

  Future<void> loadPharmacyData() async {
    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Utilisateur non connecté")),
        );
        return;
      }

      final query = await FirebaseFirestore.instance
          .collection('pharmacies')
          .where('email', isEqualTo: user.email)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        pharmacyDocId = doc.id;

        setState(() {
          name = doc['name'] ?? '';
          location = doc['location'] ?? '';
          phone = doc['phone'] ?? '';
          managerName = doc['managerName'] ?? '';
          openingHours = doc['openingHours'] ?? '';
          closingHours = doc['closingHours'] ?? '';
          is24Hours = doc['is24Hours'] ?? false;
          isOnDuty = doc['onDuty'] ?? false;
          services = List<String>.from(doc['services'] ?? []);
          isLoading = false;
        });

        _loadInventoryStats();
      } else {
        setState(() {
          name = 'Inconnu';
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aucune pharmacie trouvée pour cet utilisateur.")),
        );
      }
    } catch (e) {
      print('Erreur lors du chargement : $e');
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : ${e.toString()}")),
      );
    }
  }

  Future<void> _loadInventoryStats() async {
    try {
      final productsQuery = await FirebaseFirestore.instance
          .collection('products')
          .where('pharmacyId', isEqualTo: pharmacyDocId)
          .get();

      int lowStock = 0;
      for (var doc in productsQuery.docs) {
        if ((doc['quantity'] ?? 0) < (doc['minQuantity'] ?? 5)) {
          lowStock++;
        }
      }

      setState(() {
        totalProducts = productsQuery.docs.length;
        lowStockProducts = lowStock;
      });
    } catch (e) {
      setState(() {
        totalProducts = 0;
        lowStockProducts = 0;
      });
    }
  }

  Future<void> toggleOnDuty() async {
    if (pharmacyDocId != null) {
      setState(() => isOnDuty = !isOnDuty);

      await FirebaseFirestore.instance
          .collection('pharmacies')
          .doc(pharmacyDocId)
          .update({'onDuty': isOnDuty});
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
        title: const Text('Espace Pharmacie'),
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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
                          Icons.local_pharmacy,
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
                              name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (managerName.isNotEmpty)
                              Text(
                                'Géré par: $managerName',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Statut de garde
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isOnDuty ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOnDuty ? Colors.green : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOnDuty ? Icons.local_hospital : Icons.access_time,
                          color: isOnDuty ? Colors.green : Colors.orange,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOnDuty ? 'Pharmacie de garde' : 'Pas en service de garde',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                isOnDuty
                                    ? 'Vous êtes visible comme pharmacie de garde'
                                    : 'Activez pour être visible comme pharmacie de garde',
                                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isOnDuty,
                          activeColor: const Color(0xFF4CAF50),
                          onChanged: (_) => toggleOnDuty(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Statistiques
                  Row(
                    children: [
                      _buildStatCard('Produits en\nStock Bas', lowStockProducts.toString(),
                          Icons.warning_amber, Colors.amber),
                      const SizedBox(width: 16),
                      _buildStatCard('Total\nProduits', totalProducts.toString(),
                          Icons.medication, Colors.blue),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Informations de la pharmacie',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  _buildInfoItem(Icons.location_on, 'Adresse', location),
                  _buildInfoItem(Icons.phone, 'Téléphone', phone),

                  // Heures d'ouverture
                  _buildInfoItem(Icons.access_time, 'Heures d\'ouverture',
                      is24Hours ? 'Ouvert 24h/24' : '$openingHours - $closingHours'),

                  // Services
                  if (services.isNotEmpty)
                    _buildInfoItem(
                      Icons.medical_services,
                      'Services proposés',
                      services.join(', '),
                    ),

                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Gérer l'inventaire
                          },
                          icon: const Icon(Icons.inventory),
                          label: const Text("Gérer l'inventaire"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Modifier le profil
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text("Modifier mon profil"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF4CAF50),
                            side: const BorderSide(color: Color(0xFF4CAF50)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
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
                Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
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
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
          ],
        ),
      ),
    );
  }
}
