import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/constants/rank_config.dart';

class AnimatedXpBar extends StatelessWidget {
  final int currentXp;
  final Color color;
  final double height;
  final bool showPercentage;

  const AnimatedXpBar({
    super.key,
    required this.currentXp,
    this.color = AppColors.xpGreen,
    this.height = 10,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final progress = RankConfig.getProgressToNextRank(currentXp);
    final nextRank = RankConfig.getNextRank(currentXp);
    final xpToNext = RankConfig.getXpToNextRank(currentXp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$currentXp XP',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (nextRank != null)
              Text(
                '$xpToNext XP to ${nextRank.name}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              )
            else
              const Text(
                'MAX RANK 👑',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(height),
          child: Stack(
            children: [
              Container(
                height: height,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress.clamp(0.02, 1.0),
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height),
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.8),
                        color,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .slideX(begin: -1, end: 0, duration: 800.ms, curve: Curves.easeOutCubic),
            ],
          ),
        ),
        if (showPercentage)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
