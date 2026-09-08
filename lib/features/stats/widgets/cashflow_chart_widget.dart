import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/models/category_models.dart';
import 'package:intl/intl.dart';

class CashflowChartWidget extends StatelessWidget {
  final List<TransactionModel> transactions;

  const CashflowChartWidget({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // calculate data for the last 6 months
    final now = DateTime.now();
    final List<Map<String, dynamic>> monthlyData = [];

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final monthTxs = transactions.where((t) => t.date.month == monthDate.month && t.date.year == monthDate.year);
      
      double income = 0;
      double expense = 0;
      double investment = 0;

      for (var tx in monthTxs) {
        if (tx.type == 'income') {
          income += tx.amount;
        } else if (tx.type == 'expense') {
          expense += tx.amount;
        } else if (tx.type == 'investment' || tx.type == 'saving') {
          investment += tx.amount;
        }
      }

      double netProfit = income - expense;

      monthlyData.add({
        'month': monthDate,
        'income': income,
        'netProfit': netProfit,
        'investment': investment,
      });
    }

    // Determine max value for Y-axis interval dynamically, fallback to 10
    double maxVal = 10;
    for (var data in monthlyData) {
      if (data['income'] / 1000000 > maxVal) maxVal = data['income'] / 1000000;
      if (data['netProfit'] / 1000000 > maxVal) maxVal = data['netProfit'] / 1000000;
    }
    double yInterval = maxVal / 5;
    if (yInterval < 1) yInterval = 1;

    List<LineChartBarData> lineBarsData = [
      LineChartBarData(
        spots: monthlyData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['income'] / 1000000)).toList(), // in Millions
        isCurved: true,
        color: AppColors.xpGreen,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: AppColors.xpGreen.withValues(alpha: 0.1)),
      ),
      LineChartBarData(
        spots: monthlyData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['netProfit'] / 1000000)).toList(),
        isCurved: true,
        color: AppColors.primary,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
      ),
      LineChartBarData(
        spots: monthlyData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value['investment'] / 1000000)).toList(),
        isCurved: true,
        color: AppColors.warning,
        barWidth: 3,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: false),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LegendItem(color: AppColors.xpGreen, label: 'Income'),
              _LegendItem(color: AppColors.primary, label: 'Laba Bersih'),
              _LegendItem(color: AppColors.warning, label: 'Investasi'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          'Rp ${spot.y.toStringAsFixed(1)}Jt',
                          TextStyle(color: spot.bar.color ?? Colors.white, fontWeight: FontWeight.bold),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: AppColors.cardBorder, strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                          final date = monthlyData[value.toInt()]['month'] as DateTime;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 8.0,
                            child: Text(
                              DateFormat('MMM').format(date),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '${value.toInt()}Jt',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                          ),
                        );
                      },
                      reservedSize: 32,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: lineBarsData,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
