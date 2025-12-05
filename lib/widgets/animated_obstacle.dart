import 'dart:async';
import 'package:flutter/material.dart';
import '../models/obstacle_model.dart';

class AnimatedObstacle extends StatefulWidget {
  final Obstacle obstacle;

  const AnimatedObstacle({super.key, required this.obstacle});

  @override
  State<AnimatedObstacle> createState() => _AnimatedObstacleState();
}

class _AnimatedObstacleState extends State<AnimatedObstacle> {
  late Timer _timer;
  int _currentFrame = 0;

  @override
  void initState() {
    super.initState();
    if (widget.obstacle.isAnimated) {
      _timer = Timer.periodic(
        Duration(milliseconds: widget.obstacle.animationSpeed),
        (timer) {
          if (mounted) {
            setState(() {
              _currentFrame = (_currentFrame + 1) % widget.obstacle.frameCount;
            });
          }
        },
      );
    }
  }

  @override
  void dispose() {
    if (widget.obstacle.isAnimated) {
      _timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String finalPath = widget.obstacle.imagePath;
    
    if (widget.obstacle.isAnimated) {
      finalPath = '${widget.obstacle.imagePath}_$_currentFrame.png';
    }

    return Image.asset(
      finalPath,
      width: widget.obstacle.width,
      height: widget.obstacle.height,
      fit: BoxFit.contain,
      gaplessPlayback: true,
    );
  }
}