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

  double get _monthlyIncome {
    final now = DateTime.now();
    final idr = transactions
        .where((t) => t.type == 'income' && t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
    return idr / WealthConfig.usdToIdr;
  }

  double get _monthlyExpense {
    final now = DateTime.now();
    final idr = transactions
        .where((t) => t.type == 'expense' && t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (sum, t) => sum + t.amount);
    return idr / WealthConfig.usdToIdr;
  }

  double get _totalSavingUsd {
    final idr = transactions
        .where((t) => t.type == 'saving')
        .fold(0.0, (sum, t) => sum + t.amount);
    return idr / WealthConfig.usdToIdr;
  }

  double get _totalInvestmentUsd {
    final idr = transactions
        .where((t) => t.type == 'investment')
        .fold(0.0, (sum, t) => sum + t.amount);
    return idr / WealthConfig.usdToIdr;
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

  @override
  Widget build(BuildContext context) {
    final incomeStr = WealthConfig.formatAmountCompact(_monthlyIncome, currencyMode);
    final expenseStr = WealthConfig.formatAmountCompact(_monthlyExpense, currencyMode);
    final savingStr = WealthConfig.formatAmountCompact(_totalSavingUsd, currencyMode);
    final investStr = WealthConfig.formatAmountCompact(_totalInvestmentUsd, currencyMode);
    final savingPct = _savingRatePct;

    return Column(
      children: [
        Row(
          children: [
            _MetricTile(
              label: 'Income',
              value: incomeStr,
              sublabel: 'this month',
              icon: Icons.arrow_downward_rounded,
              color: AppColors.xpGreen,
              index: 0,
            ),
            const SizedBox(width: 12),
            _MetricTile(
              label: 'Saving Rate',
              value: '${savingPct.toStringAsFixed(0)}%',
              sublabel: savingStr,
              icon: Icons.savings_outlined,
              color: _savingRateColor(savingPct),
              index: 1,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _MetricTile(
              label: 'Portfolio',
              value: investStr,
              sublabel: 'total invested',
              icon: Icons.show_chart_rounded,
              color: AppColors.wealthBuilder,
              index: 2,
            ),
            const SizedBox(width: 12),
            _MetricTile(
              label: 'Expenses',
              value: expenseStr,
              sublabel: 'this month',
              icon: Icons.arrow_upward_rounded,
              color: AppColors.danger,
              index: 3,
            ),
          ],
        ),
      ],
    );
  }

  Color _savingRateColor(double rate) {
    if (rate >= 30) return AppColors.xpGreen;
    if (rate >= 15) return AppColors.warning;
    return AppColors.danger;
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
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
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const Spacer(),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sublabel,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 80 * index))
          .fadeIn(duration: 500.ms)
          .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
    );
  }
}
