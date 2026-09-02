import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:life_rank/core/constants/financial_rank_config.dart';

class RankCard extends StatelessWidget {
  final RankProgress progress;

  const RankCard({
    super.key,
    required this.progress,
  });

  String _formatCurrency(double amount) {
    return FinancialRankCalculator.formatIdr(amount);
  }

  @override
  Widget build(BuildContext context) {
    final rank = progress.rank;
    final stars = List.generate(5, (i) => i < progress.star ? '⭐' : '☆').join('');

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: rank.primaryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: rank.glowColor,
                blurRadius: 20,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Rank',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(rank.iconAsset, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            rank.displayName,
                            style: TextStyle(
                              color: rank.primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: rank.glowColor,
                                  blurRadius: 10,
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    stars,
                    style: const TextStyle(fontSize: 18, letterSpacing: 2),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Net Worth:',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp',
                  decimalDigits: 0,
                ).format(progress.currentAmount),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress to next star:',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${rank.displayName} ⭐${progress.star} → ⭐${progress.star < 5 ? progress.star + 1 : "MAX"}',
                    style: TextStyle(
                      color: rank.primaryColor.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: progress.starProgress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Column(
                    children: [
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: constraints.maxWidth * value,
                                decoration: BoxDecoration(
                                  color: rank.starColor,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: rank.glowColor,
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatCurrency(progress.currentStarStart),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatCurrency(progress.nextStarTarget),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                FinancialRankCalculator.remainingToNextStar(progress),
                style: TextStyle(
                  color: rank.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
