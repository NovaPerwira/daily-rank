import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/models/category_models.dart';
import 'package:life_rank/core/services/user_stats_service.dart';
import 'package:life_rank/features/auth/providers/auth_provider.dart';
import 'package:life_rank/features/cashflow/providers/boss_battle_provider.dart';
import 'package:life_rank/features/dashboard/widgets/daily_financial_todos.dart';
import 'package:life_rank/features/dashboard/widgets/boss_battle_card.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> {
  List<FinancialTodo> _todos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodos();
    });
  }

  Future<void> _loadTodos() async {
    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;
    
    final td = await UserStatsService.getTodayFinancialTodos(auth.supabaseUser!.id);
    if (mounted) {
      setState(() {
        _todos = td;
        _isLoading = false;
      });
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _completeTodo(FinancialTodo todo) async {
    final auth = context.read<AuthProvider>();
    final userId = auth.supabaseUser?.id;
    if (userId == null) return;

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
    final bossProvider = context.watch<BossBattleProvider>();

    final now = DateTime.now();
    final dateSeed = now.year * 10000 + now.month * 100 + now.day;
    final random = math.Random(dateSeed);

    final presets = _todos.where((t) => !t.isCustom).toList();
    final customs = _todos.where((t) => t.isCustom).toList();

    final shuffledPresets = List<FinancialTodo>.from(presets)..shuffle(random);
    final highlightedIds = shuffledPresets.take(2).map((t) => t.id).toSet();
    final displayedTodos = [...shuffledPresets, ...customs];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('TUGAS & GAME', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : RefreshIndicator(
            onRefresh: _loadTodos,
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (bossProvider.bosses.isNotEmpty) ...[
                  const _QuestsSectionLabel(
                    label: 'BOSS BATTLES (TAGIHAN)',
                    color: AppColors.danger,
                  ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                  const SizedBox(height: 12),
                  ...bossProvider.bosses.map((boss) => BossBattleCard(boss: boss)),
                  const SizedBox(height: 24),
                ],
                
                DailyFinancialTodos(
                  todos: displayedTodos,
                  highlightedIds: highlightedIds,
                  onComplete: _completeTodo,
                  onDelete: _deleteTodo,
                  onAddCustom: _addCustomTodo,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
    );
  }
}

class _QuestsSectionLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _QuestsSectionLabel({required this.label, required this.color});

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
