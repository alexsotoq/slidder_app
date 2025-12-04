import 'dart:async';
import 'package:flutter/material.dart';

class DraggablePlayerHorizontal extends StatefulWidget {
  final String imagePathBase;
  final int frameCount;
  final double width;
  final double height;
  final Function(double) onPositionChanged;
  final double minX;
  final double maxX;

  const DraggablePlayerHorizontal({
    super.key,
    required this.imagePathBase,
    required this.onPositionChanged, 
    this.frameCount = 3,
    this.width = 80,
    this.height = 100,
    required this.minX,
    required this.maxX,
  });

  @override
  State<DraggablePlayerHorizontal> createState() => _DraggablePlayerHorizontalState();
}

class _DraggablePlayerHorizontalState extends State<DraggablePlayerHorizontal> {
  double _xPosition = 0.0;
  Timer? _animationTimer;
  int _currentFrame = 0;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final currentImagePath = '${widget.imagePathBase}_$_currentFrame.png';

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final playerHalfWidth = widget.width / 2;
        final minX = -maxWidth / 2 + playerHalfWidth;
        final maxX = maxWidth / 2 - playerHalfWidth;

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _xPosition += details.delta.dx;
              _xPosition = _xPosition.clamp(widget.minX, widget.maxX);
            });
            widget.onPositionChanged(_xPosition); 
          },
          child: Container(
            width: maxWidth,
            height: widget.height + 20,
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(_xPosition, 0),
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