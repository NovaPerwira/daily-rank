import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:life_rank/features/auth/providers/auth_provider.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/constants/financial_rank_config.dart';
import 'package:life_rank/core/models/category_models.dart';
import 'package:life_rank/core/services/user_stats_service.dart';
import 'package:life_rank/core/services/backup_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isUploadingAvatar = false;
  List<TransactionModel> _transactions = [];
  bool _loadedTx = false;
  bool _isExporting = false;
  bool _isImporting = false;

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

  Future<void> _exportData() async {
    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;

    // Tampilkan pilihan format backup
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Format Backup',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Backup mencakup nominal, kategori, tanggal, serta catatan keperluan/sumber dana.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                leading: const Text('📊', style: TextStyle(fontSize: 24)),
                title: const Text('Format CSV (Excel / Spreadsheet)',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: const Text('Tabel rapi untuk dibuka di Excel atau Google Sheets',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () => Navigator.pop(ctx, 'csv'),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
                leading: const Text('📦', style: TextStyle(fontSize: 24)),
                title: const Text('Format JSON (Backup Lengkap)',
                    style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: const Text('Struktur utuh dengan metadata & ringkasan otomatis',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () => Navigator.pop(ctx, 'json'),
              ),
            ],
          ),
        ),
      ),
    );

    if (choice == null) return;

    setState(() => _isExporting = true);
    try {
      if (choice == 'json') {
        await BackupService.exportTransactionsJson(auth.supabaseUser!.id);
      } else {
        await BackupService.exportTransactionsCsv(auth.supabaseUser!.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              choice == 'json' ? 'Backup JSON berhasil diekspor!' : 'Backup CSV berhasil diekspor!',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.card,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export gagal: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importData() async {
    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;

    setState(() => _isImporting = true);
    try {
      final result = await BackupService.importTransactionsWithReport(auth.supabaseUser!.id);
      if (result != null && mounted) {
        await _loadTransactions();
        await auth.refreshStats();
        if (!mounted) return;
        _showImportSummarySheet(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import gagal: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  void _showImportSummarySheet(BuildContext context, ImportResult result) {
    final currencyFmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.68,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            controller: scrollController,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.xpGreen.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('📊', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Laporan Import Transaksi',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${result.successCount} transaksi berhasil diproses dari ${result.totalRows} baris',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Overview Cards
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Pemasukan Terimpor',
                      currencyFmt.format(result.totalIncome),
                      AppColors.xpGreen,
                      '💵',
                    ),
                    const Divider(color: AppColors.cardBorder, height: 20),
                    _buildSummaryRow(
                      'Pengeluaran Terimpor',
                      currencyFmt.format(result.totalExpense),
                      AppColors.danger,
                      '💸',
                    ),
                    const Divider(color: AppColors.cardBorder, height: 20),
                    _buildSummaryRow(
                      'Tabungan & Investasi',
                      currencyFmt.format(result.totalSaving + result.totalInvestment),
                      AppColors.financial,
                      '🏦',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Kategori Terbanyak
              if (result.categoryCounts.isNotEmpty) ...[
                const Text(
                  'RINCIAN KATEGORI TERIMPOR',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    children: result.categoryCounts.entries.take(6).map((e) {
                      final amount = result.categoryAmounts[e.key] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(
                              e.key,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${e.value} tx (${currencyFmt.format(amount)})',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Catatan / Validation Errors jika ada
              if (result.hasErrors) ...[
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.gold, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'CATATAN VALIDASI (${result.errorCount} BARIS DILEWATI)',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: result.validationErrors.take(5).map((err) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '• $err',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('TUTUP & SELESAI', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
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

                  // Data & Backup
                  Row(
                    children: [
                      Container(
                          width: 4,
                          height: 18,
                          decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 10),
                      const Text('DATA & BACKUP',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Export Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isExporting ? null : _exportData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.card,
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isExporting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.file_download_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('EXPORT TRANSACTIONS',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700, letterSpacing: 1)),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Import Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isImporting ? null : _importData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.card,
                        foregroundColor: AppColors.gold,
                        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isImporting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.file_upload_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('IMPORT TRANSACTIONS',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700, letterSpacing: 1)),
                              ],
                            ),
                    ),
                  ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

                  const SizedBox(height: 32),

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
