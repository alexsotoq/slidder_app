import 'dart:async';
import 'package:flutter/material.dart';

class InfiniteScrollMap extends StatefulWidget {
  final String imagePath;
  final Axis scrollDirection;
  final Widget child;
  final Duration duration;
  final bool reverse;

  const InfiniteScrollMap({
    super.key,
    required this.imagePath,
    required this.child,
    this.scrollDirection = Axis.vertical,
    this.duration = const Duration(seconds: 20),
    this.reverse = false,
  });

  @override
  State<InfiniteScrollMap> createState() => _InfiniteScrollMapState();
}

class _InfiniteScrollMapState extends State<InfiniteScrollMap>
    with TickerProviderStateMixin {
      
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double animationValue = _controller.value;
            final double screenDimension = widget.scrollDirection == Axis.vertical
                ? constraints.maxHeight
                : constraints.maxWidth;
                
            final double directionMultiplier = widget.reverse ? 1.0 : -1.0;
            final double translateValue = (animationValue * screenDimension) * directionMultiplier;

            double offsetA = translateValue;
            double offsetB = widget.reverse
                ? translateValue - screenDimension
                : translateValue + screenDimension;
            
            offsetA = _normalizeOffset(offsetA, screenDimension);
            offsetB = _normalizeOffset(offsetB, screenDimension);

            return Stack(
              fit: StackFit.expand,
              children: [
                _buildMapImage(offsetA, constraints),
                _buildMapImage(offsetB, constraints),
                widget.child,
              ],
            );
          },
        );
      },
    );
  }

  double _normalizeOffset(double offset, double screenDimension) {
    if (widget.reverse) {
      if (offset >= screenDimension) {
        return offset - (2 * screenDimension);
      }
    } else {
      if (offset <= -screenDimension) {
        return offset + (2 * screenDimension);
      }
    }
    return offset;
  }

  Widget _buildMapImage(double offset, BoxConstraints constraints) {
    final bool isVertical = widget.scrollDirection == Axis.vertical;
    BoxFit fit;
    const ImageRepeat repeat = ImageRepeat.noRepeat; 
    double? width, height;

    if (isVertical) {
      fit = BoxFit.fitWidth; 
      width = constraints.maxWidth;
      height = null;
    } else {
      fit = BoxFit.fitHeight;
      height = constraints.maxHeight;
      width = null;
    }

    return Transform.translate(
      offset: isVertical
          ? Offset(0, offset)
          : Offset(offset, 0),
      child: Image.asset(
        widget.imagePath,
        width: width,
        height: height,
        fit: fit,
        repeat: repeat, 
        gaplessPlayback: true,
      ),
    );
  }
}