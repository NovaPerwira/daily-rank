import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ══════════════════════════════════════════════════════════════════════════════
// Financial Rank Config — Mobile Legends-style gamification
// Total journey: Rp0 → Mythic (Rp100,000,000+)
// Each rank has 5 stars. Stars earned by net worth milestones.
// ══════════════════════════════════════════════════════════════════════════════

enum FinancialRankTier {
  warrior,
  elite,
  master,
  grandmaster,
  epic,
  legend,
  mythic,
}

class FinancialSubRank {
  final String id;           // e.g. "warrior_3"
  final String displayName;  // e.g. "Warrior III"
  final String tierName;     // e.g. "Warrior"
  final String tierLabel;    // e.g. "III"
  final FinancialRankTier tier;
  final double startIdr;     // net worth required to enter this sub-rank
  final double endIdr;       // net worth to leave this sub-rank (start of next)
  final Color primaryColor;
  final Color glowColor;
  final Color starColor;
  final String iconAsset;    // emoji or icon key

  const FinancialSubRank({
    required this.id,
    required this.displayName,
    required this.tierName,
    required this.tierLabel,
    required this.tier,
    required this.startIdr,
    required this.endIdr,
    required this.primaryColor,
    required this.glowColor,
    required this.starColor,
    required this.iconAsset,
  });

  /// Total IDR span of this sub-rank
  double get spanIdr => endIdr - startIdr;

  /// IDR per star (span / 5)
  double get idrPerStar => spanIdr / 5;

  bool get isMythicTier => tier == FinancialRankTier.mythic;
}

// ── Colors per tier ──────────────────────────────────────────────────────────
const _bronzeColor     = Color(0xFFCD7F32);
const _bronzeGlow      = Color(0x40CD7F32);
const _bronzeStar      = Color(0xFFE8A066);

const _silverColor     = Color(0xFFB0BEC5);
const _silverGlow      = Color(0x40B0BEC5);
const _silverStar      = Color(0xFFCFD8DC);

const _goldColor       = Color(0xFFFFD700);
const _goldGlow        = Color(0x50FFD700);
const _goldStar        = Color(0xFFFFE566);

const _platinumColor   = Color(0xFF78FFEB);
const _platinumGlow    = Color(0x4078FFEB);
const _platinumStar    = Color(0xFFB2FFF5);

const _purpleColor     = Color(0xFFC471ED);
const _purpleGlow      = Color(0x50C471ED);
const _purpleStar      = Color(0xFFDA9EF8);

const _redGoldColor    = Color(0xFFFF6B35);
const _redGoldGlow     = Color(0x50FF6B35);
const _redGoldStar     = Color(0xFFFFAA7A);

const _mythicColor     = Color(0xFFFF2E9B);
const _mythicGlow      = Color(0x60FF2E9B);
const _mythicStar      = Color(0xFFFF80C1);

// ── Master rank table ────────────────────────────────────────────────────────
// Warrior:      Rp0        → Rp5,000,000     (3 sub-ranks)
// Elite:        Rp5M       → Rp20,000,000    (4 sub-ranks)
// Master:       Rp20M      → Rp40,000,000    (4 sub-ranks)
// Grandmaster:  Rp40M      → Rp65,000,000    (5 sub-ranks)
// Epic:         Rp65M      → Rp90,000,000    (5 sub-ranks)
// Legend:       Rp90M      → Rp100,000,000   (5 sub-ranks)
// Mythic:       Rp100M+    → unlimited       (4 sub-ranks)

