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

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  final _weightCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isLoading = false;
  List<HealthEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;
    final e = await UserStatsService.getHealthEntries(auth.supabaseUser!.id);
    if (mounted) setState(() => _entries = e);
  }

  Future<void> _logActivity(String type, int xp, {double? value, String? note}) async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;
    final userId = auth.supabaseUser!.id;

    final entry = HealthEntry(
      id: '',
      userId: userId,
      type: type,
      note: note,
      value: value,
      xpEarned: xp,
      date: DateTime.now(),
    );
    await UserStatsService.addHealthEntry(entry);
    final prevStats = auth.stats;
    final newStats = await UserStatsService.updateCategoryXp(userId, 'health', xp);
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
            title: type == 'workout' ? 'Workout Complete! 💪' : 'Weight Logged! ⚖️',
            description: type == 'workout' ? 'Great session!' : 'Tracking is the first step!',
            xpReward: xp,
          );
        }
      }
    }
    _weightCtrl.clear();
    _noteCtrl.clear();
    await _loadEntries();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final healthXp = auth.stats?.healthXp ?? 0;
    final workoutCount = _entries.where((e) => e.type == 'workout').length;
    final weightEntries = _entries.where((e) => e.type == 'weight').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('💪 Health'), backgroundColor: AppColors.background),
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
                border: Border.all(color: AppColors.health.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      RankBadgeWidget(xp: healthXp, size: RankBadgeSize.small, showLabel: false),
                      const SizedBox(width: 16),
                      Expanded(child: AnimatedXpBar(currentXp: healthXp, color: AppColors.health)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(label: 'Workouts', value: '$workoutCount', icon: '🏋️'),
                      _StatItem(label: 'Weight Logs', value: '${weightEntries.length}', icon: '⚖️'),
                      _StatItem(
                        label: 'Last Weight',
                        value: weightEntries.isNotEmpty ? '${weightEntries.first.value} kg' : '-',
                        icon: '📊',
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 24),

            // Quick action buttons
            Row(
              children: [
                Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.health, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                const Text('LOG ACTIVITY', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ],
            ),

            const SizedBox(height: 16),

            // Workout button (big)
            GestureDetector(
              onTap: _isLoading ? null : () => _logActivity('workout', RankConfig.workoutXp),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.health.withOpacity(0.2), AppColors.card],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.health.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Text('🏋️', style: TextStyle(fontSize: 36)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Log Workout', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                        const Text('Tap to record a workout session', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.xpGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.xpGreen.withOpacity(0.4)),
                      ),
                      child: Text('+${RankConfig.workoutXp} XP', style: const TextStyle(color: AppColors.xpGreen, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

            const SizedBox(height: 16),

            // Weight tracking
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text('⚖️', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 10),
                      Text('Weight Tracking', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                      Spacer(),
                      Text('+50 XP', style: TextStyle(color: AppColors.xpGreen, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Current Weight',
                      hintText: '70.5',
                      suffixText: 'kg',
                      suffixStyle: TextStyle(color: AppColors.textSecondary),
                      prefixIcon: Icon(Icons.scale, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      hintText: 'e.g. After morning run',
                      prefixIcon: Icon(Icons.notes, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading || _weightCtrl.text.isEmpty
                          ? null
                          : () => _logActivity(
                                'weight',
                                RankConfig.weightTrackingXp,
                                value: double.tryParse(_weightCtrl.text),
                                note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.info,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('LOG WEIGHT', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

            const SizedBox(height: 24),

            // Activity history
            if (_entries.isNotEmpty) ...[
              Row(
                children: [
                  Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.health, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  const Text('ACTIVITY LOG', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                ],
              ),
              const SizedBox(height: 12),
              ..._entries.take(10).toList().asMap().entries.map((entry) {
                final e = entry.value;
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
                      Text(e.type == 'workout' ? '🏋️' : '⚖️', style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.type == 'weight' ? '${e.value} kg' : 'Workout Session',
                              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy, HH:mm').format(e.date),
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text('+${e.xpEarned} XP', style: const TextStyle(color: AppColors.xpGreen, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ).animate(delay: Duration(milliseconds: 40 * entry.key)).fadeIn(duration: 300.ms);
              }),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 0.5)),
      ],
    );
  }
}
