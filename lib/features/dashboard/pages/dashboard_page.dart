import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:life_rank/features/auth/providers/auth_provider.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/constants/wealth_config.dart';
import 'package:life_rank/core/models/category_models.dart';
import 'package:life_rank/core/services/user_stats_service.dart';
import '../widgets/overall_rank_card.dart';
import '../widgets/financial_rank_card.dart';
import '../widgets/savings_chart_widget.dart';
import '../widgets/net_worth_sheet.dart';
import '../widgets/zombie_mode_wrapper.dart';
import '../widgets/safe_zone_banner.dart';
import '../widgets/financial_hp_bar.dart';
import '../../cashflow/providers/gacha_provider.dart';
import '../widgets/gacha_modal.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<TransactionModel> _transactions = [];
  CurrencyMode _currencyMode = CurrencyMode.idr;

  /// Monthly savings history for chart
  List<Map<String, dynamic>> _monthlySavings = [];

  /// Days with activity this month for streak
  Set<int> _activeDays = {};

  bool _isSimulatePayday = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;
    final userId = auth.supabaseUser!.id;

    final txs = await UserStatsService.getTransactions(userId);
    final mSavings = await UserStatsService.getMonthlySavingsHistory(userId, preloadedTxs: txs);
    final active = await UserStatsService.getMonthlyActivedays(userId, preloadedTxs: txs);
    if (mounted) {
      setState(() {
        _transactions = txs;
        _monthlySavings = mSavings;
        _activeDays = active;
      });
      context.read<GachaProvider>().checkStreakAndAwardTicket(active.length);
    }
  }

  void _toggleCurrency() {
    setState(() {
      _currencyMode =
          _currencyMode == CurrencyMode.idr ? CurrencyMode.usd : CurrencyMode.idr;
    });
  }

  /// Net Worth for Rank = Pemasukan - Pengeluaran (pengeluaran investasi/tabungan tidak mengurangi rank)
  double get _rankNetWorthIdr {
    double income = 0, expense = 0, investmentExpense = 0;
    for (final t in _transactions) {
      if (t.type == 'income') {
        income += t.amount;
      } else if (t.type == 'expense') {
        expense += t.amount;
        final cat = t.category?.toLowerCase() ?? '';
        if (cat.contains('investasi') || cat.contains('tabungan') || cat.contains('dana darurat')) {
          investmentExpense += t.amount;
        }
      } else if (t.type == 'saving' || t.type == 'investment') {
        expense += t.amount;
        investmentExpense += t.amount;
      }
    }
    return income - expense + investmentExpense;
  }

  /// HP Financial Health: (Income - PureExpense) / Income (Current Month Only)
  double get _financialHpPercentage {
    final now = DateTime.now();
    double income = 0;
    double pureExpense = 0;
    
    for (final t in _transactions) {
      final date = t.date;
      if (date.year == now.year && date.month == now.month) {
        if (t.type == 'income') {
          income += t.amount;
        } else if (t.type == 'expense') {
          final cat = t.category?.toLowerCase() ?? '';
          final isAsset = cat.contains('investasi') || cat.contains('tabungan') || cat.contains('dana darurat');
          if (!isAsset) {
            pureExpense += t.amount;
          }
        }
      }
    }
    
    if (income == 0) return pureExpense > 0 ? 0.0 : 1.0;
    double hp = (income - pureExpense) / income;
    return hp.clamp(0.0, 1.0);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ── Todo actions ────────────────────────────────────────────────────────────

  void _showSavingsChartDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SavingsChartWidget(
                  monthlySavings: _monthlySavings,
                  barColor: AppColors.financial,
                  isCompact: false,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Note: Todos and Boss Battles logic moved to QuestsPage
  // Note: Stats and Metrics logic moved to StatsPage

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final stats = auth.stats;
    final profile = auth.profile;
    final gachaProvider = context.watch<GachaProvider>();

    if (stats == null || profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.financial),
        ),
      );
    }

    final streakCount = _activeDays.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await auth.refreshStats();
              await _loadInitialData();
            },
            color: AppColors.financial,
            backgroundColor: AppColors.card,
            child: ZombieModeWrapper(
              isZombie: _rankNetWorthIdr <= 0,
              child: CustomScrollView(
                slivers: [
                  // ── App Bar ────────────────────────────────────────────────────
                  SliverAppBar(
                    expandedHeight: 0,
                    toolbarHeight: 60,
                    floating: true,
                    pinned: true,
                    backgroundColor: AppColors.background.withValues(alpha: 0.9),
                    elevation: 0,
                    actions: [
                      IconButton(
                        tooltip: 'Simulasi Payday (Safe Zone)',
                        icon: Icon(
                          _isSimulatePayday ? Icons.shield_rounded : Icons.shield_outlined,
                          color: _isSimulatePayday ? Colors.amberAccent : AppColors.textSecondary,
                          size: 22,
                        ),
                        onPressed: () {
                          setState(() {
                            _isSimulatePayday = !_isSimulatePayday;
                          });
                          if (_isSimulatePayday) {
                            _showSnack('Safe Zone Diaktifkan! Uang kebal hukuman.');
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.inventory_2_rounded, color: AppColors.xpGreen, size: 22),
                        onPressed: () => GachaModal.show(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.receipt_long, color: AppColors.financial, size: 22),
                        onPressed: () => context.push('/cashflow'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded,
                            color: AppColors.textSecondary, size: 22),
                        onPressed: () async {
                          await auth.refreshStats();
                          await _loadInitialData();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),

                  // ── Main Content ───────────────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        
                        // ── Safe Zone Banner (Payday) ───────────────────────────
                        SafeZoneBanner(isPayday: _isSimulatePayday),

                        // ── User Profile Header (rank from total savings) ───────
                        UserProfileHeader(
                          stats: stats,
                          username: profile.username,
                          avatarUrl: profile.avatarUrl,
                          currencyMode: _currencyMode,
                          onCurrencyToggle: _toggleCurrency,
                          netWorthIdr: _rankNetWorthIdr,
                          streakCount: streakCount,
                          userId: auth.supabaseUser?.id,
                          transactions: _transactions,
                          financialHpPercentage: _financialHpPercentage,
                        ),

                        const SizedBox(height: 20),

                        // ── Hero Financial Rank Card (incorporates embedded chart!) ──
                        FinancialRankCard(
                          netWorthIdr: _rankNetWorthIdr,
                          displayNetWorthIdr: _rankNetWorthIdr, 
                          monthlySavings: _monthlySavings,
                          onTapEdit: () async {
                            final res = await NetWorthSheet.show(context,
                                currentIdr: _rankNetWorthIdr, currencyMode: _currencyMode);
                            if (res != null) {
                              _showSnack('Net worth updated to Rp ${res.amountIdr}');
                            }
                          },
                          onTapChart: () => _showSavingsChartDetail(context),
                        ),

                        const SizedBox(height: 20),

                        // ── Financial HP Bar (NEW) ──────────────────────────────
                        FinancialHpBar(hpPercentage: _financialHpPercentage),
                        const SizedBox(height: 20),

                        const SizedBox(height: 100), // Extra scrolling space
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Notif Gacha
          if (gachaProvider.shouldShowNotif)
            Positioned(
              right: 16,
              top: 100, // Below app bar
              child: _buildGachaNotif(gachaProvider),
            ),
        ],
      ),
    );
  }

  Widget _buildGachaNotif(GachaProvider provider) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.xpGreen.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: AppColors.xpGreen.withValues(alpha: 0.2),
              blurRadius: 8,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => GachaModal.show(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2_rounded, color: AppColors.xpGreen, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${provider.tickets} Gacha Tersedia!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => provider.closeNotif(),
              child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 16),
            ),
          ],
        ),
      ).animate().slideX(begin: 1.0).fadeIn(),
    );
  }
}
