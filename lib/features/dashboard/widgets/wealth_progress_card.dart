import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/constants/wealth_config.dart';
import 'package:life_rank/core/models/category_models.dart';
import 'package:life_rank/shared/widgets/wealth_badge_widget.dart';

class WealthProgressCard extends StatelessWidget {
  final int financialXp;
  final CurrencyMode currencyMode;
  final List<TransactionModel> transactions;
  /// If set, overrides XP-based net worth with a direct IDR value
  final double? manualNetWorthIdr;

  const WealthProgressCard({
    super.key,
    required this.financialXp,
    required this.currencyMode,
    required this.transactions,
    this.manualNetWorthIdr,
  });

  double get _netWorthUsd {
    if (manualNetWorthIdr != null) return manualNetWorthIdr! / WealthConfig.usdToIdr;
    return WealthConfig.xpToUsd(financialXp);
  }

  double get _monthlyIncomeUsd {
    final now = DateTime.now();
    final income = transactions
        .where((t) => t.type == 'income' && t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
    return income / WealthConfig.usdToIdr;
  }

  double get _savingRatePct {
    final now = DateTime.now();
    final income = transactions
        .where((t) => t.type == 'income' && t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
    final saving = transactions
        .where((t) => t.type == 'saving' && t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
    if (income <= 0) return 0;
    return (saving / income * 100).clamp(0, 100);
  }

  double get _investmentUsd {
    final investment = transactions
        .where((t) => t.type == 'investment')
        .fold(0.0, (sum, t) => sum + t.amount);
    return investment / WealthConfig.usdToIdr;
  }

  @override
  Widget build(BuildContext context) {
    final usd = _netWorthUsd;
    final rank = WealthConfig.getRankFromUsd(usd);
    final nextRank = WealthConfig.getNextRankFromUsd(usd);
    final progress = WealthConfig.getProgressFromUsd(usd);
    final netWorthStr = WealthConfig.formatAmount(usd, currencyMode);
    final nextTargetStr = nextRank != null
        ? WealthConfig.formatAmount(nextRank.minUSD, currencyMode)
        : 'MAX RANK';
    final incomeStr = WealthConfig.formatAmountCompact(_monthlyIncomeUsd, currencyMode);
    final investStr = WealthConfig.formatAmountCompact(_investmentUsd, currencyMode);
    final savingPct = _savingRatePct;
    // For badge, convert back to a synthetic XP so badge widget works
    final syntheticXp = manualNetWorthIdr != null
        ? WealthConfig.idrToXp(manualNetWorthIdr!)
        : financialXp;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            rank.color.withOpacity(0.18),
            AppColors.card,
            AppColors.card.withOpacity(0.95),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        border: Border.all(
          color: rank.color.withOpacity(0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: rank.glowColor,
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: label + badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            color: rank.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'FINANCIAL',
                          style: TextStyle(
                            color: rank.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Net worth
                    Text(
                      netWorthStr,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Net Worth',
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.7),
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              WealthBadgeWidget(
                financialXp: syntheticXp,
                size: WealthBadgeSize.large,
                animated: true,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Progress to next rank
          if (nextRank != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NEXT: ${nextRank.name.toUpperCase()}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  nextTargetStr,
                  style: TextStyle(
                    color: rank.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _AnimatedProgressBar(
              progress: progress,
              color: rank.color,
              glowColor: rank.glowColor,
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(progress * 100).toStringAsFixed(1)}% to ${nextRank.name}',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ] else ...[
            Text(
              '👑 WEALTH MASTER — FINANCIAL FREEDOM',
              style: TextStyle(
                color: AppColors.wealthMaster,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  rank.color.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Metrics row: Income / Saving Rate / Investment
          Row(
            children: [
              _MetricChip(
                label: 'INCOME',
                value: incomeStr,
                sublabel: '/month',
                color: AppColors.xpGreen,
                icon: Icons.trending_up_rounded,
              ),
              const _MetricDivider(),
              _MetricChip(
                label: 'SAVING',
                value: '${savingPct.toStringAsFixed(0)}%',
                sublabel: 'of income',
                color: _savingRateColor(savingPct),
                icon: Icons.savings_rounded,
              ),
              const _MetricDivider(),
              _MetricChip(
                label: 'PORTFOLIO',
                value: investStr,
                sublabel: 'invested',
                color: AppColors.wealthBuilder,
                icon: Icons.show_chart_rounded,
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 700.ms)
        .slideY(begin: 0.15, end: 0, duration: 700.ms, curve: Curves.easeOutCubic);
  }

  Color _savingRateColor(double rate) {
    if (rate >= 30) return AppColors.xpGreen;
    if (rate >= 15) return AppColors.warning;
    return AppColors.danger;
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final Color color;
  final Color glowColor;

  const _AnimatedProgressBar({
    required this.progress,
    required this.color,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Stack(
        children: [
          Container(
            height: 10,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardBorder,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.02, 1.0),
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.7), color],
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor,
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          )
              .animate()
              .slideX(begin: -1, end: 0, duration: 1200.ms, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final Color color;
  final IconData icon;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            sublabel,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 9,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary.withOpacity(0.6),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.cardBorder,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
