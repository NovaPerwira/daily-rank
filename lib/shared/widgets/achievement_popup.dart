import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_rank/core/constants/app_colors.dart';

class AchievementPopup extends StatelessWidget {
  final String title;
  final String description;
  final int xpReward;
  final VoidCallback? onDismiss;

  const AchievementPopup({
    super.key,
    required this.title,
    required this.description,
    required this.xpReward,
    this.onDismiss,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String description,
    required int xpReward,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Achievement',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, a1, a2) => Center(
        child: AchievementPopup(
          title: title,
          description: description,
          xpReward: xpReward,
          onDismiss: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldGlow,
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🏆',
                style: const TextStyle(fontSize: 56),
              ).animate().scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.0, 1.0),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(height: 8),
              const Text(
                'ACHIEVEMENT UNLOCKED',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.xpGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.xpGreen.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: AppColors.xpGreen, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '+$xpReward XP',
                      style: const TextStyle(
                        color: AppColors.xpGreen,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tap anywhere to dismiss',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        )
            .animate()
            .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOutCubic)
            .fadeIn(duration: 300.ms),
      ),
    );
  }
}

class RankUpCelebration extends StatelessWidget {
  final String newRank;
  final String emoji;
  final Color rankColor;
  final VoidCallback? onDismiss;

  const RankUpCelebration({
    super.key,
    required this.newRank,
    required this.emoji,
    required this.rankColor,
    this.onDismiss,
  });

  static void show(
    BuildContext context, {
    required String newRank,
    required String emoji,
    required Color rankColor,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Rank Up',
      barrierColor: const Color(0xB3000000),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (ctx, a1, a2) => Center(
        child: RankUpCelebration(
          newRank: newRank,
          emoji: emoji,
          rankColor: rankColor,
          onDismiss: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: onDismiss,
        child: SizedBox.expand(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Particles
              ...List.generate(12, (i) {
                return Positioned(
                  top: 100.0 + (i * 40) % 500,
                  left: (i * 60.0) % MediaQuery.of(context).size.width,
                  child: Text(
                    ['⭐', '✨', '💫', '🌟'][i % 4],
                    style: const TextStyle(fontSize: 20),
                  )
                      .animate(delay: Duration(milliseconds: i * 100))
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 1, end: -0.5, duration: 2000.ms),
                );
              }),
              // Main card
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: rankColor, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: rankColor.withOpacity(0.4),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'RANK UP!',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      emoji,
                      style: const TextStyle(fontSize: 80),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.1, 1.1),
                          duration: 800.ms,
                        ),
                    const SizedBox(height: 16),
                    Text(
                      newRank.toUpperCase(),
                      style: TextStyle(
                        color: rankColor,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: rankColor.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .scale(
                          begin: const Offset(0, 0),
                          end: const Offset(1, 1),
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(height: 8),
                    Text(
                      'You have reached $newRank rank!',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tap to continue',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).scale(
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.0, 1.0),
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
