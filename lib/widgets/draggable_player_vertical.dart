import 'dart:async';
import 'package:flutter/material.dart';

class DraggablePlayerVertical extends StatefulWidget {
  final String imagePathBase;
  final int frameCount;
  final double width;
  final double height;
  final Function(double) onPositionChanged;

  const DraggablePlayerVertical({
    super.key,
    required this.imagePathBase,
    required this.onPositionChanged,
    this.frameCount = 3,
    this.width = 80,
    this.height = 100,
  });

  @override
  State<DraggablePlayerVertical> createState() => _DraggablePlayerVerticalState();
}

class _DraggablePlayerVerticalState extends State<DraggablePlayerVertical> {
  double _yPosition = 0.0;
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
        final maxHeight = constraints.maxHeight;
        final playerHalfHeight = widget.height / 2;
        final minY = -maxHeight / 2 + playerHalfHeight;
        final maxY = maxHeight / 2 - playerHalfHeight;

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _yPosition += details.delta.dy;
              _yPosition = _yPosition.clamp(minY, maxY);
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