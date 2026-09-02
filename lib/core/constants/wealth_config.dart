import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_colors.dart';

enum CurrencyMode { usd, idr }

class WealthRank {
  final String name;
  final String subtitle;
  final double minUSD;
  final double maxUSD; // -1 means unlimited
  final Color color;
  final Color glowColor;
  final String emoji;
  final String badge;

  const WealthRank({
    required this.name,
    required this.subtitle,
    required this.minUSD,
    required this.maxUSD,
    required this.color,
    required this.glowColor,
    required this.emoji,
    required this.badge,
  });
}

class WealthConfig {
  // Exchange rate: 1 USD = 16,000 IDR
  static const double usdToIdr = 16000.0;

  // XP to wealth mapping: 1 financial XP = IDR 100,000 = ~$6.25
  static const double xpToIdr = 100000.0;

  static const List<WealthRank> ranks = [
    WealthRank(
      name: 'Beginner',
      subtitle: 'Just Starting',
      minUSD: 0,
      maxUSD: 1000,
      color: AppColors.wealthBeginner,
      glowColor: AppColors.wealthBeginnerGlow,
      emoji: '🌱',
      badge: 'BG',
    ),
    WealthRank(
      name: 'Starter',
      subtitle: 'Building Foundation',
      minUSD: 1000,
      maxUSD: 10000,
      color: AppColors.wealthStarter,
      glowColor: AppColors.wealthStarterGlow,
      emoji: '⚡',
      badge: 'ST',
    ),
    WealthRank(
      name: 'Builder',
      subtitle: 'Wealth Builder',
      minUSD: 10000,
      maxUSD: 50000,
      color: AppColors.wealthBuilder,
      glowColor: AppColors.wealthBuilderGlow,
      emoji: '🔷',
      badge: 'BL',
    ),
    WealthRank(
      name: 'Elite',
      subtitle: 'Elite Investor',
      minUSD: 50000,
      maxUSD: 250000,
      color: AppColors.wealthElite,
      glowColor: AppColors.wealthEliteGlow,
      emoji: '💎',
      badge: 'EL',
    ),
    WealthRank(
      name: 'Wealth Master',
      subtitle: 'Financial Freedom',
      minUSD: 250000,
      maxUSD: -1,
      color: AppColors.wealthMaster,
      glowColor: AppColors.wealthMasterGlow,
      emoji: '👑',
      badge: 'WM',
    ),
  ];

  // ── Daily financial motivations / todo seeds ─────────────────────────────
  static const List<Map<String, dynamic>> dailyFinancialTodos = [
    {
      'id': 'todo-f1',
      'title': 'Catat pengeluaran hari ini',
      'desc': 'Track setiap rupiah yang keluar',
      'icon': '📝',
      'points': 50,
    },
    {
      'id': 'todo-f2',
      'title': 'Review saldo rekening tabungan',
      'desc': 'Cek apakah sesuai target bulan ini',
      'icon': '🏦',
      'points': 30,
    },
    {
      'id': 'todo-f3',
      'title': 'Pelajari satu konsep investasi',
      'desc': 'Saham, reksa dana, atau crypto 15 menit',
      'icon': '📚',
      'points': 40,
    },
    {
      'id': 'todo-f4',
      'title': 'Hindari pembelian impulsif',
      'desc': 'Tahan diri dari 1 keinginan hari ini',
      'icon': '🛑',
      'points': 60,
    },
    {
      'id': 'todo-f5',
      'title': 'Update net worth tracker',
      'desc': 'Input data keuangan terkini kamu',
      'icon': '💰',
      'points': 100,
    },
    {
      'id': 'todo-f6',
      'title': 'Kurangi satu biaya langganan',
      'desc': 'Cek aplikasi/langganan yang jarang dipakai',
      'icon': '✂️',
      'points': 80,
    },
    {
      'id': 'todo-f7',
      'title': 'Siapkan bekal makan siang',
      'desc': 'Hemat pengeluaran makan hari ini',
      'icon': '🍱',
      'points': 70,
    },
    {
      'id': 'todo-f8',
      'title': 'Baca artikel finansial',
      'desc': 'Tambah ilmu seputar perencanaan keuangan',
      'icon': '📖',
      'points': 40,
    },
    {
      'id': 'todo-f9',
      'title': 'Bayar tagihan lebih awal',
      'desc': 'Hindari denda keterlambatan',
      'icon': '⚡',
      'points': 60,
    },
    {
      'id': 'todo-f10',
      'title': 'Pisahkan uang tabungan di awal',
      'desc': 'Lakukan "pay yourself first"',
      'icon': '💸',
      'points': 90,
    },
    {
      'id': 'todo-f11',
      'title': 'Cek performa portofolio investasi',
      'desc': 'Evaluasi alokasi dan return',
      'icon': '📈',
      'points': 70,
    },
    {
      'id': 'todo-f12',
      'title': 'Rencanakan pengeluaran akhir pekan',
      'desc': 'Buat budget khusus agar tidak bocor',
      'icon': '🏖️',
      'points': 50,
    },
    {
      'id': 'todo-f13',
      'title': 'Sedekah atau donasi hari ini',
      'desc': 'Sisihkan rezeki untuk yang membutuhkan',
      'icon': '🤲',
      'points': 50,
    },
    {
      'id': 'todo-f14',
      'title': 'Lakukan 24-hour rule',
      'desc': 'Tunda beli barang non-esensial selama 24 jam',
      'icon': '⏳',
      'points': 80,
    },
    {
      'id': 'todo-f15',
      'title': 'Evaluasi tujuan keuangan',
      'desc': 'Lihat lagi apakah targetmu masih relevan',
      'icon': '🎯',
      'points': 100,
    },
  ];

