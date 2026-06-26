// This file is a compatibility alias.
// The actual rank calculation logic lives in:
// lib/core/constants/financial_rank_config.dart
//
// Use FinancialRankCalculator.calculate(netWorthIdr) instead.

export 'package:life_rank/core/constants/financial_rank_config.dart'
    show FinancialRankCalculator, RankProgress, FinancialSubRank, FinancialRankTier;
