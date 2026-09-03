import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_rank/core/constants/app_colors.dart';

class FinancialHpBar extends StatelessWidget {
  final double hpPercentage; // 0.0 to 1.0

  const FinancialHpBar({
    super.key,
    required this.hpPercentage,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color based on HP
    Color hpColor = AppColors.xpGreen; // Default healthy green
    if (hpPercentage < 0.25) {
      hpColor = AppColors.danger; // Dying (Red)
    } else if (hpPercentage < 0.5) {
      hpColor = Colors.orangeAccent; // Warning (Orange)
    }

    final int hpDisplay = (hpPercentage * 100).clamp(0, 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header (Title)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'FINANCE: ',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'GAMIFIED',
                    style: TextStyle(
                      color: AppColors.xpGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: AppColors.xpGreen.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 800.ms),
                ],
              ),
              Icon(Icons.open_in_new_rounded, color: AppColors.textSecondary.withValues(alpha: 0.5), size: 16),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // HP Bar Info Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'HP FINANCIAL HEALTH',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '$hpDisplay%',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // The RPG Bar itself
          Stack(
            children: [
              // Background track
              Container(
                height: 14,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: AppColors.cardBorder, width: 1),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
              
              // Animated Fill
              LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth;
                  final width = maxWidth * hpPercentage.clamp(0.0, 1.0);
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    height: 14,
                    width: width,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          hpColor.withValues(alpha: 0.7),
                          hpColor,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: hpColor.withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
