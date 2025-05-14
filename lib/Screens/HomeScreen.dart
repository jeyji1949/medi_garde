import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:medi_garde/Screens/pharmacy_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  Position? _currentPosition;
  List<Map<String, dynamic>> _pharmacies = [];
  List<Map<String, dynamic>> _filteredPharmacies = [];
  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _filteredDoctors = [];
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    _initializeLocationAndData();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeLocationAndData() async {
    try {
      // Demander les permissions de localisation et obtenir la position
      await _getCurrentLocation();
      
      // Une fois que nous avons la position, charger les données
      if (_currentPosition != null) {
        await Future.wait([
          _loadPharmacies(),
          _loadDoctors(),
        ]);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des données: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _getCurrentLocation() async {
    final status = await Permission.location.request();
    
    if (status.isGranted) {
      try {
        setState(() => _isLoading = true);
        
        // Vérifier si le service de localisation est activé
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() {
            _errorMessage = 'Les services de localisation sont désactivés.';
            _isLoading = false;
          });
          return;
        }
        
        // Obtenir la position actuelle
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        setState(() {
          _currentPosition = position;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Erreur de localisation: $e';
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Permission de localisation refusée';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadPharmacies() async {
    try {
      // Récupérer les pharmacies depuis Firestore
      final pharmaciesSnapshot = await FirebaseFirestore.instance
          .collection('pharmacies')
          .where('onDuty', isEqualTo: true) // Utiliser le bon nom de champ
          .get();
      
      List<Map<String, dynamic>> pharmacies = [];
      
      for (var doc in pharmaciesSnapshot.docs) {
        final data = doc.data();
        // Calculer la distance si nous avons les coordonnées
        if (_currentPosition != null && data.containsKey('latitude') && data.containsKey('longitude')) {
          double distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            data['latitude'],
            data['longitude'],
          );
          
          // Convertir en km et arrondir
          double distanceInKm = distance / 1000;
          distanceInKm = double.parse(distanceInKm.toStringAsFixed(1));
          
          pharmacies.add({
            'id': doc.id,
            ...data,
            'distance': distanceInKm,
          });
        } else {
          pharmacies.add({
            'id': doc.id,
            ...data,
            'distance': null,
          });
        }
      }
      
      // Trier par distance si disponible
      pharmacies.sort((a, b) {
        if (a['distance'] == null && b['distance'] == null) return 0;
        if (a['distance'] == null) return 1;
        if (b['distance'] == null) return -1;
        return a['distance'].compareTo(b['distance']);
      });
      
      setState(() {
        _pharmacies = pharmacies;
        _filteredPharmacies = pharmacies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des pharmacies: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadDoctors() async {
    try {
      print("Chargement des médecins...");
      final doctorsSnapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .where('isAvailable', isEqualTo: true) // Filtrer les médecins disponibles
          .get();
    
      List<Map<String, dynamic>> doctors = [];
    
      for (var doc in doctorsSnapshot.docs) {
        final data = doc.data();
        // Vérifiez si nous avons les coordonnées nécessaires
        if (_currentPosition != null && data.containsKey('latitude') && data.containsKey('longitude')) {
          double distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            data['latitude'],
            data['longitude'],
          );
          
          // Convertir en km et arrondir
          double distanceInKm = distance / 1000;
          distanceInKm = double.parse(distanceInKm.toStringAsFixed(1));
          
          doctors.add({
            'id': doc.id,
            ...data,
            'distance': distanceInKm,
          });
        } else {
          doctors.add({
            'id': doc.id,
            ...data,
            'distance': null,
          });
        }
      }
    
      // Trier les médecins par distance
      doctors.sort((a, b) {
        if (a['distance'] == null && b['distance'] == null) return 0;
        if (a['distance'] == null) return 1;
        if (b['distance'] == null) return -1;
        return a['distance'].compareTo(b['distance']);
      });
    
      setState(() {
        _doctors = doctors;
        _filteredDoctors = doctors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des médecins: $e';
        _isLoading = false;
      });
      print('Erreur lors du chargement des médecins: $e');
    }
  }

  void _onSearchQueryChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        // Réinitialiser aux valeurs complètes si la recherche est vide
        _filteredPharmacies = List.from(_pharmacies);
        _filteredDoctors = List.from(_doctors);
      } else {
        final lowercaseQuery = query.toLowerCase();
        
        _filteredPharmacies = _pharmacies.where((pharmacy) {
          final name = pharmacy['name']?.toLowerCase() ?? '';
          final address = pharmacy['location']?.toLowerCase() ?? ''; // Corriger le nom du champ
          return name.contains(lowercaseQuery) || address.contains(lowercaseQuery);
        }).toList();

        _filteredDoctors = _doctors.where((doctor) {
          final name = doctor['name']?.toLowerCase() ?? '';
          final specialty = doctor['specialty']?.toLowerCase() ?? '';
          return name.contains(lowercaseQuery) || specialty.contains(lowercaseQuery);
        }).toList();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Icon(Icons.menu, color: Colors.black),
                  Text('mediGarde',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50))),
                  Icon(Icons.notifications_outlined, color: Colors.black),
                ],
              ),
              const SizedBox(height: 16),
              
              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Recherche une pharmacie ou un médecin',
                          border: InputBorder.none,
                        ),
                        onChanged: _onSearchQueryChanged,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Messages d'erreur ou de chargement
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                  ),
                )
              else if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _initializeLocationAndData,
                    color: Color(0xFF4CAF50),
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Pharmacies
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0, bottom: 12.0),
                            child: Text(
                              'Pharmacies de garde à proximité',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // Liste des pharmacies
                          _filteredPharmacies.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20.0),
                                  child: Center(
                                    child: Text(
                                      'Aucune pharmacie de garde trouvée à proximité',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: _filteredPharmacies.length,
                                  itemBuilder: (context, index) {
                                    final pharmacy = _filteredPharmacies[index];
                                    return _buildPharmacyCard(pharmacy);
                                  },
                                ),
                          
                          const SizedBox(height: 24),
                          
                          // Section Médecins
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0, bottom: 12.0),
                            child: Text(
                              'Médecins disponibles à proximité',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // Liste des médecins
                          _filteredDoctors.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20.0),
                                  child: Center(
                                    child: Text(
                                      'Aucun médecin disponible trouvé à proximité',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: _filteredDoctors.length,
                                  itemBuilder: (context, index) {
                                    final doctor = _filteredDoctors[index];
                                    return _buildDoctorCard(doctor);
                                  },
                                ),
                              
                          // Ajouter un peu d'espace au bas de la liste
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        currentIndex: 0, // L'index de l'accueil
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart), label: 'Panier'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
        onTap: (index) {
          // Gérer la navigation vers les autres écrans ici
          if (index != 0) {
            // Notifier que cette fonctionnalité est en cours de développement
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cette fonctionnalité sera bientôt disponible'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }
  
  Widget _buildPharmacyCard(Map<String, dynamic> pharmacy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
       onTap: () {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (context) => PharmacyDetailScreen(pharmacy: pharmacy),
  ));
},

        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Image de la pharmacie
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  image: pharmacy['imageUrl'] != null && pharmacy['imageUrl'].toString().isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(pharmacy['imageUrl']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: pharmacy['imageUrl'] == null || pharmacy['imageUrl'].toString().isEmpty
                    ? const Icon(Icons.local_pharmacy, color: Colors.grey, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              // Informations sur la pharmacie
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pharmacy['name'] ?? 'Pharmacie',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pharmacy['location'] ?? 'Adresse non disponible', // Corriger le nom du champ
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          pharmacy['is24Hours'] == true 
                              ? 'Ouvert 24h/24'
                              : '${pharmacy['openingHours'] ?? ''} - ${pharmacy['closingHours'] ?? ''}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Distance et bouton d'action
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (pharmacy['distance'] != null)
                    Text(
                      '${pharmacy['distance']} km',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Voir',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Naviguer vers la page détaillée du médecin
          // Navigator.of(context).push(MaterialPageRoute(
          //   builder: (context) => DoctorDetailScreen(doctorId: doctor['id']),
          // ));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Image du médecin
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                  image: doctor['imageUrl'] != null && doctor['imageUrl'].toString().isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(doctor['imageUrl']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: doctor['imageUrl'] == null || doctor['imageUrl'].toString().isEmpty
                    ? const Icon(Icons.person, color: Colors.grey, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              // Informations sur le médecin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dr. ${doctor['name'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor['specialty'] ?? 'Spécialité non disponible',
                      style: TextStyle(fontSize: 14, color: Color(0xFF4CAF50)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor['rating']?.toStringAsFixed(1) ?? '0.0'} (${doctor['reviewCount'] ?? '0'})',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Distance et bouton d'action
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (doctor['distance'] != null)
                    Text(
                      '${doctor['distance']} km',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'RDV',
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}