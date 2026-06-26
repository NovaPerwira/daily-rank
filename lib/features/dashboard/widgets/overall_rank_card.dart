import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/constants/wealth_config.dart';
import 'package:life_rank/core/constants/financial_rank_config.dart';
import 'package:life_rank/core/models/user_models.dart';

/// Compact user profile header — wealth rank as the PRIMARY identity.
/// Life XP / overall rank completely removed.
class UserProfileHeader extends StatelessWidget {
  final UserStats stats;
  final String username;
  final CurrencyMode currencyMode;
  final VoidCallback onCurrencyToggle;
  /// Net worth in IDR (manual entry, overrides XP-based)
  final double? manualNetWorthIdr;
  final VoidCallback? onEditNetWorth;

  const UserProfileHeader({
    super.key,
    required this.stats,
    required this.username,
    required this.currencyMode,
    required this.onCurrencyToggle,
    this.manualNetWorthIdr,
    this.onEditNetWorth,
  });

  @override
  Widget build(BuildContext context) {
    // Use manual net worth if set, otherwise derive from financialXp
    final netWorthIdr = manualNetWorthIdr ?? WealthConfig.xpToIdrAmount(stats.financialXp);
    final rankProgress = FinancialRankCalculator.calculate(netWorthIdr);
    final mlRank = rankProgress.rank;

    final initials = username.length >= 2
        ? username.substring(0, 2).toUpperCase()
        : username.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: mlRank.primaryColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: mlRank.glowColor,
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar — colored by ML rank
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  mlRank.primaryColor.withValues(alpha: 0.85),
                  mlRank.primaryColor.withValues(alpha: 0.35),
                ],
              ),
              border: Border.all(color: mlRank.primaryColor.withValues(alpha: 0.7), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: mlRank.glowColor,
                  blurRadius: 14,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Name + ML RANK (primary identity)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    // ML Rank badge — THE primary rank
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: mlRank.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: mlRank.primaryColor.withValues(alpha: 0.45)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(mlRank.iconAsset,
                              style: const TextStyle(fontSize: 10)),
                          const SizedBox(width: 4),
                          Text(
                            mlRank.displayName,
                            style: TextStyle(
                              color: mlRank.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // show filled stars
                          ...List.generate(rankProgress.star, (_) =>
                            Text('★', style: TextStyle(color: mlRank.starColor, fontSize: 8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Edit net worth button
          if (onEditNetWorth != null)
            GestureDetector(
              onTap: onEditNetWorth,
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: mlRank.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: mlRank.primaryColor.withValues(alpha: 0.35)),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: mlRank.primaryColor,
                  size: 16,
                ),
              ),
            ),

          // Currency toggle
          GestureDetector(
            onTap: onCurrencyToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CurrencyPill(
                    label: 'USD',
                    active: currencyMode == CurrencyMode.usd,
                    color: mlRank.primaryColor,
                  ),
                  const SizedBox(width: 2),
                  _CurrencyPill(
                    label: 'IDR',
                    active: currencyMode == CurrencyMode.idr,
                    color: mlRank.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: -0.1, end: 0, duration: 600.ms, curve: Curves.easeOutCubic);
  }
}

class _CurrencyPill extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;

  const _CurrencyPill({
    required this.label,
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? color.withOpacity(0.6) : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? color : AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
