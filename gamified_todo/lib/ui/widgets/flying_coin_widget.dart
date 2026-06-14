import 'dart:math';
import 'package:flutter/material.dart';

class FlyingCoinWidget extends StatefulWidget {
  final Offset start;
  final Offset target;
  final VoidCallback onFinished;

  const FlyingCoinWidget({
    super.key,
    required this.start,
    required this.target,
    required this.onFinished,
  });

  @override
  State<FlyingCoinWidget> createState() => _FlyingCoinWidgetState();
}

class _FlyingCoinWidgetState extends State<FlyingCoinWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Offset _randomExplodeOffset;

  @override
  void initState() {
    super.initState();
    final random = Random();
    double angle = random.nextDouble() * 2 * pi;
    double radius = 40 + random.nextDouble() * 40; // explode outwards by 40-80 px
    _randomExplodeOffset = Offset(cos(angle) * radius, sin(angle) * radius);

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600 + random.nextInt(300)), // 600-900ms duration
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

    _controller.forward().then((_) {
      widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        double t = _animation.value;
        
        Offset currentPosition;
        if (t < 0.25) {
          // Phase 1: Explode outwards (0.0 to 0.25)
          double explodeT = t / 0.25;
          currentPosition = Offset.lerp(widget.start, widget.start + _randomExplodeOffset, explodeT)!;
        } else {
          // Phase 2: Swoop to target (0.25 to 1.0)
          double flyT = (t - 0.25) / 0.75;
          Offset explodeEnd = widget.start + _randomExplodeOffset;
          // Use quadratic Bezier curve to make path curved and more dynamic!
          Offset controlPoint = Offset(
            (explodeEnd.dx + widget.target.dx) / 2, 
            min(explodeEnd.dy, widget.target.dy) - 100
          );
          
          // Bezier interpolation formula: B(t) = (1-t)^2 * P0 + 2*(1-t)*t * P1 + t^2 * P2
          currentPosition = Offset(
            pow(1 - flyT, 2) * explodeEnd.dx + 2 * (1 - flyT) * flyT * controlPoint.dx + pow(flyT, 2) * widget.target.dx,
            pow(1 - flyT, 2) * explodeEnd.dy + 2 * (1 - flyT) * flyT * controlPoint.dy + pow(flyT, 2) * widget.target.dy,
          );
        }

        // Scale popping
        double scale = 1.0;
        if (t < 0.2) {
          scale = t / 0.2 * 1.3; // slightly larger on pop
        } else if (t > 0.8) {
          scale = 1.3 * (1.0 - (t - 0.8) / 0.2); // shrink to 0 as it merges
        } else {
          scale = 1.3 - ((t - 0.2) / 0.6) * 0.3; // shrink from 1.3 to 1.0
        }

        return Positioned(
          left: currentPosition.dx - 12,
          top: currentPosition.dy - 12,
          child: IgnorePointer(
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: t > 0.85 ? (1.0 - t) / 0.15 : 1.0,
                child: const Icon(
                  Icons.monetization_on,
                  color: Colors.amber,
                  size: 24,
                  shadows: [
                    Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(1, 2)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
