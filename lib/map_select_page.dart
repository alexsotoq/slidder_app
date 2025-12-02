import 'package:flutter/material.dart';

class MapSelectPage extends StatelessWidget {
  final String currentMap;

  const MapSelectPage({
    super.key,
    required this.currentMap,
  });

  @override
  Widget build(BuildContext context) {
    // Reutilizamos el fondo azul semitransparente para consistencia
    return Scaffold(
      backgroundColor: Colors.blueAccent,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Título de la página
              const Text(
                "SELECCIONAR MAPA",
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 24,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),

              // Lista de opciones de mapas
              // Usamos un estilo similar de botones pero simplificado para la selección
              _MapOption(
                mapId: 'forest',
                label: 'BOSQUE VERDE',
                color: const Color(0xFF81C784),
                isSelected: currentMap == 'forest',
                onTap: () => Navigator.pop(context, 'forest'),
              ),

              const SizedBox(height: 20),

              _MapOption(
                mapId: 'city',
                label: 'CIUDAD AZULONA',
                color: const Color(0xFF90CAF9),
                isSelected: currentMap == 'city',
                onTap: () => Navigator.pop(context, 'city'),
              ),

              const SizedBox(height: 20),

              _MapOption(
                mapId: 'volcano',
                label: 'MONTE CENIZA',
                color: const Color(0xFFE57373),
                isSelected: currentMap == 'volcano',
                onTap: () => Navigator.pop(context, 'volcano'),
              ),

              const SizedBox(height: 50),

              // Botón de volver
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "< VOLVER",
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget auxiliar privado para las opciones de mapa
class _MapOption extends StatelessWidget {
  final String mapId;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _MapOption({
    required this.mapId,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.black45,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white30,
            width: 4,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 14,
                color: isSelected ? Colors.black87 : Colors.white70,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white),
          ],
        ),
      ),
    );
  }
}