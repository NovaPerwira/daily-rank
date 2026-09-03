import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

class SafeZoneBanner extends StatefulWidget {
  final bool isPayday;

  const SafeZoneBanner({super.key, required this.isPayday});

  @override
  State<SafeZoneBanner> createState() => _SafeZoneBannerState();
}

class _SafeZoneBannerState extends State<SafeZoneBanner> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.isPayday) {
      _confettiController.play();
    }
  }

  @override
  void didUpdateWidget(covariant SafeZoneBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPayday && !oldWidget.isPayday) {
      _confettiController.play();
    } else if (!widget.isPayday && oldWidget.isPayday) {
      _confettiController.stop();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isPayday) return const SizedBox.shrink();

    return Stack(
      alignment: Alignment.center,
      children: [
        // Main Banner Content
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24), // Sleek dark
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.amberAccent.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amberAccent.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              // Glowing Shield Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amberAccent.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amberAccent.withValues(alpha: 0.5),
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: Colors.amberAccent,
                  size: 28,
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true))
               .scaleXY(begin: 1.0, end: 1.1, duration: 800.ms),
              
              const SizedBox(width: 16),
              
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SAFE ZONE ACTIVATED',
                      style: TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.amberAccent,
                            blurRadius: 8,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Invincibility mode active until next month. Happy Payday!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().slideY(begin: -0.5, end: 0, duration: 500.ms, curve: Curves.easeOutBack).fadeIn(),

        // Confetti Emitter
        Positioned(
          top: 0,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.amber, Colors.amberAccent, Colors.yellow, Colors.white],
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.2,
          ),
        ),
      ],
    );
  }
}
