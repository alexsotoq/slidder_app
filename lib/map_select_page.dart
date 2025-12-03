import 'package:flutter/material.dart';

class MapSelectPage extends StatelessWidget {
  final String currentMap;
  
  const MapSelectPage({super.key, required this.currentMap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elige el mapa'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _MapCard(
              mapName: 'Parque',
              imagePath: 'assets/maps/mapa_parque_horizontal.png',
              isSelected: currentMap == 'Parque',
              onTap: () {
                Navigator.pop(context, 'Parque');
              },
            ),

            _MapCard(
              mapName: 'Ciudad',
              imagePath: 'assets/maps/mapa_city_horizontal.png',
              isSelected: currentMap == 'Ciudad',
              onTap: () {
                Navigator.pop(context, 'Ciudad');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final String mapName;
  final String imagePath;
  final bool isSelected;
  final VoidCallback onTap;

  const _MapCard({
    required this.mapName,
    required this.imagePath,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: Colors.blue, width: 4)
              : Border.all(color: Colors.grey.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              imagePath,
              height: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            Text(
              mapName.toUpperCase(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}