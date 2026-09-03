import 'package:flutter/material.dart';

class ZombieModeWrapper extends StatelessWidget {
  final bool isZombie;
  final Widget child;

  const ZombieModeWrapper({
    super.key,
    required this.isZombie,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!isZombie) return child;

    // A color matrix that converts everything to grayscale and adds a slight red tint
    const ColorFilter greyscaleRedTint = ColorFilter.matrix([
      0.33, 0.59, 0.11, 0, 40, // Red channel (slightly boosted for tint)
      0.33, 0.59, 0.11, 0, 0,  // Green channel
      0.33, 0.59, 0.11, 0, 0,  // Blue channel
      0,    0,    0,    1, 0,  // Alpha channel
    ]);

    return Stack(
      children: [
        ColorFiltered(
          colorFilter: greyscaleRedTint,
          child: child,
        ),
        // Add a subtle vignette/border effect for "danger" feel
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3),
                  width: 4,
                ),
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                  radius: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
