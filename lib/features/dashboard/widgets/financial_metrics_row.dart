import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/constants/wealth_config.dart';
import 'package:life_rank/core/models/category_models.dart';

class FinancialMetricsRow extends StatelessWidget {
  final List<TransactionModel> transactions;
  final CurrencyMode currencyMode;

  const FinancialMetricsRow({
    super.key,
    required this.transactions,
    required this.currencyMode,
  });

  double get _monthlyFixedIncomeUsd {
    final now = DateTime.now();
    final idr = transactions
        .where(
          (t) =>
              t.type == 'income' &&
              (t.incomeType == 'fixed' || t.incomeType == null) &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
    return idr / WealthConfig.usdToIdr;
  }

  double get _monthlySideIncomeUsd {
    final now = DateTime.now();
    final idr = transactions
        .where(
          (t) =>
              t.type == 'income' &&
              t.incomeType == 'side' &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
    return idr / WealthConfig.usdToIdr;
  }

  double get _monthlyTotalIncomeUsd {
    final now = DateTime.now();
    final idr = transactions
        .where(
          (t) =>
              t.type == 'income' &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
    return idr / WealthConfig.usdToIdr;
  }

  double get _monthlyExpenseUsd {
    final now = DateTime.now();
    final idr = transactions
        .where(
          (t) =>
              t.type == 'expense' &&
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .fold(0.0, (sum, t) => sum + t.amount);
    return idr / WealthConfig.usdToIdr;
  }

  @override
  Widget build(BuildContext context) {
    final fixedStr = WealthConfig.formatAmountCompact(
      _monthlyFixedIncomeUsd,
      currencyMode,
    );
    final sideStr = WealthConfig.formatAmountCompact(
      _monthlySideIncomeUsd,
      currencyMode,
    );
    final totalStr = WealthConfig.formatAmountCompact(
      _monthlyTotalIncomeUsd,
      currencyMode,
    );
    final expenseStr = WealthConfig.formatAmountCompact(
      _monthlyExpenseUsd,
      currencyMode,
    );

    return Column(
      children: [
        Row(
          children: [
            _MetricTile(
              label: 'Pendapatan Tetap',
              value: fixedStr,
              sublabel: 'gaji bulan ini',
              icon: Icons.work_rounded,
              color: AppColors.xpGreen,
              index: 0,
            ),
            const SizedBox(width: 12),
            _MetricTile(
              label: 'Pendapatan Sampingan',
              value: sideStr,
              sublabel: 'freelance / bisnis',
              icon: Icons.flash_on_rounded,
              color: AppColors.gold,
              index: 1,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _MetricTile(
              label: 'Total Pemasukan',
              value: totalStr,
              sublabel: 'bulan ini',
              icon: Icons.arrow_downward_rounded,
              color: AppColors.financial,
              index: 2,
            ),
            const SizedBox(width: 12),
            _MetricTile(
              label: 'Pengeluaran',
              value: expenseStr,
              sublabel: 'bulan ini',
              icon: Icons.arrow_upward_rounded,
              color: AppColors.danger,
              index: 3,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String sublabel;
  final IconData icon;
  final Color color;
  final int index;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.icon,
    required this.color,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child:
          Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.07),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.20),
                                color.withValues(alpha: 0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(icon, color: color, size: 16),
                        ),
                        const Spacer(),
                        Text(
                          label.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Animated count-up value
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 600 + 100 * index),
                      curve: Curves.easeOutCubic,
                      builder: (_, t, _) {
                        return Text(
                          value,
                          style: TextStyle(
                            color: color,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sublabel,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              )
              .animate(delay: Duration(milliseconds: 80 * index))
              .fadeIn(duration: 500.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                duration: 500.ms,
                curve: Curves.easeOutCubic,
              )
              .then()
              .shimmer(duration: 600.ms, color: color.withValues(alpha: 0.15)),
    );
  }
}
