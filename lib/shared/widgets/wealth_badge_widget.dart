import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_rank/core/constants/wealth_config.dart';

enum WealthBadgeSize { small, medium, large }

class WealthBadgeWidget extends StatelessWidget {
  final int financialXp;
  final WealthBadgeSize size;
  final bool animated;
  final bool showLabel;

  const WealthBadgeWidget({
    super.key,
    required this.financialXp,
    this.size = WealthBadgeSize.medium,
    this.animated = false,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final rank = WealthConfig.getRankFromXp(financialXp);

    final double badgeSize = switch (size) {
      WealthBadgeSize.small => 52,
      WealthBadgeSize.medium => 80,
      WealthBadgeSize.large => 110,
    };
    final double emojiSize = switch (size) {
      WealthBadgeSize.small => 20,
      WealthBadgeSize.medium => 32,
      WealthBadgeSize.large => 46,
    };
    final double labelSize = switch (size) {
      WealthBadgeSize.small => 9,
      WealthBadgeSize.medium => 12,
      WealthBadgeSize.large => 15,
    };

    Widget badge = _HexBadge(
      size: badgeSize,
      color: rank.color,
      glowColor: rank.glowColor,
      child: Text(rank.emoji, style: TextStyle(fontSize: emojiSize)),
    );

    if (animated) {
      badge = badge
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            duration: 2500.ms,
            color: rank.color.withOpacity(0.4),
          )
          .then()
          .shimmer(duration: 1000.ms, delay: 1500.ms);
    }

    if (!showLabel) return badge;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        badge,
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color: rank.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: rank.color.withOpacity(0.5)),
          ),
          child: Text(
            rank.name.toUpperCase(),
            style: TextStyle(
              color: rank.color,
              fontSize: labelSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          rank.subtitle,
          style: TextStyle(
            color: rank.color.withOpacity(0.65),
            fontSize: labelSize - 1,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _HexBadge extends StatelessWidget {
  final double size;
  final Color color;
  final Color glowColor;
  final Widget child;

  const _HexBadge({
    required this.size,
    required this.color,
    required this.glowColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.2,
          colors: [
            color.withOpacity(0.35),
            color.withOpacity(0.08),
          ],
        ),
        border: Border.all(color: color, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: glowColor,
            blurRadius: 24,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}
