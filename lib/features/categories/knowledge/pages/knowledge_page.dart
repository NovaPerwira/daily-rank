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

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  String _selectedType = 'Book';
  final _titleCtrl = TextEditingController();
  bool _isLoading = false;
  List<KnowledgeEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;
    final e = await UserStatsService.getKnowledgeEntries(auth.supabaseUser!.id);
    if (mounted) setState(() => _entries = e);
  }

  Future<void> _addEntry() async {
    if (_titleCtrl.text.isEmpty) return;
    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;
    final userId = auth.supabaseUser!.id;
    final xp = RankConfig.knowledgeXp[_selectedType] ?? 100;

    setState(() => _isLoading = true);

    try {
      final entry = KnowledgeEntry(
        id: '',
        userId: userId,
        type: _selectedType.toLowerCase(),
        title: _titleCtrl.text.trim(),
        xpEarned: xp,
        addedAt: DateTime.now(),
      );
      await UserStatsService.addKnowledgeEntry(entry);
      final prevStats = auth.stats;
      final newStats = await UserStatsService.updateCategoryXp(userId, 'knowledge', xp);
      if (newStats != null) {
        await auth.updateStats(newStats);
        if (prevStats != null && mounted) {
          final prevRank = RankConfig.getRankInfo(prevStats.totalXp).name;
          final newRankName = RankConfig.getRankInfo(newStats.totalXp).name;
          if (prevRank != newRankName) {
            final rankInfo = RankConfig.getRankInfo(newStats.totalXp);
            RankUpCelebration.show(context, newRank: rankInfo.name, emoji: rankInfo.emoji, rankColor: rankInfo.color);
          } else {
            AchievementPopup.show(context, title: '$_selectedType Added!', description: '"${_titleCtrl.text}" recorded.', xpReward: xp);
          }
        }
      }
      _titleCtrl.clear();
      await _loadEntries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final knowledgeXp = auth.stats?.knowledgeXp ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('📚 Knowledge'), backgroundColor: AppColors.background),
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
                border: Border.all(color: AppColors.knowledge.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  RankBadgeWidget(xp: knowledgeXp, size: RankBadgeSize.small, showLabel: false),
                  const SizedBox(width: 16),
                  Expanded(child: AnimatedXpBar(currentXp: knowledgeXp, color: AppColors.knowledge)),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),

            const SizedBox(height: 24),

            // Type selection
            Row(
              children: [
                Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.knowledge, borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                const Text('WHAT DID YOU LEARN?', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
              ],
            ),

            const SizedBox(height: 16),

            // XP type cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.2,
              children: RankConfig.knowledgeXp.entries.map((e) {
                final isSelected = _selectedType == e.key;
                final emoji = switch (e.key) {
                  'Book' => '📖',
                  'Online Course' => '🎓',
                  'Certificate' => '🏅',
                  'Research Paper' => '🔬',
                  _ => '📚',
                };
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.knowledge.withValues(alpha: 0.15) : AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.knowledge : AppColors.cardBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(e.key, style: TextStyle(color: isSelected ? AppColors.knowledge : AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                              Text('+${e.value} XP', style: const TextStyle(color: AppColors.xpGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(duration: 500.ms, delay: 100.ms),

            const SizedBox(height: 20),

            TextFormField(
              controller: _titleCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Clean Code by Robert C. Martin',
                prefixIcon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.knowledge),
                ),
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addEntry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.knowledge,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                    : Text(
                        'RECORD +${RankConfig.knowledgeXp[_selectedType]} XP',
                        style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.5),
                      ),
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 300.ms),

            const SizedBox(height: 28),

            // History
            if (_entries.isNotEmpty) ...[
              Row(
                children: [
                  Container(width: 4, height: 18, decoration: BoxDecoration(color: AppColors.knowledge, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  const Text('LEARNING LOG', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                ],
              ),
              const SizedBox(height: 12),
              ..._entries.asMap().entries.map((entry) {
                final e = entry.value;
                final emoji = switch (e.type) {
                  'book' => '📖',
                  'online course' => '🎓',
                  'certificate' => '🏅',
                  'research paper' => '🔬',
                  _ => '📚',
                };
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(e.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                            Text(e.type.toUpperCase(), style: const TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1)),
                          ],
                        ),
                      ),
                      Text('+${e.xpEarned} XP', style: const TextStyle(color: AppColors.xpGreen, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ).animate(delay: Duration(milliseconds: 50 * entry.key)).fadeIn(duration: 300.ms);
              }),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
