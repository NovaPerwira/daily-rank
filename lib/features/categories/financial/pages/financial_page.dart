import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/constants/rank_config.dart';
import 'package:life_rank/core/models/category_models.dart';
import 'package:life_rank/core/services/user_stats_service.dart';
import 'package:life_rank/shared/widgets/animated_xp_bar.dart';
import 'package:life_rank/shared/widgets/rank_badge_widget.dart';
import 'package:life_rank/shared/widgets/achievement_popup.dart';
import 'package:life_rank/features/auth/providers/auth_provider.dart';

class FinancialPage extends StatefulWidget {
  const FinancialPage({super.key});

  @override
  State<FinancialPage> createState() => _FinancialPageState();
}

class _FinancialPageState extends State<FinancialPage> {
  final _formKey = GlobalKey<FormState>();
  final _incomeCtrl = TextEditingController();
  final _expenseCtrl = TextEditingController();
  final _savingCtrl = TextEditingController();
  final _investmentCtrl = TextEditingController();
  bool _hasDebt = false;
  bool _isLoading = false;
  List<TransactionModel> _transactions = [];
  final _formatter = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _expenseCtrl.dispose();
    _savingCtrl.dispose();
    _investmentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;
    final txs = await UserStatsService.getTransactions(auth.supabaseUser!.id);
    if (mounted) setState(() => _transactions = txs);
  }

  int _calculateFinancialXp() {
    final income = double.tryParse(_incomeCtrl.text.replaceAll(',', '')) ?? 0;
    final saving = double.tryParse(_savingCtrl.text.replaceAll(',', '')) ?? 0;
    final investment = double.tryParse(_investmentCtrl.text.replaceAll(',', '')) ?? 0;

    // Saving XP (40%)
    final savingXp = (RankConfig.calculateSavingXp(saving) * 0.40).round();

    // Saving rate XP (25%)
    final savingRate = income > 0 ? (saving / income * 100) : 0.0;
    final savingRateXp = (RankConfig.calculateSavingRateXp(savingRate.toDouble()) * 0.25).round();

    // Investment XP (20%)
    final investmentXp = investment > 0
        ? (RankConfig.calculateSavingXp(investment) * 0.20).round()
        : 0;

    // Debt management XP (15%)
    final debtXp = (RankConfig.calculateDebtManagementXp(!_hasDebt, 0) * 0.15).round();

    return savingXp + savingRateXp + investmentXp + debtXp;
  }

  Future<void> _submitFinancial() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;
    final userId = auth.supabaseUser!.id;

    final income = double.tryParse(_incomeCtrl.text.replaceAll(',', '')) ?? 0;
    final expense = double.tryParse(_expenseCtrl.text.replaceAll(',', '')) ?? 0;
    final saving = double.tryParse(_savingCtrl.text.replaceAll(',', '')) ?? 0;
    final investment = double.tryParse(_investmentCtrl.text.replaceAll(',', '')) ?? 0;

    // Save transactions
    final now = DateTime.now();
    final txs = [
      if (income > 0) TransactionModel(id: '', userId: userId, type: 'income', amount: income, date: now),
      if (expense > 0) TransactionModel(id: '', userId: userId, type: 'expense', amount: expense, date: now),
      if (saving > 0) TransactionModel(id: '', userId: userId, type: 'saving', amount: saving, date: now),
      if (investment > 0) TransactionModel(id: '', userId: userId, type: 'investment', amount: investment, date: now),
    ];
    for (final tx in txs) {
      await UserStatsService.addTransaction(tx);
    }

    final xpEarned = _calculateFinancialXp();
    final prevStats = auth.stats;
    final newStats = await UserStatsService.updateCategoryXp(userId, 'financial', xpEarned);

    if (newStats != null) {
      await auth.updateStats(newStats);
      // Check rank up
      if (prevStats != null && mounted) {
        final prevRank = RankConfig.getRankInfo(prevStats.totalXp).name;
        final newRank = RankConfig.getRankInfo(newStats.totalXp).name;
        if (prevRank != newRank) {
          final rankInfo = RankConfig.getRankInfo(newStats.totalXp);
          RankUpCelebration.show(
            context,
            newRank: rankInfo.name,
            emoji: rankInfo.emoji,
            rankColor: rankInfo.color,
          );
        } else if (xpEarned > 0 && mounted) {
          AchievementPopup.show(
            context,
            title: 'Financial Log Added!',
            description: 'Your financial data has been recorded.',
            xpReward: xpEarned,
          );
        }
      }
    }

    await _loadTransactions();
    _incomeCtrl.clear();
    _expenseCtrl.clear();
    _savingCtrl.clear();
    _investmentCtrl.clear();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final financialXp = auth.stats?.financialXp ?? 0;
    final savingRate = () {
      final i = double.tryParse(_incomeCtrl.text.replaceAll(',', '')) ?? 0;
      final s = double.tryParse(_savingCtrl.text.replaceAll(',', '')) ?? 0;
      return i > 0 ? (s / i * 100) : 0.0;
    }();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('💰 Financial'),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.financial.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  RankBadgeWidget(xp: financialXp, size: RankBadgeSize.medium),
                  const SizedBox(height: 16),
                  AnimatedXpBar(currentXp: financialXp, color: AppColors.financial),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 24),

            // Monthly Input Form
            _SectionTitle(title: 'Monthly Record', color: AppColors.financial),
            const SizedBox(height: 12),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  _NumberField(
                    controller: _incomeCtrl,
                    label: 'Income',
                    hint: '0',
                    prefix: 'Rp',
                    color: AppColors.xpGreen,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    controller: _expenseCtrl,
                    label: 'Expense',
                    hint: '0',
                    prefix: 'Rp',
                    color: AppColors.danger,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    controller: _savingCtrl,
                    label: 'Saving',
                    hint: '0',
                    prefix: 'Rp',
                    color: AppColors.financial,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    controller: _investmentCtrl,
                    label: 'Investment',
                    hint: '0',
                    prefix: 'Rp',
                    color: AppColors.primary,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),

                  // Debt toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'I have debt / hutang',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                        ),
                        Switch(
                          value: _hasDebt,
                          onChanged: (v) => setState(() => _hasDebt = v),
                          activeColor: AppColors.danger,
                          inactiveThumbColor: AppColors.xpGreen,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

            const SizedBox(height: 16),

            // Saving rate preview
            if (savingRate > 0)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.financial.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.financial.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Saving Rate:', style: TextStyle(color: AppColors.textSecondary)),
                    Text(
                      '${savingRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: savingRate >= 20 ? AppColors.xpGreen : AppColors.warning,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '+${_calculateFinancialXp()} XP',
                      style: const TextStyle(color: AppColors.xpGreen, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

            const SizedBox(height: 20),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitFinancial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.financial,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                    : const Text('RECORD & EARN XP', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 400.ms),

            const SizedBox(height: 28),

            // Transaction history
            if (_transactions.isNotEmpty) ...[
              _SectionTitle(title: 'Recent Transactions', color: AppColors.financial),
              const SizedBox(height: 12),
              ..._transactions.take(10).map((tx) => _TransactionTile(tx: tx)),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String prefix;
  final Color color;
  final ValueChanged<String>? onChanged;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefix,
    required this.color,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      style: TextStyle(color: color, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: '$prefix ',
        prefixStyle: TextStyle(color: color.withOpacity(0.7), fontWeight: FontWeight.w600),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionModel tx;

  const _TransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final color = switch (tx.type) {
      'income' => AppColors.xpGreen,
      'expense' => AppColors.danger,
      'saving' => AppColors.financial,
      'investment' => AppColors.primary,
      _ => AppColors.textSecondary,
    };
    final emoji = switch (tx.type) {
      'income' => '💵',
      'expense' => '💸',
      'saving' => '💰',
      'investment' => '📈',
      _ => '💳',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.type.toUpperCase(),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, letterSpacing: 1),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(tx.date),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            'Rp ${NumberFormat('#,###', 'id_ID').format(tx.amount)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Color color;

  const _SectionTitle({required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
      ],
    );
  }
}
