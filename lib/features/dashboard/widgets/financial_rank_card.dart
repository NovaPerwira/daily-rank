import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/constants/financial_rank_config.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Financial Rank Card — ML-style premium gamification UI
// ══════════════════════════════════════════════════════════════════════════════

class FinancialRankCard extends StatefulWidget {
  final double netWorthIdr;
  final VoidCallback? onTapEdit;

  const FinancialRankCard({
    super.key,
    required this.netWorthIdr,
    this.onTapEdit,
  });

  @override
  State<FinancialRankCard> createState() => _FinancialRankCardState();
}

class _FinancialRankCardState extends State<FinancialRankCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late RankProgress _progress;

  @override
  void initState() {
    super.initState();
    _progress = FinancialRankCalculator.calculate(widget.netWorthIdr);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant FinancialRankCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.netWorthIdr != widget.netWorthIdr) {
      // Bug fix: must call setState to trigger UI rebuild
      setState(() {
        _progress = FinancialRankCalculator.calculate(widget.netWorthIdr);
      });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rank = _progress.rank;
    final isMythic = rank.tier == FinancialRankTier.mythic;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: rank.glowColor,
            blurRadius: 32,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ── Background gradient ──────────────────────────────────────
            _buildBackground(rank, isMythic),

            // ── Shimmer overlay (Mythic only) ────────────────────────────
            if (isMythic) _buildMythicShimmer(),

            // ── Content ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(rank),
                  const SizedBox(height: 20),
                  _buildRankBadgeRow(rank, isMythic),
                  const SizedBox(height: 24),
                  _buildStarRow(_progress),
                  const SizedBox(height: 20),
                  _buildNetWorthDisplay(_progress),
                  const SizedBox(height: 20),
                  _buildProgressSection(_progress),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 700.ms)
        .slideY(begin: 0.08, end: 0, duration: 700.ms, curve: Curves.easeOutCubic);
  }

  // ── Background ─────────────────────────────────────────────────────────────

  Widget _buildBackground(FinancialSubRank rank, bool isMythic) {
    if (isMythic) {
      return Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A0030),
                const Color(0xFF0D001A),
                rank.primaryColor.withOpacity(0.25),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      );
    }

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              rank.primaryColor.withOpacity(0.20),
              AppColors.card,
              AppColors.card.withOpacity(0.98),
            ],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
      ),
    );
  }

  // ── Mythic shimmer ──────────────────────────────────────────────────────────

  Widget _buildMythicShimmer() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (_, __) {
          return CustomPaint(
            painter: _ShimmerPainter(_shimmerController.value),
          );
        },
      ),
    );
  }

  // ── Header row ─────────────────────────────────────────────────────────────

  Widget _buildHeader(FinancialSubRank rank) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: rank.primaryColor,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: rank.glowColor, blurRadius: 8, spreadRadius: 1),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'FINANCIAL RANK',
          style: TextStyle(
            color: rank.primaryColor,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 3.0,
          ),
        ),
        const Spacer(),
        if (widget.onTapEdit != null)
          GestureDetector(
            onTap: widget.onTapEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: rank.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: rank.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, color: rank.primaryColor, size: 11),
                  const SizedBox(width: 5),
                  Text(
                    'UPDATE',
                    style: TextStyle(
                      color: rank.primaryColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── Badge + rank name ───────────────────────────────────────────────────────

  Widget _buildRankBadgeRow(FinancialSubRank rank, bool isMythic) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Badge
        _RankBadge(rank: rank, isMythic: isMythic, shimmer: _shimmerController),
        const SizedBox(width: 18),
        // Rank name + tier
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rank.tierName.toUpperCase(),
                style: TextStyle(
                  color: rank.primaryColor.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                rank.displayName,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: rank.glowColor,
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              if (_progress.nextRank != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        color: rank.primaryColor.withOpacity(0.6), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Next: ${_progress.nextRank!.displayName}',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  '✨ Maximum Rank Achieved',
                  style: TextStyle(
                    color: rank.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Star row ────────────────────────────────────────────────────────────────

  Widget _buildStarRow(RankProgress p) {
    // For mythic, show a "points" style indicator instead of stars
    if (p.rank.isMythicTier && p.isMaxRank) {
      return _buildMythicStarRow(p);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            final filled = i < p.star;
            final isCurrent = i == p.star - 1; // last filled star
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _StarWidget(
                filled: filled,
                isCurrent: isCurrent,
                starColor: p.rank.starColor,
                glowColor: p.rank.glowColor,
                progress: isCurrent ? p.starProgress : (filled ? 1.0 : 0.0),
                shimmer: _shimmerController,
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Bintang ${p.star}/5',
          style: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMythicStarRow(RankProgress p) {
    return Row(
      children: [
        ...List.generate(5, (_) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Icon(Icons.star_rounded, color: p.rank.starColor, size: 28),
        )),
        const SizedBox(width: 4),
        Text(
          '∞',
          style: TextStyle(
            color: p.rank.primaryColor,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // ── Net worth display ───────────────────────────────────────────────────────

  Widget _buildNetWorthDisplay(RankProgress p) {
    final usdStr = FinancialRankCalculator.formatUsdFull(p.currentAmount);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Net Worth',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.6),
            fontSize: 11,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        // IDR — primary display
        Text(
          FinancialRankCalculator.formatIdrFull(p.currentAmount),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            shadows: [
              Shadow(color: p.rank.glowColor, blurRadius: 12),
            ],
          ),
        ),
        const SizedBox(height: 2),
        // USD — auto conversion display
        Text(
          usdStr,
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.55),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          FinancialRankCalculator.remainingToNextStar(p),
          style: TextStyle(
            color: p.rank.primaryColor.withValues(alpha: 0.85),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── Progress section ────────────────────────────────────────────────────────

  Widget _buildProgressSection(RankProgress p) {
    if (p.isMaxRank) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: p.rank.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.rank.primaryColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(p.rank.iconAsset, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'Mythical Immortal — No Ceiling',
              style: TextStyle(
                color: p.rank.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    // Progress to next star
    final starStart = FinancialRankCalculator.formatIdr(p.currentStarStart);
    final starEnd   = FinancialRankCalculator.formatIdr(p.nextStarTarget);
    final rankEnd   = FinancialRankCalculator.formatIdr(p.nextRankTarget);
    final pct       = (p.currentProgress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label: current star → next star
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${p.rank.displayName} ⭐${p.star} → ⭐${p.star < 5 ? p.star + 1 : "MAX"}',
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.8),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                color: p.rank.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Star progress bar (fine-grained)
        _ProgressBar(
          progress: p.starProgress,
          color: p.rank.starColor,
          glowColor: p.rank.glowColor,
          height: 8,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(starStart,
                style: TextStyle(
                    color: AppColors.textMuted, fontSize: 10)),
            Text(starEnd,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 10,
                    fontWeight: FontWeight.w600)),
          ],
        ),

        const SizedBox(height: 16),

        // Sub-rank overall bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress to ${p.nextRank?.displayName ?? "MAX"}',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              rankEnd,
              style: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _ProgressBar(
          progress: p.currentProgress,
          color: p.rank.primaryColor,
          glowColor: p.rank.glowColor,
          height: 5,
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Star Widget
// ══════════════════════════════════════════════════════════════════════════════

class _StarWidget extends StatelessWidget {
  final bool filled;
  final bool isCurrent;
  final Color starColor;
  final Color glowColor;
  final double progress; // 0.0–1.0 (fill within this star)
  final AnimationController shimmer;

  const _StarWidget({
    required this.filled,
    required this.isCurrent,
    required this.starColor,
    required this.glowColor,
    required this.progress,
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    if (isCurrent && !filled) {
      // Partially filled — use custom painter
      return SizedBox(
        width: 32, height: 32,
        child: AnimatedBuilder(
          animation: shimmer,
          builder: (_, __) => CustomPaint(
            painter: _PartialStarPainter(
              progress: progress,
              fillColor: starColor,
              emptyColor: AppColors.textMuted.withOpacity(0.3),
              glowColor: glowColor,
            ),
          ),
        ),
      );
    }

    if (filled) {
      return AnimatedBuilder(
        animation: shimmer,
        builder: (_, __) => Icon(
          Icons.star_rounded,
          color: starColor,
          size: 32,
          shadows: [Shadow(color: glowColor, blurRadius: 10)],
        ),
      )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(duration: 2000.ms, color: starColor.withOpacity(0.5))
          .then()
          .custom(
            duration: 0.ms,
            builder: (_, __, child) => child!,
          );
    }

    return Icon(
      Icons.star_outline_rounded,
      color: AppColors.textMuted.withOpacity(0.35),
      size: 32,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Rank Badge Widget
// ══════════════════════════════════════════════════════════════════════════════

class _RankBadge extends StatelessWidget {
  final FinancialSubRank rank;
  final bool isMythic;
  final AnimationController shimmer;

  const _RankBadge({
    required this.rank,
    required this.isMythic,
    required this.shimmer,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmer,
      builder: (_, __) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                rank.primaryColor.withOpacity(isMythic ? 0.6 : 0.35),
                rank.primaryColor.withOpacity(0.08),
              ],
            ),
            border: Border.all(
              color: rank.primaryColor.withOpacity(isMythic ? 0.9 : 0.55),
              width: isMythic ? 2.5 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: rank.glowColor,
                blurRadius: isMythic ? 28 : 18,
                spreadRadius: isMythic ? 4 : 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              rank.iconAsset,
              style: TextStyle(fontSize: isMythic ? 36 : 32),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Progress Bar
// ══════════════════════════════════════════════════════════════════════════════

class _ProgressBar extends StatefulWidget {
  final double progress;
  final Color color;
  final Color glowColor;
  final double height;

  const _ProgressBar({
    required this.progress,
    required this.color,
    required this.glowColor,
    required this.height,
  });

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 900.ms);
    _anim = Tween<double>(begin: 0, end: widget.progress)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(covariant _ProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _anim = Tween<double>(begin: _anim.value, end: widget.progress)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.textMuted.withOpacity(0.15),
          borderRadius: BorderRadius.circular(widget.height),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: _anim.value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.height),
              gradient: LinearGradient(
                colors: [
                  widget.color.withOpacity(0.8),
                  widget.color,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor,
                  blurRadius: widget.height * 2,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Custom Painters
// ══════════════════════════════════════════════════════════════════════════════

class _PartialStarPainter extends CustomPainter {
  final double progress;
  final Color fillColor;
  final Color emptyColor;
  final Color glowColor;

  _PartialStarPainter({
    required this.progress,
    required this.fillColor,
    required this.emptyColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _starPath(size);

    // Draw empty star
    canvas.drawPath(path, Paint()..color = emptyColor);

    // Clip to filled portion
    if (progress > 0) {
      final clipRect = Rect.fromLTWH(0, 0, size.width * progress, size.height);
      canvas.save();
      canvas.clipRect(clipRect);

      // Glow
      canvas.drawPath(
        path,
        Paint()
          ..color = glowColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      // Fill
      canvas.drawPath(path, Paint()..color = fillColor);
      canvas.restore();
    }
  }

  Path _starPath(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = size.width / 2;
    final innerR = outerR * 0.4;
    const points = 5;
    final path = Path();

    for (int i = 0; i < points * 2; i++) {
      final r = i.isEven ? outerR : innerR;
      final angle = (math.pi / points) * i - math.pi / 2;
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
  bool shouldRepaint(covariant _PartialStarPainter old) =>
      old.progress != progress;
}

class _ShimmerPainter extends CustomPainter {
  final double value;

  _ShimmerPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final x = -size.width + (size.width * 2.5) * value;
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.transparent,
        const Color(0xFFFF2E9B).withOpacity(0.06),
        const Color(0xFFFFD700).withOpacity(0.08),
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 0.6, 1.0],
    );
    final rect = Rect.fromLTWH(x, 0, size.width * 0.6, size.height);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter old) => old.value != value;
}

// ══════════════════════════════════════════════════════════════════════════════
// Compact Rank Chip (for header / profile area)
// ══════════════════════════════════════════════════════════════════════════════

class FinancialRankChip extends StatelessWidget {
  final double netWorthIdr;

  const FinancialRankChip({super.key, required this.netWorthIdr});

  @override
  Widget build(BuildContext context) {
    final p = FinancialRankCalculator.calculate(netWorthIdr);
    final rank = p.rank;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: rank.primaryColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: rank.primaryColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: rank.glowColor, blurRadius: 8, spreadRadius: 0),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rank.iconAsset, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            rank.displayName,
            style: TextStyle(
              color: rank.primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 5),
          Row(
            children: List.generate(p.star, (_) => Text(
              '★',
              style: TextStyle(color: rank.starColor, fontSize: 8),
            )),
          ),
        ],
      ),
    );
  }
}