const List<FinancialSubRank> kFinancialRanks = [
  // ── WARRIOR (Bronze) ────────────────────────────────────────────────────
  // III: 0 - 1M     | per star: 200K
  // II:  1M - 3M    | per star: 400K
  // I:   3M - 5M    | per star: 400K
  FinancialSubRank(
    id: 'warrior_3', displayName: 'Warrior III', tierName: 'Warrior', tierLabel: 'III',
    tier: FinancialRankTier.warrior,
    startIdr: 0, endIdr: 1_000_000,
    primaryColor: _bronzeColor, glowColor: _bronzeGlow, starColor: _bronzeStar,
    iconAsset: '⚔️',
  ),
  FinancialSubRank(
    id: 'warrior_2', displayName: 'Warrior II', tierName: 'Warrior', tierLabel: 'II',
    tier: FinancialRankTier.warrior,
    startIdr: 1_000_000, endIdr: 3_000_000,
    primaryColor: _bronzeColor, glowColor: _bronzeGlow, starColor: _bronzeStar,
    iconAsset: '⚔️',
  ),
  FinancialSubRank(
    id: 'warrior_1', displayName: 'Warrior I', tierName: 'Warrior', tierLabel: 'I',
    tier: FinancialRankTier.warrior,
    startIdr: 3_000_000, endIdr: 5_000_000,
    primaryColor: _bronzeColor, glowColor: _bronzeGlow, starColor: _bronzeStar,
    iconAsset: '⚔️',
  ),

  // ── ELITE (Silver) ───────────────────────────────────────────────────────
  // IV:  5M  - 8M    | per star: 600K
  // III: 8M  - 11M   | per star: 600K
  // II:  11M - 15M   | per star: 800K
  // I:   15M - 20M   | per star: 1M
  FinancialSubRank(
    id: 'elite_4', displayName: 'Elite IV', tierName: 'Elite', tierLabel: 'IV',
    tier: FinancialRankTier.elite,
    startIdr: 5_000_000, endIdr: 8_000_000,
    primaryColor: _silverColor, glowColor: _silverGlow, starColor: _silverStar,
    iconAsset: '🛡️',
  ),
  FinancialSubRank(
    id: 'elite_3', displayName: 'Elite III', tierName: 'Elite', tierLabel: 'III',
    tier: FinancialRankTier.elite,
    startIdr: 8_000_000, endIdr: 11_000_000,
    primaryColor: _silverColor, glowColor: _silverGlow, starColor: _silverStar,
    iconAsset: '🛡️',
  ),
  FinancialSubRank(
    id: 'elite_2', displayName: 'Elite II', tierName: 'Elite', tierLabel: 'II',
    tier: FinancialRankTier.elite,
    startIdr: 11_000_000, endIdr: 15_000_000,
    primaryColor: _silverColor, glowColor: _silverGlow, starColor: _silverStar,
    iconAsset: '🛡️',
  ),
  FinancialSubRank(
    id: 'elite_1', displayName: 'Elite I', tierName: 'Elite', tierLabel: 'I',
    tier: FinancialRankTier.elite,
    startIdr: 15_000_000, endIdr: 20_000_000,
    primaryColor: _silverColor, glowColor: _silverGlow, starColor: _silverStar,
    iconAsset: '🛡️',
  ),

  // ── MASTER (Gold) ────────────────────────────────────────────────────────
  // IV:  20M - 25M   | per star: 1M
  // III: 25M - 30M   | per star: 1M
  // II:  30M - 35M   | per star: 1M
  // I:   35M - 40M   | per star: 1M
  FinancialSubRank(
    id: 'master_4', displayName: 'Master IV', tierName: 'Master', tierLabel: 'IV',
    tier: FinancialRankTier.master,
    startIdr: 20_000_000, endIdr: 25_000_000,
    primaryColor: _goldColor, glowColor: _goldGlow, starColor: _goldStar,
    iconAsset: '🏆',
  ),
  FinancialSubRank(
    id: 'master_3', displayName: 'Master III', tierName: 'Master', tierLabel: 'III',
    tier: FinancialRankTier.master,
    startIdr: 25_000_000, endIdr: 30_000_000,
    primaryColor: _goldColor, glowColor: _goldGlow, starColor: _goldStar,
    iconAsset: '🏆',
  ),
  FinancialSubRank(
    id: 'master_2', displayName: 'Master II', tierName: 'Master', tierLabel: 'II',
    tier: FinancialRankTier.master,
    startIdr: 30_000_000, endIdr: 35_000_000,
    primaryColor: _goldColor, glowColor: _goldGlow, starColor: _goldStar,
    iconAsset: '🏆',
  ),
  FinancialSubRank(
    id: 'master_1', displayName: 'Master I', tierName: 'Master', tierLabel: 'I',
    tier: FinancialRankTier.master,
    startIdr: 35_000_000, endIdr: 40_000_000,
    primaryColor: _goldColor, glowColor: _goldGlow, starColor: _goldStar,
    iconAsset: '🏆',
  ),

  // ── GRANDMASTER (Platinum) ───────────────────────────────────────────────
  // V:   40M - 45M   | per star: 1M
  // IV:  45M - 50M   | per star: 1M
  // III: 50M - 55M   | per star: 1M
  // II:  55M - 60M   | per star: 1M
  // I:   60M - 65M   | per star: 1M
  FinancialSubRank(
    id: 'gm_5', displayName: 'Grandmaster V', tierName: 'Grandmaster', tierLabel: 'V',
    tier: FinancialRankTier.grandmaster,
    startIdr: 40_000_000, endIdr: 45_000_000,
    primaryColor: _platinumColor, glowColor: _platinumGlow, starColor: _platinumStar,
    iconAsset: '💠',
  ),
  FinancialSubRank(
    id: 'gm_4', displayName: 'Grandmaster IV', tierName: 'Grandmaster', tierLabel: 'IV',
    tier: FinancialRankTier.grandmaster,
    startIdr: 45_000_000, endIdr: 50_000_000,
    primaryColor: _platinumColor, glowColor: _platinumGlow, starColor: _platinumStar,
    iconAsset: '💠',
  ),
  FinancialSubRank(
    id: 'gm_3', displayName: 'Grandmaster III', tierName: 'Grandmaster', tierLabel: 'III',
    tier: FinancialRankTier.grandmaster,
    startIdr: 50_000_000, endIdr: 55_000_000,
    primaryColor: _platinumColor, glowColor: _platinumGlow, starColor: _platinumStar,
    iconAsset: '💠',
  ),
  FinancialSubRank(
    id: 'gm_2', displayName: 'Grandmaster II', tierName: 'Grandmaster', tierLabel: 'II',
    tier: FinancialRankTier.grandmaster,
    startIdr: 55_000_000, endIdr: 60_000_000,
    primaryColor: _platinumColor, glowColor: _platinumGlow, starColor: _platinumStar,
    iconAsset: '💠',
  ),
  FinancialSubRank(
    id: 'gm_1', displayName: 'Grandmaster I', tierName: 'Grandmaster', tierLabel: 'I',
    tier: FinancialRankTier.grandmaster,
    startIdr: 60_000_000, endIdr: 65_000_000,
    primaryColor: _platinumColor, glowColor: _platinumGlow, starColor: _platinumStar,
    iconAsset: '💠',
  ),

  // ── EPIC (Purple) ────────────────────────────────────────────────────────
  // V:   65M - 70M   | per star: 1M
  // IV:  70M - 75M   | per star: 1M
  // III: 75M - 80M   | per star: 1M
  // II:  80M - 85M   | per star: 1M
  // I:   85M - 90M   | per star: 1M
  FinancialSubRank(
    id: 'epic_5', displayName: 'Epic V', tierName: 'Epic', tierLabel: 'V',
    tier: FinancialRankTier.epic,
    startIdr: 65_000_000, endIdr: 70_000_000,
    primaryColor: _purpleColor, glowColor: _purpleGlow, starColor: _purpleStar,
    iconAsset: '🔮',
  ),
  FinancialSubRank(
    id: 'epic_4', displayName: 'Epic IV', tierName: 'Epic', tierLabel: 'IV',
    tier: FinancialRankTier.epic,
    startIdr: 70_000_000, endIdr: 75_000_000,
    primaryColor: _purpleColor, glowColor: _purpleGlow, starColor: _purpleStar,
    iconAsset: '🔮',
  ),
  FinancialSubRank(
    id: 'epic_3', displayName: 'Epic III', tierName: 'Epic', tierLabel: 'III',
    tier: FinancialRankTier.epic,
    startIdr: 75_000_000, endIdr: 80_000_000,
    primaryColor: _purpleColor, glowColor: _purpleGlow, starColor: _purpleStar,
    iconAsset: '🔮',
  ),
  FinancialSubRank(
    id: 'epic_2', displayName: 'Epic II', tierName: 'Epic', tierLabel: 'II',
    tier: FinancialRankTier.epic,
    startIdr: 80_000_000, endIdr: 85_000_000,
    primaryColor: _purpleColor, glowColor: _purpleGlow, starColor: _purpleStar,
    iconAsset: '🔮',
  ),
  FinancialSubRank(
    id: 'epic_1', displayName: 'Epic I', tierName: 'Epic', tierLabel: 'I',
    tier: FinancialRankTier.epic,
    startIdr: 85_000_000, endIdr: 90_000_000,
    primaryColor: _purpleColor, glowColor: _purpleGlow, starColor: _purpleStar,
    iconAsset: '🔮',
  ),

  // ── LEGEND (Red-Gold) ────────────────────────────────────────────────────
  // V:   90M - 92M   | per star: 400K
  // IV:  92M - 94M   | per star: 400K
  // III: 94M - 96M   | per star: 400K
  // II:  96M - 98M   | per star: 400K
  // I:   98M - 100M  | per star: 400K
  FinancialSubRank(
    id: 'legend_5', displayName: 'Legend V', tierName: 'Legend', tierLabel: 'V',
    tier: FinancialRankTier.legend,
    startIdr: 90_000_000, endIdr: 92_000_000,
    primaryColor: _redGoldColor, glowColor: _redGoldGlow, starColor: _redGoldStar,
    iconAsset: '🌟',
  ),
  FinancialSubRank(
    id: 'legend_4', displayName: 'Legend IV', tierName: 'Legend', tierLabel: 'IV',
    tier: FinancialRankTier.legend,
    startIdr: 92_000_000, endIdr: 94_000_000,
    primaryColor: _redGoldColor, glowColor: _redGoldGlow, starColor: _redGoldStar,
    iconAsset: '🌟',
  ),
  FinancialSubRank(
    id: 'legend_3', displayName: 'Legend III', tierName: 'Legend', tierLabel: 'III',
    tier: FinancialRankTier.legend,
    startIdr: 94_000_000, endIdr: 96_000_000,
    primaryColor: _redGoldColor, glowColor: _redGoldGlow, starColor: _redGoldStar,
    iconAsset: '🌟',
  ),
  FinancialSubRank(
    id: 'legend_2', displayName: 'Legend II', tierName: 'Legend', tierLabel: 'II',
    tier: FinancialRankTier.legend,
    startIdr: 96_000_000, endIdr: 98_000_000,
    primaryColor: _redGoldColor, glowColor: _redGoldGlow, starColor: _redGoldStar,
    iconAsset: '🌟',
  ),
  FinancialSubRank(
    id: 'legend_1', displayName: 'Legend I', tierName: 'Legend', tierLabel: 'I',
    tier: FinancialRankTier.legend,
    startIdr: 98_000_000, endIdr: 100_000_000,
    primaryColor: _redGoldColor, glowColor: _redGoldGlow, starColor: _redGoldStar,
    iconAsset: '🌟',
  ),

  // ── MYTHIC (Legendary Glowing) ───────────────────────────────────────────
  // Mythic:           100M  - 150M
  // Mythical Honor:   150M  - 250M
  // Mythical Glory:   250M  - 500M
  // Mythical Immortal: 500M+
  FinancialSubRank(
    id: 'mythic', displayName: 'Mythic', tierName: 'Mythic', tierLabel: '',
    tier: FinancialRankTier.mythic,
    startIdr: 100_000_000, endIdr: 150_000_000,
    primaryColor: _mythicColor, glowColor: _mythicGlow, starColor: _mythicStar,
    iconAsset: '👑',
  ),
  FinancialSubRank(
    id: 'mythical_honor', displayName: 'Mythical Honor', tierName: 'Mythic', tierLabel: 'Honor',
    tier: FinancialRankTier.mythic,
    startIdr: 150_000_000, endIdr: 250_000_000,
    primaryColor: _mythicColor, glowColor: _mythicGlow, starColor: _mythicStar,
    iconAsset: '👑',
  ),
  FinancialSubRank(
    id: 'mythical_glory', displayName: 'Mythical Glory', tierName: 'Mythic', tierLabel: 'Glory',
    tier: FinancialRankTier.mythic,
    startIdr: 250_000_000, endIdr: 500_000_000,
    primaryColor: _mythicColor, glowColor: _mythicGlow, starColor: _mythicStar,
    iconAsset: '👑',
  ),
  FinancialSubRank(
    id: 'mythical_immortal', displayName: 'Mythical Immortal', tierName: 'Mythic', tierLabel: 'Immortal',
    tier: FinancialRankTier.mythic,
    startIdr: 500_000_000, endIdr: double.maxFinite,
    primaryColor: _mythicColor, glowColor: _mythicGlow, starColor: _mythicStar,
    iconAsset: '👑',
  ),
];

