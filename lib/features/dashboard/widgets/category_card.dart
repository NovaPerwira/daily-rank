import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/constants/rank_config.dart';

/// Supporting attribute card (Career, Knowledge, Habit, Health)
/// RPG character sheet stat card with animated glow border on press.
class SupportAttributeCard extends StatefulWidget {
  final String title;
  final String rpgLabel; // e.g., "Income Engine"
  final String emoji;
  final Color color;
  final int xp;
  final String route;
  final int index;

  const SupportAttributeCard({
    super.key,
    required this.title,
    required this.rpgLabel,
    required this.emoji,
    required this.color,
    required this.xp,
    required this.route,
    required this.index,
  });

  @override
  State<SupportAttributeCard> createState() => _SupportAttributeCardState();
}

class _SupportAttributeCardState extends State<SupportAttributeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rankInfo = RankConfig.getRankInfo(widget.xp);
    final progress = RankConfig.getProgressToNextRank(widget.xp);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        context.push(widget.route);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: _glowCtrl,
        builder: (_, child) {
          final glowOpacity = _isPressed
              ? 0.6
              : 0.04 + _glowCtrl.value * 0.06;
          final borderOpacity = _isPressed
              ? 0.8
              : 0.2 + _glowCtrl.value * 0.15;
          final scale = _isPressed ? 0.96 : 1.0;

          return AnimatedScale(
            scale: scale,
            duration: const Duration(milliseconds: 120),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.color.withValues(alpha: borderOpacity), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: glowOpacity),
                    blurRadius: _isPressed ? 20 : 10 + _glowCtrl.value * 8,
                    spreadRadius: _isPressed ? 2 : 0,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: icon + title + arrow
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: widget.color.withValues(alpha: 0.35)),
                  ),
                  child: Center(
                    child: Text(widget.emoji, style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.rpgLabel,
                        style: TextStyle(
                          color: widget.color,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: widget.color.withValues(alpha: 0.5),
                  size: 16,
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Rank name + XP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${rankInfo.emoji} ${rankInfo.name}',
                  style: TextStyle(
                    color: rankInfo.color,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Animated XP counter
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: widget.xp.toDouble()),
                  duration: Duration(milliseconds: 800 + widget.index * 100),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) => Text(
                    '${value.toInt()} XP',
                    style: TextStyle(
                      color: widget.color.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Mini progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Stack(
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    color: AppColors.cardBorder,
                  ),
                  FractionallySizedBox(
                    widthFactor: progress.clamp(0.02, 1.0),
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(
                          colors: [
                            widget.color.withValues(alpha: 0.8),
                            widget.color,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .slideX(
                        begin: -1,
                        end: 0,
                        duration: Duration(milliseconds: 700 + widget.index * 80),
                        curve: Curves.easeOutCubic,
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 80 * widget.index))
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.25, end: 0, duration: 500.ms, curve: Curves.easeOutCubic);
  }
}

// Keep old CategoryCard as an alias for backward compat if needed
typedef CategoryCard = SupportAttributeCard;
