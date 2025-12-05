import 'package:flutter/material.dart';

class InfiniteScrollMap extends StatelessWidget {
  final String imagePath;
  final Axis scrollDirection;
  final Widget child;
  final double scrollOffset; // NUEVO: Recibimos cuánto se ha movido el mapa
  final bool reverse;

  const InfiniteScrollMap({
    super.key,
    required this.imagePath,
    required this.child,
    required this.scrollOffset, // Obligatorio
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Dimension de la pantalla (alto o ancho)
        final double screenDimension = scrollDirection == Axis.vertical
            ? constraints.maxHeight
            : constraints.maxWidth;

        // Calculamos el desplazamiento relativo al tamaño de la pantalla
        // Usamos el módulo (%) para crear el efecto de bucle infinito
        double relativeOffset = scrollOffset % screenDimension;
        
        // Si queremos ir en reversa (para que el suelo baje o vaya a la izquierda)
        if (reverse) {
          relativeOffset = screenDimension - relativeOffset;
        }

        // Posición de la primera imagen
        double offsetA = relativeOffset;
        if (offsetA > 0) offsetA -= screenDimension;

        // Posición de la segunda imagen (la que viene detrás)
        double offsetB = offsetA + screenDimension;

        return Stack(
          fit: StackFit.expand,
          children: [
            _buildMapImage(offsetA, constraints),
            _buildMapImage(offsetB, constraints),
            child, // Los obstáculos y el jugador van encima
          ],
        );
      },
    );
  }

  Widget _buildMapImage(double offset, BoxConstraints constraints) {
    final bool isVertical = scrollDirection == Axis.vertical;
    BoxFit fit;
    
    // Ajuste para que la imagen cubra bien
    if (isVertical) {
      fit = BoxFit.cover; 
    } else {
      fit = BoxFit.cover;
    }

    return Positioned(
      top: isVertical ? offset : 0,
      left: isVertical ? 0 : offset,
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      child: Image.asset(
        imagePath,
        fit: fit,
        gaplessPlayback: true, // Evita parpadeos
      ),
    );
  }
}