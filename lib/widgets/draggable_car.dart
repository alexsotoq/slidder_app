import 'package:flutter/material.dart';

class DraggableCar extends StatefulWidget {

  final String imagePath;
  final double width;
  final double height;

  const DraggableCar({
    super.key,
    required this.imagePath,
    this.width = 100,
    this.height = 60,
  });

  @override
  State<DraggableCar> createState() => _DraggableCarState();
}

class _DraggableCarState extends State<DraggableCar> {
  double _xPosition = 0.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final carHalfWidth = widget.width / 2;
        final minX = -maxWidth / 2 + carHalfWidth;
        final maxX = maxWidth / 2 - carHalfWidth;

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _xPosition += details.delta.dx;              
              _xPosition = _xPosition.clamp(minX, maxX);
            });
          },
          child: Container(
            width: maxWidth,
            height: widget.height + 20,
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(_xPosition, 0),
              child: Image.asset(
                widget.imagePath,
                width: widget.width,
                height: widget.height,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}

class DraggableCarHorizontal extends StatefulWidget {
  final String imagePath;
  final double width;
  final double height;

  const DraggableCarHorizontal({
    super.key,
    required this.imagePath,
    this.width = 60,
    this.height = 100,
  });

  @override
  State<DraggableCarHorizontal> createState() => _DraggableCarHorizontalState();
}

class _DraggableCarHorizontalState extends State<DraggableCarHorizontal> {
  double _yPosition = 0.0;
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final carHalfHeight = widget.height / 2;        
        final minY = -maxHeight / 2 + carHalfHeight;
        final maxY = maxHeight / 2 - carHalfHeight;

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {              
              _yPosition += details.delta.dy;             
              _yPosition = _yPosition.clamp(minY, maxY);
            });
          },
          child: Container(
            width: widget.width + 20,
            height: maxHeight,
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(0, _yPosition),
              child: Image.asset(
                widget.imagePath,
                width: widget.width,
                height: widget.height,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}
