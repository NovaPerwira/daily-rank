import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:life_rank/core/constants/app_colors.dart';

/// Bar chart widget showing monthly savings for the last 6 months.
/// Data format: List of {month: DateTime, amount: double}
class SavingsChartWidget extends StatefulWidget {
  final List<Map<String, dynamic>> monthlySavings;
  final Color barColor;
  final bool isCompact;
  final bool showBackground;

  const SavingsChartWidget({
    super.key,
    required this.monthlySavings,
    this.barColor = AppColors.financial,
    this.isCompact = false,
    this.showBackground = true,
  });

  @override
  State<SavingsChartWidget> createState() => _SavingsChartWidgetState();
}

class _SavingsChartWidgetState extends State<SavingsChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _anim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatCompact(double amount) {
    if (amount >= 1000000000)
      return '${(amount / 1000000000).toStringAsFixed(1)}M';
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(0)}Jt';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}Rb';
    return amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.monthlySavings;
    final maxAmount = data.fold<double>(
      0,
      (prev, e) => math.max(prev, (e['amount'] as double)),
    );

    final isCompact = widget.isCompact;
    final paddingVal = isCompact ? 12.0 : 20.0;
    final chartHeight = isCompact ? 75.0 : 140.0;
    final titleFontSize = isCompact ? 9.5 : 13.0;
    final iconSize = isCompact ? 13.0 : 18.0;
    final iconBoxSize = isCompact ? 24.0 : 32.0;

    return Container(
          padding: EdgeInsets.all(widget.showBackground ? paddingVal : 0.0),
          decoration: widget.showBackground
              ? BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.barColor.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.barColor.withValues(alpha: 0.06),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                  ],
                )
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: widget.barColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(isCompact ? 6 : 10),
                    ),
                    child: Icon(
                      Icons.bar_chart_rounded,
                      color: widget.barColor,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: isCompact ? 6 : 10),
                  Text(
                    isCompact ? 'TABUNGAN' : 'GRAFIK TABUNGAN',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: isCompact ? 0.8 : 1.5,
                    ),
                  ),
                  const Spacer(),
                  if (isCompact)
                    Icon(
                      Icons.zoom_out_map_rounded,
                      color: widget.barColor.withValues(alpha: 0.7),
                      size: 12,
                    )
                  else
                    Text(
                      '6 Bulan Terakhir',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),

              SizedBox(height: isCompact ? 10 : 20),

              // Total saving label
              if (maxAmount > 0) ...[
                Text(
                  isCompact
                      ? 'Rp ${_formatCompact(data.fold<double>(0, (s, e) => s + (e['amount'] as double)))}'
                      : 'Total: Rp ${_formatCompact(data.fold<double>(0, (s, e) => s + (e['amount'] as double)))}',
                  style: TextStyle(
                    color: widget.barColor,
                    fontSize: isCompact ? 11 : 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: isCompact ? 6 : 12),
              ],

              // Chart area
              SizedBox(
                height: chartHeight,
                child: AnimatedBuilder(
                  animation: _anim,
                  builder: (_, _) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(data.length, (i) {
                        final entry = data[i];
                        final amount = entry['amount'] as double;
                        final month = entry['month'] as DateTime;
                        final isCurrentMonth = i == data.length - 1;

                        final fraction = maxAmount > 0
                            ? (amount / maxAmount)
                            : 0.0;
                        final animFraction = fraction * _anim.value;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Amount label (only if > 0 and not compact)
                                if (amount > 0 && !isCompact)
                                  Text(
                                    _formatCompact(amount),
                                    style: TextStyle(
                                      color: isCurrentMonth
                                          ? widget.barColor
                                          : AppColors.textMuted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                const SizedBox(height: 2),
                                // Bar
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 50),
                                  height: math.max(
                                    3,
                                    animFraction * (isCompact ? 45 : 100),
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: amount > 0
                                        ? LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: [
                                              widget.barColor.withValues(
                                                alpha: isCurrentMonth
                                                    ? 1.0
                                                    : 0.45,
                                              ),
                                              widget.barColor.withValues(
                                                alpha: isCurrentMonth
                                                    ? 0.7
                                                    : 0.25,
                                              ),
                                            ],
                                          )
                                        : null,
                                    color: amount == 0
                                        ? AppColors.cardBorder.withValues(
                                            alpha: 0.4,
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: isCurrentMonth && amount > 0
                                        ? [
                                            BoxShadow(
                                              color: widget.barColor.withValues(
                                                alpha: 0.4,
                                              ),
                                              blurRadius: 8,
                                              spreadRadius: 0,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Month label
                                Text(
                                  () {
                                    const shortMonths = [
                                      'Jan',
                                      'Feb',
                                      'Mar',
                                      'Apr',
                                      'Mei',
                                      'Jun',
                                      'Jul',
                                      'Agt',
                                      'Sep',
                                      'Okt',
                                      'Nov',
                                      'Des',
                                    ];
                                    return shortMonths[month.month - 1];
                                  }(),
                                  style: TextStyle(
                                    color: isCurrentMonth
                                        ? widget.barColor
                                        : AppColors.textMuted,
                                    fontSize: isCompact ? 8.0 : 10.0,
                                    fontWeight: isCurrentMonth
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),

              // Empty state
              if (maxAmount == 0) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Belum ada data tabungan',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms, delay: 300.ms)
        .slideY(
          begin: 0.15,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
