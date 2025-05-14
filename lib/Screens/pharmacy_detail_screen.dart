import 'package:flutter/material.dart';

class PharmacyDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pharmacy;

  const PharmacyDetailScreen({Key? key, required this.pharmacy}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pharmacy['name'] ?? 'Pharmacie'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image principale
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                image: pharmacy['imageUrl'] != null && pharmacy['imageUrl'].toString().isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(pharmacy['imageUrl']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: pharmacy['imageUrl'] == null || pharmacy['imageUrl'].toString().isEmpty
                  ? const Center(child: Icon(Icons.local_pharmacy, size: 50, color: Colors.white))
                  : null,
            ),
            const SizedBox(height: 16),

            // Infos pharmacie
            Text(
              pharmacy['name'] ?? 'Nom non disponible',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              pharmacy['location'] ?? 'Adresse non disponible',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  pharmacy['is24Hours'] == true
                      ? 'Ouvert 24h/24'
                      : '${pharmacy['openingHours'] ?? ''} - ${pharmacy['closingHours'] ?? ''}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (pharmacy['distance'] != null)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text('${pharmacy['distance']} km de vous'),
                ],
              ),

            const SizedBox(height: 24),

            // Boutons actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(
                  icon: Icons.chat,
                  label: 'Chat',
                  onTap: () {
                    // TODO: Implémenter la logique de chat
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Fonction de chat à venir")),
                    );
                  },
                ),
                _ActionButton(
                  icon: Icons.phone,
                  label: 'Appeler',
                  onTap: () {
                    // TODO: Implémenter appel via url_launcher
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Appel en cours...")),
                    );
                  },
                ),
                _ActionButton(
                  icon: Icons.directions,
                  label: 'Itinéraire',
                  onTap: () {
                    // TODO: Implémenter ouverture de Google Maps
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Ouverture de l'itinéraire...")),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Ink(
          decoration: const ShapeDecoration(
            color: Color(0xFF4CAF50),
            shape: CircleBorder(),
          ),
          child: IconButton(
            icon: Icon(icon),
            color: Colors.white,
            onPressed: onTap,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
