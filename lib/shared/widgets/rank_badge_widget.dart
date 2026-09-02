import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:life_rank/core/constants/rank_config.dart';

enum RankBadgeSize { small, medium, large }

class RankBadgeWidget extends StatefulWidget {
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
  State<RankBadgeWidget> createState() => _RankBadgeWidgetState();
}

class _RankBadgeWidgetState extends State<RankBadgeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
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

    final double badgeSize = switch (widget.size) {
      RankBadgeSize.small => 48,
      RankBadgeSize.medium => 72,
      RankBadgeSize.large => 100,
    };

    final double fontSize = switch (widget.size) {
      RankBadgeSize.small => 18,
      RankBadgeSize.medium => 28,
      RankBadgeSize.large => 40,
    };

    final double labelSize = switch (widget.size) {
      RankBadgeSize.small => 9,
      RankBadgeSize.medium => 12,
      RankBadgeSize.large => 16,
    };

    Widget badge = AnimatedBuilder(
      animation: _glowCtrl,
      builder: (context, child) {
        final glowRadius = widget.animated
            ? 12.0 + _glowCtrl.value * 10.0
            : 12.0;
        return SizedBox(
          width: badgeSize,
          height: badgeSize,
          child: CustomPaint(
            painter: _HexBadgePainter(
              color: rankInfo.color,
              glowColor: rankInfo.glowColor,
              glowRadius: glowRadius,
              glowIntensity: widget.animated ? 0.4 + _glowCtrl.value * 0.3 : 0.4,
            ),
            child: Center(
              child: Text(
                rankInfo.emoji,
                style: TextStyle(fontSize: fontSize),
              ),
            ),
          ),
        );
      },
    );

    if (!widget.showLabel) return badge;

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

// ── Hexagonal Badge Painter ────────────────────────────────────────────────────

class _HexBadgePainter extends CustomPainter {
  final Color color;
  final Color glowColor;
  final double glowRadius;
  final double glowIntensity;

  _HexBadgePainter({
    required this.color,
    required this.glowColor,
    required this.glowRadius,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 4;

    final path = _hexPath(cx, cy, r);

    // Outer glow
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: glowIntensity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);
    canvas.drawPath(path, glowPaint);

    // Background fill (dark)
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);

    // Gradient fill using shader
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.35),
          color.withValues(alpha: 0.08),
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, gradientPaint);

    // Border stroke
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, borderPaint);

    // Inner highlight
    final innerPath = _hexPath(cx, cy, r * 0.85);
    final highlightPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(innerPath, highlightPaint);
  }

  Path _hexPath(double cx, double cy, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 180) * (60 * i - 30);
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _HexBadgePainter old) =>
      old.glowRadius != glowRadius || old.glowIntensity != glowIntensity;
}
