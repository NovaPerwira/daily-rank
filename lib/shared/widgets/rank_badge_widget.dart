import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_rank/core/constants/rank_config.dart';

enum RankBadgeSize { small, medium, large }

class RankBadgeWidget extends StatelessWidget {
  final int xp;
  final RankBadgeSize size;
  final bool showLabel;
  final bool animated;

  const RankBadgeWidget({
    super.key,
    required this.xp,
    this.size = RankBadgeSize.medium,
    this.showLabel = true,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    final rankInfo = RankConfig.getRankInfo(xp);

    final double badgeSize = switch (size) {
      RankBadgeSize.small => 48,
      RankBadgeSize.medium => 72,
      RankBadgeSize.large => 100,
    };

    final double fontSize = switch (size) {
      RankBadgeSize.small => 18,
      RankBadgeSize.medium => 28,
      RankBadgeSize.large => 40,
    };

    final double labelSize = switch (size) {
      RankBadgeSize.small => 9,
      RankBadgeSize.medium => 12,
      RankBadgeSize.large => 16,
    };

    Widget badge = Container(
      width: badgeSize,
      height: badgeSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            rankInfo.color.withOpacity(0.3),
            rankInfo.color.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: rankInfo.color, width: 2),
        boxShadow: [
          BoxShadow(
            color: rankInfo.glowColor,
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          rankInfo.emoji,
          style: TextStyle(fontSize: fontSize),
        ),
      ),
    );

    if (animated) {
      badge = badge
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 2000.ms, color: rankInfo.color.withOpacity(0.3));
    }

    if (!showLabel) return badge;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(height: 6),
        Text(
          rankInfo.name.toUpperCase(),
          style: TextStyle(
            color: rankInfo.color,
            fontSize: labelSize,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
