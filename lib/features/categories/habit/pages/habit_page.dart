import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/constants/rank_config.dart';
import 'package:life_rank/core/models/category_models.dart';
import 'package:life_rank/core/services/user_stats_service.dart';
import 'package:life_rank/shared/widgets/animated_xp_bar.dart';
import 'package:life_rank/shared/widgets/rank_badge_widget.dart';
import 'package:life_rank/shared/widgets/achievement_popup.dart';
import 'package:life_rank/features/auth/providers/auth_provider.dart';

class HabitPage extends StatefulWidget {
  const HabitPage({super.key});

  @override
  State<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends State<HabitPage> {
  List<QuestModel> _quests = [];
  bool _loading = true;
  final int _streakDays = 0;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;
    final userId = auth.supabaseUser!.id;
    await UserStatsService.seedDailyQuests(userId);
    final quests = await UserStatsService.getTodayQuests(userId);
    if (mounted) {
      setState(() {
        _quests = quests;
        _loading = false;
      });
    }
  }

  Future<void> _completeQuest(QuestModel quest) async {
    if (quest.completed) return;
    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;

    await UserStatsService.completeQuest(quest.id);
    final prevStats = auth.stats;
    final newStats = await UserStatsService.updateCategoryXp(
      auth.supabaseUser!.id,
      'habit',
      quest.xpReward,
    );

    if (newStats != null) {
      await auth.updateStats(newStats);
      if (prevStats != null && mounted) {
        final prevRank = RankConfig.getRankInfo(prevStats.totalXp).name;
        final newRankName = RankConfig.getRankInfo(newStats.totalXp).name;
        if (prevRank != newRankName) {
          final rankInfo = RankConfig.getRankInfo(newStats.totalXp);
          RankUpCelebration.show(context, newRank: rankInfo.name, emoji: rankInfo.emoji, rankColor: rankInfo.color);
        } else {
          AchievementPopup.show(
            context,
            title: '${quest.title} Done!',
            description: 'Quest completed. Keep it up!',
            xpReward: quest.xpReward,
          );
        }
      }
    }

    setState(() {
      final idx = _quests.indexWhere((q) => q.id == quest.id);
      if (idx != -1) _quests[idx] = quest.copyWith(completed: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final habitXp = auth.stats?.habitXp ?? 0;
    final completed = _quests.where((q) => q.completed).length;
    final total = _quests.length;
    final allDone = total > 0 && completed == total;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🔥 Habit'),
        backgroundColor: AppColors.background,
      ),
      body: RefreshIndicator(
        onRefresh: _loadQuests,
        color: AppColors.habit,
        backgroundColor: AppColors.card,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Status card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.habit.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      RankBadgeWidget(xp: habitXp, size: RankBadgeSize.small, showLabel: false),
                      const SizedBox(width: 16),
                      Expanded(child: AnimatedXpBar(currentXp: habitXp, color: AppColors.habit)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Daily progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatChip(label: 'Today', value: '$completed/$total', color: AppColors.habit),
                      _StatChip(label: 'Streak', value: '${_streakDays}d 🔥', color: AppColors.warning),
                      _StatChip(label: 'Status', value: allDone ? '✅ Done' : '⏳ In Progress', color: AppColors.xpGreen),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 20),

            // Quest progress bar
            if (total > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.habit, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 10),
                      const Text('DAILY QUESTS', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 2)),
                    ],
                  ),
                  Text('$completed/$total', style: TextStyle(color: AppColors.habit, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? completed / total : 0,
                  backgroundColor: AppColors.cardBorder,
                  valueColor: AlwaysStoppedAnimation(AppColors.habit),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppColors.habit))
            else
              ..._quests.asMap().entries.map((entry) {
                final quest = entry.value;
                return _QuestCard(
                  quest: quest,
                  onComplete: () => _completeQuest(quest),
                  index: entry.key,
                );
              }),

            const SizedBox(height: 24),

            // Streak bonus info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🔥 Streak Bonus XP',
                    style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  ...RankConfig.streakBonusXp.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${e.key} days streak', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          Text('+${e.value} XP', style: const TextStyle(color: AppColors.xpGreen, fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 400.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final QuestModel quest;
  final VoidCallback onComplete;
  final int index;

  const _QuestCard({required this.quest, required this.onComplete, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: quest.completed ? AppColors.xpGreen.withValues(alpha: 0.4) : AppColors.cardBorder,
        ),
        boxShadow: quest.completed
            ? [BoxShadow(color: AppColors.xpGreen.withValues(alpha: 0.1), blurRadius: 8)]
            : [],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: GestureDetector(
          onTap: quest.completed ? null : onComplete,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: quest.completed ? AppColors.xpGreen : Colors.transparent,
              border: Border.all(
                color: quest.completed ? AppColors.xpGreen : AppColors.textMuted,
                width: 2,
              ),
            ),
            child: quest.completed
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        ),
        title: Text(
          quest.title,
          style: TextStyle(
            color: quest.completed ? AppColors.textMuted : AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            decoration: quest.completed ? TextDecoration.lineThrough : null,
            decorationColor: AppColors.textMuted,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.xpGreen.withValues(alpha: quest.completed ? 0.05 : 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '+${quest.xpReward} XP',
            style: TextStyle(
              color: quest.completed ? AppColors.textMuted : AppColors.xpGreen,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.2, end: 0, duration: 400.ms);
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }
}
