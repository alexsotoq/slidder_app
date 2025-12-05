import 'dart:async';
import 'package:flutter/material.dart';

class DraggablePlayerVertical extends StatefulWidget {
  final String imagePathBase;
  final int frameCount;
  final double width;
  final double height;
  final Function(double) onPositionChanged;
  final double minY; 
  final double maxY;

  const DraggablePlayerVertical({
    super.key,
    required this.imagePathBase,
    required this.onPositionChanged,
    this.frameCount = 3,
    this.width = 80,
    this.height = 100,
    required this.minY,
    required this.maxY,
  });

  @override
  // CAMBIO 1: El tipo de retorno y la creación del estado ya NO tienen el guion bajo "_"
  State<DraggablePlayerVertical> createState() => DraggablePlayerVerticalState();
}

// CAMBIO 2: La clase ahora se llama "DraggablePlayerVerticalState" (sin "_")
// Esto permite acceder a ella desde GamePage usando una GlobalKey.
class DraggablePlayerVerticalState extends State<DraggablePlayerVertical> {
  double _yPosition = 0.0;
  Timer? _animationTimer;
  int _currentFrame = 0;

  @override
  void initState() {
    super.initState();
    _yPosition = (widget.minY + widget.maxY) / 2;
    _startAnimation();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  void _startAnimation() {
    _animationTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (mounted) {
        setState(() {
          _currentFrame = (_currentFrame + 1) % widget.frameCount;
        });
      }
    });
  }

  // CAMBIO 3: Función nueva para mover al jugador desde el teclado
  void movePlayer(double delta) {
    setState(() {
      _yPosition += delta;
      // Respetamos los mismos límites que el arrastre táctil
      _yPosition = _yPosition.clamp(widget.minY, widget.maxY);
    });
    // Avisamos a la página principal que nos movimos
    widget.onPositionChanged(_yPosition);
  }

  @override
  Widget build(BuildContext context) {
    final currentImagePath = '${widget.imagePathBase}_$_currentFrame.png';

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        
        // No es necesario recalcular límites aquí para el clamp, ya los recibimos en el widget,
        // pero sí para el Layout visual si fuera necesario.
        
        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _yPosition += details.delta.dy;
              _yPosition = _yPosition.clamp(widget.minY, widget.maxY);
            });
            widget.onPositionChanged(_yPosition);
          },
          child: Container(
            width: widget.width + 20,
            height: maxHeight,
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(0, _yPosition),
              child: Image.asset(
                currentImagePath,
                width: widget.width,
                height: widget.height,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ),
        );
      },
    );
  }
}