  // ── Net Worth direct helpers ─────────────────────────────────────────────

  /// Convert a direct IDR net worth to XP (used when user inputs amount directly)
  static int idrToXp(double idrAmount) {
    return (idrAmount / xpToIdr).round();
  }

  /// Convert a direct USD net worth to XP
  static int usdToXp(double usdAmount) {
    return idrToXp(usdAmount * usdToIdr);
  }

  /// Convert financialXp to USD net worth
  static double xpToUsd(int financialXp) {
    return (financialXp * xpToIdr) / usdToIdr;
  }

  /// Convert financialXp to IDR net worth
  static double xpToIdrAmount(int financialXp) {
    return financialXp * xpToIdr;
  }

  /// Get wealth rank from financialXp
  static WealthRank getRankFromXp(int financialXp) {
    final usd = xpToUsd(financialXp);
    return getRankFromUsd(usd);
  }

  /// Get wealth rank from USD amount
  static WealthRank getRankFromUsd(double usd) {
    for (int i = ranks.length - 1; i >= 0; i--) {
      if (usd >= ranks[i].minUSD) return ranks[i];
    }
    return ranks[0];
  }

  /// Get wealth rank from direct IDR net worth
  static WealthRank getRankFromIdr(double idrAmount) {
    return getRankFromUsd(idrAmount / usdToIdr);
  }

  /// Get next rank (null if at max)
  static WealthRank? getNextRank(int financialXp) {
    final current = getRankFromXp(financialXp);
    final idx = ranks.indexOf(current);
    if (idx < ranks.length - 1) return ranks[idx + 1];
    return null;
  }

  /// Get next rank from USD amount
  static WealthRank? getNextRankFromUsd(double usd) {
    final current = getRankFromUsd(usd);
    final idx = ranks.indexOf(current);
    if (idx < ranks.length - 1) return ranks[idx + 1];
    return null;
  }

  /// Progress (0.0 to 1.0) to the next rank
  static double getProgressToNextRank(int financialXp) {
    final usd = xpToUsd(financialXp);
    return getProgressFromUsd(usd);
  }

  /// Progress from a direct USD amount
  static double getProgressFromUsd(double usd) {
    final current = getRankFromUsd(usd);
    final next = getNextRankFromUsd(usd);
    if (next == null) return 1.0;
    final range = next.minUSD - current.minUSD;
    final progress = usd - current.minUSD;
    return (progress / range).clamp(0.0, 1.0);
  }

  /// Amount needed to reach next rank, in USD
  static double getUsdToNextRank(int financialXp) {
    final usd = xpToUsd(financialXp);
    final next = getNextRank(financialXp);
    if (next == null) return 0;
    return next.minUSD - usd;
  }

  /// Format currency based on mode
  static String formatAmount(double usdAmount, CurrencyMode mode) {
    if (mode == CurrencyMode.usd) {
      return _formatUsd(usdAmount);
    } else {
      return _formatIdr(usdAmount * usdToIdr);
    }
  }

  /// Format compact (for metric tiles)
  static String formatAmountCompact(double usdAmount, CurrencyMode mode) {
    if (mode == CurrencyMode.usd) {
      if (usdAmount >= 1000000) return '\$${(usdAmount / 1000000).toStringAsFixed(1)}M';
      if (usdAmount >= 1000) return '\$${(usdAmount / 1000).toStringAsFixed(1)}K';
      return '\$${usdAmount.toStringAsFixed(0)}';
    } else {
      final idr = usdAmount * usdToIdr;
      if (idr >= 1000000000) return 'Rp ${(idr / 1000000000).toStringAsFixed(1)}M';
      if (idr >= 1000000) return 'Rp ${(idr / 1000000).toStringAsFixed(0)}Jt';
      if (idr >= 1000) return 'Rp ${(idr / 1000).toStringAsFixed(0)}Rb';
      return 'Rp ${idr.toStringAsFixed(0)}';
    }
  }

  static String _formatUsd(double amount) {
    final formatter = NumberFormat('#,###', 'en_US');
    return '\$${formatter.format(amount.round())}';
  }

  static String _formatIdr(double amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp ${formatter.format(amount.round())}';
  }

  /// Format the target amount for next rank
  static String formatNextTarget(int financialXp, CurrencyMode mode) {
    final next = getNextRank(financialXp);
    if (next == null) return 'MAX RANK';
    return formatAmount(next.minUSD, mode);
  }
}
