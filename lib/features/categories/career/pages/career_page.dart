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

class CareerPage extends StatefulWidget {
  const CareerPage({super.key});

  @override
  State<CareerPage> createState() => _CareerPageState();
}

class _CareerPageState extends State<CareerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _selectedSkill;
  String? _selectedProject;
  final _customTitleCtrl = TextEditingController();
  bool _isLoading = false;
  List<CareerEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadEntries();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _customTitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;
    final entries = await UserStatsService.getCareerEntries(auth.supabaseUser!.id);
    if (mounted) setState(() => _entries = entries);
  }

  Future<void> _addEntry(String type, String title, int xp) async {
    if (title.isEmpty) return;
    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;
    final userId = auth.supabaseUser!.id;

    setState(() => _isLoading = true);

    try {
      final entry = CareerEntry(
        id: '',
        userId: userId,
        type: type,
        title: title,
        xpEarned: xp,
        addedAt: DateTime.now(),
      );
      await UserStatsService.addCareerEntry(entry);
      final prevStats = auth.stats;
      final newStats = await UserStatsService.updateCategoryXp(userId, 'career', xp);
      if (newStats != null) {
        await auth.updateStats(newStats);
        if (prevStats != null && mounted) {
          final prevRank = RankConfig.getRankInfo(prevStats.totalXp).name;
          final newRankName = RankConfig.getRankInfo(newStats.totalXp).name;
          if (prevRank != newRankName) {
            final rankInfo = RankConfig.getRankInfo(newStats.totalXp);
            RankUpCelebration.show(context, newRank: rankInfo.name, emoji: rankInfo.emoji, rankColor: rankInfo.color);
          } else {
            AchievementPopup.show(context, title: 'Career Updated!', description: '$title added.', xpReward: xp);
          }
        }
      }
      await _loadEntries();
      if (mounted) {
        setState(() {
          _selectedSkill = null;
          _selectedProject = null;
          _customTitleCtrl.clear();
        });
      }
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
    final careerXp = auth.stats?.careerXp ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('💼 Career'),
        backgroundColor: AppColors.background,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.career,
          labelColor: AppColors.career,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'ADD ENTRY'),
            Tab(text: 'MY JOURNEY'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Status card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.career.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  RankBadgeWidget(xp: careerXp, size: RankBadgeSize.small, showLabel: false),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AnimatedXpBar(currentXp: careerXp, color: AppColors.career),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // Tab 1: Add Entry
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Skills section
                      _sectionTitle('🎯 Add Skill', AppColors.career),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: RankConfig.skillXp.entries.map((e) {
                          final isSelected = _selectedSkill == e.key;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedSkill = isSelected ? null : e.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.career.withValues(alpha: 0.2) : AppColors.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppColors.career : AppColors.cardBorder,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    e.key,
                                    style: TextStyle(
                                      color: isSelected ? AppColors.career : AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '+${e.value}',
                                    style: TextStyle(
                                      color: isSelected ? AppColors.xpGreen : AppColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      if (_selectedSkill != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _addEntry('skill', _selectedSkill!, RankConfig.skillXp[_selectedSkill!]!),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.career),
                              child: Text(
                                'ADD $_selectedSkill (+${RankConfig.skillXp[_selectedSkill!]} XP)',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Projects section
                      _sectionTitle('🚀 Add Project', AppColors.career),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: RankConfig.projectXp.entries.map((e) {
                          final isSelected = _selectedProject == e.key;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedProject = isSelected ? null : e.key),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    e.key,
                                    style: TextStyle(
                                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '+${e.value}',
                                    style: TextStyle(
                                      color: isSelected ? AppColors.xpGreen : AppColors.textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      if (_selectedProject != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextFormField(
                            controller: _customTitleCtrl,
                            style: const TextStyle(color: AppColors.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Project Name',
                              hintText: 'Enter your project name...',
                              prefixIcon: Icon(Icons.folder_outlined, color: AppColors.textMuted),
                            ),
                          ),
                        ),

                      if (_selectedProject != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () => _addEntry(
                                        'project',
                                        _customTitleCtrl.text.isEmpty ? _selectedProject! : _customTitleCtrl.text,
                                        RankConfig.projectXp[_selectedProject!]!,
                                      ),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: Text(
                                'ADD PROJECT (+${RankConfig.projectXp[_selectedProject!]} XP)',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),

                // Tab 2: Journey History
                _entries.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('💼', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 12),
                            Text('No career entries yet', style: TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _entries.length,
                        itemBuilder: (ctx, i) {
                          final e = _entries[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  e.type == 'skill' ? '🎯' : '🚀',
                                  style: const TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                                      Text(e.type.toUpperCase(), style: const TextStyle(color: AppColors.textMuted, fontSize: 11, letterSpacing: 1)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.xpGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('+${e.xpEarned} XP', style: const TextStyle(color: AppColors.xpGreen, fontWeight: FontWeight.w700, fontSize: 12)),
                                ),
                              ],
                            ),
                          ).animate(delay: Duration(milliseconds: 50 * i)).fadeIn(duration: 300.ms);
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
      ],
    );
  }
}