// ══════════════════════════════════════════════════════════════════════════════
// Rank Progress Result
// ══════════════════════════════════════════════════════════════════════════════

class RankProgress {
  final FinancialSubRank rank;
  final FinancialSubRank? nextRank;
  final int star;           // 1–5 (current filled stars)
  final double currentProgress; // 0.0–1.0 within this sub-rank
  final double starProgress;    // 0.0–1.0 within this star
  final double currentAmount;   // current net worth IDR
  final double currentStarStart; // IDR at start of current star
  final double nextStarTarget;   // IDR to fill current star
  final double nextRankTarget;   // IDR to enter next sub-rank
  final bool isMaxRank;

  const RankProgress({
    required this.rank,
    required this.nextRank,
    required this.star,
    required this.currentProgress,
    required this.starProgress,
    required this.currentAmount,
    required this.currentStarStart,
    required this.nextStarTarget,
    required this.nextRankTarget,
    required this.isMaxRank,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// Calculator
// ══════════════════════════════════════════════════════════════════════════════

class FinancialRankCalculator {
  static const int starsPerRank = 5;
  static final _formatter = NumberFormat('#,###', 'id_ID');

  /// Get the current sub-rank index from net worth (IDR)
  static int _getRankIndex(double netWorthIdr) {
    // Find highest rank where startIdr <= netWorthIdr
    for (int i = kFinancialRanks.length - 1; i >= 0; i--) {
      if (netWorthIdr >= kFinancialRanks[i].startIdr) return i;
    }
    return 0;
  }

  /// Main calculation — input net worth IDR, output full RankProgress
  static RankProgress calculate(double netWorthIdr) {
    final netWorth = netWorthIdr.clamp(0.0, double.maxFinite).toDouble();
    final idx = _getRankIndex(netWorth);
    final rank = kFinancialRanks[idx];

    final isMax = idx == kFinancialRanks.length - 1
        && rank.endIdr == double.maxFinite;

    // Progress within this sub-rank (0.0 → 1.0)
    double currentProgress;
    int star;
    double starProgress;
    double currentStarStart;
    double nextStarTarget;

    if (isMax) {
      // Mythical Immortal — no upper bound
      currentProgress = 0.99;
      star = 5;
      starProgress = 1.0;
      currentStarStart = rank.startIdr;
      nextStarTarget = rank.startIdr;
    } else {
      final span = rank.endIdr - rank.startIdr;
      // Bug fix: cast clamp result explicitly to double
      final within = (netWorth - rank.startIdr).clamp(0.0, span).toDouble();
      currentProgress = (within / span).clamp(0.0, 1.0).toDouble();

      // star index 0–4 (filled stars = star+1 visually)
      final rawStar = (currentProgress * starsPerRank).floor();
      star = rawStar.clamp(0, starsPerRank - 1) + 1; // 1-indexed

      // Progress within this star (for the fill bar of current star)
      final starFraction = (currentProgress * starsPerRank) - rawStar;
      starProgress = starFraction.clamp(0.0, 1.0).toDouble();

      final idrPerStar = span / starsPerRank;
      currentStarStart = rank.startIdr + (rawStar * idrPerStar);
      nextStarTarget = currentStarStart + idrPerStar;
    }

    // Next sub-rank
    final FinancialSubRank? nextRank =
        idx < kFinancialRanks.length - 1 ? kFinancialRanks[idx + 1] : null;

    return RankProgress(
      rank: rank,
      nextRank: nextRank,
      star: star,
      currentProgress: currentProgress,
      starProgress: starProgress,
      currentAmount: netWorth,
      currentStarStart: currentStarStart,
      nextStarTarget: nextStarTarget,
      nextRankTarget: isMax ? netWorth : rank.endIdr,
      isMaxRank: isMax,
    );
  }

  // ── Formatters ─────────────────────────────────────────────────────────────

  static String formatIdr(double amount) {
    if (amount >= 1_000_000_000) {
      return 'Rp${(amount / 1_000_000_000).toStringAsFixed(1)}M';
    }
    if (amount >= 1_000_000) {
      final jt = amount / 1_000_000;
      return jt == jt.truncateToDouble()
          ? 'Rp${jt.toStringAsFixed(0)}Jt'
          : 'Rp${jt.toStringAsFixed(1)}Jt';
    }
    if (amount >= 1_000) {
      return 'Rp${(amount / 1_000).toStringAsFixed(0)}Rb';
    }
    return 'Rp${amount.toStringAsFixed(0)}';
  }

  static String formatIdrFull(double amount) {
    return 'Rp ${_formatter.format(amount.round())}';
  }

  static String remainingToNextStar(RankProgress p) {
    if (p.isMaxRank) return 'MAX RANK';
    final rem = p.nextStarTarget - p.currentAmount;
    return '${formatIdr(rem)} lagi';
  }

  static String remainingToNextRank(RankProgress p) {
    if (p.isMaxRank) return 'MAX RANK';
    final rem = p.nextRankTarget - p.currentAmount;
    return '${formatIdr(rem)} lagi';
  }

  // ── USD Conversion ─────────────────────────────────────────────────────────

  /// Exchange rate: 1 USD = Rp16.000 (aligned with WealthConfig.usdToIdr)
  static const double usdToIdr = 16000.0;

  /// Convert IDR amount to USD
  static double idrToUsd(double idrAmount) => idrAmount / usdToIdr;

  /// Format USD with compact suffix (K/M)
  static String formatUsd(double usdAmount) {
    if (usdAmount >= 1_000_000) {
      return '\$${(usdAmount / 1_000_000).toStringAsFixed(2)}M';
    }
    if (usdAmount >= 1_000) {
      return '\$${(usdAmount / 1_000).toStringAsFixed(1)}K';
    }
    return '\$${usdAmount.toStringAsFixed(0)}';
  }

  /// Format full IDR + USD dual display string
  /// e.g. "Rp 62.500.000" and "≈ \$3,906"
  static String formatUsdFull(double idrAmount) {
    final usd = idrToUsd(idrAmount);
    final usdFormatter = NumberFormat('#,###', 'en_US');
    return '≈ \$${usdFormatter.format(usd.round())}';
  }

  /// Total overall progress across all non-mythic ranks (0.0 → 1.0)
  static double overallProgress(double netWorthIdr) {
    const totalMax = 100_000_000.0;
    return (netWorthIdr / totalMax).clamp(0.0, 1.0).toDouble();
  }

  /// Tier rank number label (for UI display)
  static String tierRankLabel(FinancialRankTier tier) {
    switch (tier) {
      case FinancialRankTier.warrior:     return 'Warrior';
      case FinancialRankTier.elite:       return 'Elite';
      case FinancialRankTier.master:      return 'Master';
      case FinancialRankTier.grandmaster: return 'Grandmaster';
      case FinancialRankTier.epic:        return 'Epic';
      case FinancialRankTier.legend:      return 'Legend';
      case FinancialRankTier.mythic:      return 'Mythic';
    }
  }
}
