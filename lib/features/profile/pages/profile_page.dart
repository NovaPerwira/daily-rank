import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:life_rank/features/auth/providers/auth_provider.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/constants/financial_rank_config.dart';
import 'package:life_rank/core/models/category_models.dart';
import 'package:life_rank/core/services/user_stats_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isUploadingAvatar = false;
  List<TransactionModel> _transactions = [];
  bool _loadedTx = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTransactions());
  }

  Future<void> _loadTransactions() async {
    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;
    final txs =
        await UserStatsService.getTransactions(auth.supabaseUser!.id);
    if (mounted) {
      setState(() {
        _transactions = txs;
        _loadedTx = true;
      });
    }
  }

  double get _totalSavingsIdr {
    return _transactions
        .where((t) => t.type == 'saving')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<void> _pickAvatar() async {
    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;

    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;

    setState(() => _isUploadingAvatar = true);
    final url = await UserStatsService.uploadAvatar(
        auth.supabaseUser!.id, File(picked.path));
    if (url != null && mounted) {
      // Refresh profile so avatar_url updates in UI
      await auth.refreshProfile();
    }
    if (mounted) setState(() => _isUploadingAvatar = false);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;
    final stats = auth.stats;

    if (profile == null || stats == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.financial)),
      );
    }

    // ── Rank is now based on total savings (same as dashboard) ──────────────
    final netWorthIdr = _loadedTx ? _totalSavingsIdr : 0.0;
    final rankProgress = FinancialRankCalculator.calculate(netWorthIdr);
    final mlRank = rankProgress.rank;

    // XP stats for info display
    final totalXp = stats.totalXp;
    final level = (totalXp / 100).floor() + 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.danger),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    mlRank.primaryColor.withValues(alpha: 0.15),
                    AppColors.background,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: _isUploadingAvatar ? null : _pickAvatar,
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: mlRank.primaryColor, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                  color: mlRank.glowColor,
                                  blurRadius: 16,
                                  spreadRadius: 2),
                            ],
                          ),
                          child: ClipOval(
                            child: profile.avatarUrl != null
                                ? Image.network(
                                    profile.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        _defaultAvatar(profile.username),
                                  )
                                : _defaultAvatar(profile.username),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: mlRank.primaryColor,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: AppColors.background, width: 2),
                            ),
                            child: _isUploadingAvatar
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.camera_alt,
                                    color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 500.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      end: const Offset(1.0, 1.0)),

                  const SizedBox(height: 16),

                  Text(
                    profile.username,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 4),
                  Text(
                    'Level $level',
                    style: TextStyle(
                        color: mlRank.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 16),

                  // Rank badge — uses same FinancialRankCalculator as dashboard
                  _RankBadge(rankProgress: rankProgress, mlRank: mlRank),
                ],
              ),
            ),

            // ── Stats Grid ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                              color: mlRank.primaryColor,
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 10),
                      const Text('STATISTICS',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _StatCard(
                          label: 'Total XP',
                          value: '$totalXp',
                          icon: '⭐',
                          color: AppColors.xpGreen),
                      _StatCard(
                          label: 'Level',
                          value: '$level',
                          icon: '🎮',
                          color: AppColors.primary),
                      _StatCard(
                          label: 'Pendapatan Tetap',
                          value: _formatIdrCompact(_transactions
                              .where((t) =>
                                  t.type == 'income' &&
                                  (t.incomeType == 'fixed' || t.incomeType == null))
                              .fold(0.0, (s, t) => s + t.amount)),
                          icon: '💼',
                          color: AppColors.financial),
                      _StatCard(
                          label: 'Pendapatan Sampingan',
                          value: _formatIdrCompact(_transactions
                              .where((t) =>
                                  t.type == 'income' && t.incomeType == 'side')
                              .fold(0.0, (s, t) => s + t.amount)),
                          icon: '⚡',
                          color: AppColors.gold),
                      _StatCard(
                          label: 'Total Tabungan',
                          value: _formatIdrCompact(_totalSavingsIdr),
                          icon: '🏦',
                          color: AppColors.career),
                      _StatCard(
                          label: 'Habit XP',
                          value: '${stats.habitXp}',
                          icon: '🔥',
                          color: AppColors.habit),
                      _StatCard(
                          label: 'Knowledge XP',
                          value: '${stats.knowledgeXp}',
                          icon: '📚',
                          color: AppColors.knowledge),
                      _StatCard(
                          label: 'Rank Saat Ini',
                          value: mlRank.displayName,
                          icon: mlRank.iconAsset,
                          color: mlRank.primaryColor),
                    ],
                  ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

                  const SizedBox(height: 24),

                  // Email
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            color: AppColors.textMuted),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Email',
                                style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    letterSpacing: 1)),
                            Text(
                              auth.supabaseUser?.email ?? '-',
                              style: const TextStyle(
                                  color: AppColors.textPrimary, fontSize: 15),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _logout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout, size: 18),
                          SizedBox(width: 8),
                          Text('LOGOUT',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, letterSpacing: 2)),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 400.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatIdrCompact(double idr) {
    if (idr >= 1000000000) return 'Rp ${(idr / 1000000000).toStringAsFixed(1)}M';
    if (idr >= 1000000) return 'Rp ${(idr / 1000000).toStringAsFixed(0)}Jt';
    if (idr >= 1000) return 'Rp ${(idr / 1000).toStringAsFixed(0)}Rb';
    return 'Rp ${idr.toStringAsFixed(0)}';
  }

  Widget _defaultAvatar(String name) {
    return Container(
      color: AppColors.card,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 40,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Rank Badge Widget (using FinancialRankCalculator, same as dashboard) ────────

class _RankBadge extends StatelessWidget {
  final RankProgress rankProgress;
  final FinancialSubRank mlRank;

  const _RankBadge({required this.rankProgress, required this.mlRank});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: mlRank.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mlRank.primaryColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
              color: mlRank.glowColor, blurRadius: 16, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          Text(
            mlRank.iconAsset,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 6),
          Text(
            mlRank.displayName,
            style: TextStyle(
              color: mlRank.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              5,
              (i) => Text(
                '★',
                style: TextStyle(
                  color: i < rankProgress.star
                      ? mlRank.starColor
                      : AppColors.textMuted.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${rankProgress.star}/5 ⭐',
            style: TextStyle(
              color: mlRank.primaryColor.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ).animate().scale(
        begin: const Offset(0.85, 0.85),
        end: const Offset(1.0, 1.0),
        duration: 600.ms,
        curve: Curves.easeOutBack);
  }
}

// ── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
