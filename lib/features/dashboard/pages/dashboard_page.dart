import 'dart:math' as math;
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
import '../widgets/category_card.dart';
import '../widgets/financial_rank_card.dart';
import '../widgets/financial_metrics_row.dart';
import '../widgets/daily_financial_todos.dart';
import '../widgets/savings_chart_widget.dart';
import '../widgets/monthly_streak_widget.dart';
import '../widgets/net_worth_sheet.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<TransactionModel> _transactions = [];
  CurrencyMode _currencyMode = CurrencyMode.idr;

  /// Daily financial todos
  List<FinancialTodo> _todos = [];

  /// Monthly savings history for chart
  List<Map<String, dynamic>> _monthlySavings = [];

  /// Days with activity this month for streak
  Set<int> _activeDays = {};

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
    final td = await UserStatsService.getTodayFinancialTodos(userId);
    final savings = await UserStatsService.getMonthlySavingsHistory(userId, preloadedTxs: txs);
    final active = await UserStatsService.getMonthlyActivedays(userId, preloadedTxs: txs);

    if (mounted) {
      setState(() {
        _transactions = txs;
        _todos = td;
        _monthlySavings = savings;
        _activeDays = active;
      });
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

  Future<void> _completeTodo(FinancialTodo todo) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.supabaseUser?.id;
    if (userId == null) return;

    // Deterministic seed based on date to check if it's highlighted today
    final now = DateTime.now();
    final dateSeed = now.year * 10000 + now.month * 100 + now.day;
    final random = math.Random(dateSeed);

    final presets = _todos.where((t) => !t.isCustom).toList();
    final shuffledPresets = List<FinancialTodo>.from(presets)..shuffle(random);
    final highlightedIds = shuffledPresets.take(2).map((t) => t.id).toSet();

    final isHighlighted = highlightedIds.contains(todo.id);
    final finalPoints = isHighlighted ? todo.points * 2 : todo.points;

    await UserStatsService.completeFinancialTodo(todo.id);
    await UserStatsService.updateCategoryXp(userId, 'financial', finalPoints);
    await auth.refreshStats();

    setState(() {
      final idx = _todos.indexWhere((t) => t.id == todo.id);
      if (idx != -1) _todos[idx].completed = true;
    });
    _showSnack('${todo.icon} +$finalPoints pts — Kerja bagus! 🔥${isHighlighted ? " (Misi Utama 2x XP)" : ""}');
  }

  Future<void> _deleteTodo(FinancialTodo todo) async {
    await UserStatsService.deleteFinancialTodo(todo.id);
    setState(() => _todos.removeWhere((t) => t.id == todo.id));
  }

  Future<void> _addCustomTodo(String title) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.supabaseUser?.id;
    if (userId == null) return;

    final newTodo = FinancialTodo(
      id: '',
      userId: userId,
      title: title,
      desc: '',
      icon: '🎯',
      points: 50,
      isCustom: true,
    );

    await UserStatsService.addCustomFinancialTodo(newTodo);
    final updated = await UserStatsService.getTodayFinancialTodos(userId);
    if (mounted) setState(() => _todos = updated);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final stats = auth.stats;
    final profile = auth.profile;

    if (stats == null || profile == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.financial),
        ),
      );
    }

    final streakCount = _activeDays.length;

    // Date-based deterministic randomizer for daily presets
    final now = DateTime.now();
    final dateSeed = now.year * 10000 + now.month * 100 + now.day;
    final random = math.Random(dateSeed);

    final presets = _todos.where((t) => !t.isCustom).toList();
    final customs = _todos.where((t) => t.isCustom).toList();

    // Shuffle preset daily todos deterministically based on date
    final shuffledPresets = List<FinancialTodo>.from(presets)..shuffle(random);
    final highlightedIds = shuffledPresets.take(2).map((t) => t.id).toSet();

    // Recombine (presets first in shuffled order, then customs)
    final displayedTodos = [...shuffledPresets, ...customs];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await auth.refreshStats();
          await _loadInitialData();
        },
        color: AppColors.financial,
        backgroundColor: AppColors.card,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ────────────────────────────────────────────────────
            SliverAppBar(
              floating: true,
              snap: true,
              backgroundColor: AppColors.background,
              expandedHeight: 56,
              titleSpacing: 20,
              title: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.financial, AppColors.xpGreen],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.financial.withValues(alpha: 0.4),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('S',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'SAVINGRANK',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.5,
                    ),
                  ),
                ],
              ),
              actions: [
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
                  ),

                  const SizedBox(height: 20),

                  // ── Hero Financial Rank Card (incorporates embedded chart!) ──
                  FinancialRankCard(
                    netWorthIdr: _rankNetWorthIdr,
                    displayNetWorthIdr: _rankNetWorthIdr, // Now it displays the full 'My Wealth' value
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

                  // ── Financial Metrics 2×2 ──────────────────────────────
                  _SectionLabel(
                    label: 'FINANCIAL METRICS',
                    color: AppColors.financial,
                  ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

                  const SizedBox(height: 12),

                  FinancialMetricsRow(
                    transactions: _transactions,
                    currencyMode: _currencyMode,
                  ),

                  const SizedBox(height: 20),

                  // ── Supporting Attributes (Moved below metrics!) ──────────
                  _SectionLabel(
                    label: 'ATTRIBUTES',
                    color: AppColors.textSecondary,
                  ).animate().fadeIn(duration: 400.ms, delay: 450.ms),

                  const SizedBox(height: 12),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.45,
                    children: [
                      SupportAttributeCard(
                        title: 'Career',
                        rpgLabel: 'Income Engine',
                        emoji: '💼',
                        color: AppColors.career,
                        xp: stats.careerXp,
                        route: '/career',
                        index: 0,
                      ),
                      SupportAttributeCard(
                        title: 'Knowledge',
                        rpgLabel: 'Skill Power',
                        emoji: '📚',
                        color: AppColors.knowledge,
                        xp: stats.knowledgeXp,
                        route: '/knowledge',
                        index: 1,
                      ),
                      SupportAttributeCard(
                        title: 'Habit',
                        rpgLabel: 'Discipline',
                        emoji: '🔥',
                        color: AppColors.habit,
                        xp: stats.habitXp,
                        route: '/habit',
                        index: 2,
                      ),
                      SupportAttributeCard(
                        title: 'Health',
                        rpgLabel: 'Energy',
                        emoji: '💪',
                        color: AppColors.health,
                        xp: stats.healthXp,
                        route: '/health',
                        index: 3,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Streak Bulan Ini (Moved below attributes!) ──────────
                  _SectionLabel(
                    label: 'STREAK BULAN INI',
                    color: AppColors.habit,
                  ).animate().fadeIn(duration: 400.ms, delay: 500.ms),

                  const SizedBox(height: 12),

                  MonthlyStreakWidget(
                    activeDays: _activeDays,
                    accentColor: AppColors.habit,
                  ),

                  const SizedBox(height: 28),

                  // ── Daily Financial Todos + Motivation ─────────────────
                  DailyFinancialTodos(
                    todos: displayedTodos,
                    highlightedIds: highlightedIds,
                    onComplete: _completeTodo,
                    onDelete: _deleteTodo,
                    onAddCustom: _addCustomTodo,
                  ),

                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}
