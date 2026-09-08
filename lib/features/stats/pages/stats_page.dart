import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/constants/wealth_config.dart';
import 'package:life_rank/core/models/category_models.dart';
import 'package:life_rank/core/services/user_stats_service.dart';
import 'package:life_rank/features/auth/providers/auth_provider.dart';
import 'package:life_rank/features/dashboard/widgets/financial_metrics_row.dart';
import 'package:life_rank/features/dashboard/widgets/category_card.dart';
import 'package:life_rank/features/dashboard/widgets/monthly_streak_widget.dart';
import 'package:life_rank/features/stats/widgets/cashflow_chart_widget.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  List<TransactionModel> _transactions = [];
  Set<int> _activeDays = {};
  final CurrencyMode _currencyMode = CurrencyMode.idr;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatsData();
    });
  }

  Future<void> _loadStatsData() async {
    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;

    final userId = auth.supabaseUser!.id;
    final txs = await UserStatsService.getTransactions(userId);
    final active = await UserStatsService.getMonthlyActivedays(
      userId,
      preloadedTxs: txs,
    );

    if (mounted) {
      setState(() {
        _transactions = txs;
        _activeDays = active;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final stats = auth.stats;

    if (stats == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'ANALYTICS & STATS',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadStatsData,
              color: AppColors.primary,
              backgroundColor: AppColors.card,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Financial Metrics 2×2 ──────────────────────────────
                  const _StatsSectionLabel(
                    label: 'FINANCIAL METRICS',
                    color: AppColors.financial,
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                  const SizedBox(height: 12),

                  FinancialMetricsRow(
                    transactions: _transactions,
                    currencyMode: _currencyMode,
                  ),

                  const SizedBox(height: 32),

                  // ── Cashflow Chart ──────────────────────────────
                  const _StatsSectionLabel(
                    label: 'CASHFLOW (6 BULAN)',
                    color: AppColors.financial,
                  ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

                  const SizedBox(height: 12),

                  CashflowChartWidget(transactions: _transactions)
                      .animate().fadeIn(duration: 500.ms, delay: 200.ms),

                  const SizedBox(height: 32),

                  // ── Supporting Attributes ──────────────────────────
                  const _StatsSectionLabel(
                    label: 'ATTRIBUTES',
                    color: AppColors.textSecondary,
                  ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

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

                  const SizedBox(height: 32),

                  // ── Streak Bulan Ini ──────────────────────────
                  const _StatsSectionLabel(
                    label: 'STREAK BULAN INI',
                    color: AppColors.habit,
                  ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

                  const SizedBox(height: 12),

                  MonthlyStreakWidget(
                    activeDays: _activeDays,
                    accentColor: AppColors.habit,
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }
}

class _StatsSectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _StatsSectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
