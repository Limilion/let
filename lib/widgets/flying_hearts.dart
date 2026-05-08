import 'dart:math';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class FlyingHeartsOverlay extends StatefulWidget {
  final bool visible;
  const FlyingHeartsOverlay({super.key, required this.visible});

  @override
  State<FlyingHeartsOverlay> createState() => _FlyingHeartsOverlayState();
}

class _FlyingHeartsOverlayState extends State<FlyingHeartsOverlay> with TickerProviderStateMixin {
  final List<HeartPosition> _hearts = [];
  final Random _random = Random();

  @override
  void didUpdateWidget(FlyingHeartsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      _generateHearts();
    }
  }

  void _generateHearts() {
    setState(() {
      _hearts.clear();
      // Generate 5-7 hearts
      for (int i = 0; i < 6; i++) {
        _hearts.add(HeartPosition(
          x: _random.nextDouble() * 200 - 100, // Random X offset
          y: _random.nextDouble() * -150 - 50, // Random Y offset (upwards)
          size: 30 + _random.nextDouble() * 40,
          rotation: _random.nextDouble() * 0.5 - 0.25,
          delay: i * 50,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && _hearts.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: _hearts.map((h) => Positioned(
        child: Center(
          child: Transform.translate(
            offset: Offset(h.x, h.y),
            child: Transform.rotate(
              angle: h.rotation,
              child: FadeOut(
                delay: Duration(milliseconds: 300 + h.delay),
                duration: const Duration(milliseconds: 400),
                child: ZoomIn(
                  delay: Duration(milliseconds: h.delay),
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: h.size,
                    shadows: const [
                      Shadow(color: Colors.black26, blurRadius: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }
}

class HeartPosition {
  final double x;
  final double y;
  final double size;
  final double rotation;
  final int delay;

  HeartPosition({
    required this.x,
    required this.y,
    required this.size,
    required this.rotation,
    required this.delay,
  });
}
