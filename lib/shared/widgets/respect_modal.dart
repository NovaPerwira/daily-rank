import 'package:flutter/material.dart';
import 'dart:ui'; // Needed for BackdropFilter

class RespectModal extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onContinue;

  const RespectModal({
    super.key,
    this.title = "RESPECT+",
    this.message =
        "Achievement Unlocked! You resisted impulse spending and boosted your savings score by 5 points. Way to go!",
    required this.onContinue,
  });

  /// Helper function to show this modal easily from anywhere
  static void show(BuildContext context, {VoidCallback? onContinue}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return RespectModal(onContinue: onContinue ?? () {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      // Glassmorphism blur effect
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Placeholder for the 3D Money Bag character
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glowing aura behind the icon
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withValues(alpha: 0.4),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  // The actual icon (Replace with your asset later)
                  const Icon(
                    Icons.monetization_on_rounded,
                    size: 90,
                    color: Colors.greenAccent,
                  ),
                  // Decorative "Level up" arrows
                  Positioned(
                    top: 0,
                    right: -10,
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.greenAccent,
                      size: 24,
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: -10,
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.greenAccent,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title: RESPECT+
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.greenAccent,
                  letterSpacing: 2,
                  shadows: [Shadow(color: Colors.greenAccent, blurRadius: 15)],
                ),
              ),
              const SizedBox(height: 16),

              // Message Text
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white70,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade400,
                    foregroundColor: Colors.black, // Text color
                    elevation: 10,
                    shadowColor: Colors.greenAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    onContinue();
                  },
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Close Button
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white54,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: const Text("Close", style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
