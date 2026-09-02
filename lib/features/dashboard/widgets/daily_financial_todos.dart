import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:life_rank/core/constants/app_colors.dart';

import 'package:life_rank/core/models/category_models.dart';

/// Daily financial todo list with motivational quotes + custom todo support
class DailyFinancialTodos extends StatefulWidget {
  final List<FinancialTodo> todos;
  final Set<String> highlightedIds;
  final void Function(FinancialTodo todo) onComplete;
  final void Function(FinancialTodo todo) onDelete;
  final void Function(String title) onAddCustom;

  const DailyFinancialTodos({
    super.key,
    required this.todos,
    this.highlightedIds = const {},
    required this.onComplete,
    required this.onDelete,
    required this.onAddCustom,
  });

  @override
  State<DailyFinancialTodos> createState() => _DailyFinancialTodosState();
}

class _DailyFinancialTodosState extends State<DailyFinancialTodos> {
  bool _showAddField = false;
  final _addCtrl = TextEditingController();
  late ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(duration: const Duration(milliseconds: 1200));
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  void _submitCustom() {
    final title = _addCtrl.text.trim();
    if (title.isEmpty) return;
    widget.onAddCustom(title);
    _addCtrl.clear();
    setState(() => _showAddField = false);
  }

  void _completeTodoWithEffect(FinancialTodo todo) {
    _confettiCtrl.play();
    widget.onComplete(todo);
  }

  int get _completed => widget.todos.where((t) => t.completed).length;
  int get _total => widget.todos.length;
  int get _totalPoints =>
      widget.todos.where((t) => t.completed).fold(0, (s, t) => s + t.points);

  @override
  Widget build(BuildContext context) {
    final completedCount = _completed;
    final totalCount = _total;
    final progressPct = totalCount == 0 ? 0.0 : completedCount / totalCount;

    // Daily motivational quote
    final quotes = [
      'Kekayaan bukan tentang seberapa banyak yang kamu punya, tapi seberapa sedikit yang kamu butuhkan. 🌿',
      '"Do not save what is left after spending, spend what is left after saving." — Warren Buffett 💡',
      'Setiap Rp 1.000 yang kamu tabung hari ini adalah kebebasan masa depan. 🚀',
      'Investor terbaik adalah yang bisa tidur nyenyak meski pasar turun. 😴',
      'Kemewahan sejati adalah tidak perlu melihat harga sebelum membeli sesuatu yang kamu butuhkan. 👑',
    ];
    final quoteIdx = DateTime.now().day % quotes.length;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Overall Mission Progress Bar ──────────────────────────────────
        _MissionProgressBar(
          completed: completedCount,
          total: totalCount,
          progress: progressPct,
        ),

        const SizedBox(height: 16),

        // Motivational quote card
        _MotivationCard(quote: quotes[quoteIdx]),

        const SizedBox(height: 20),

        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.financial,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'MISI HARIAN',
                  style: TextStyle(
                    color: AppColors.financial,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // Points earned badge
                if (_totalPoints > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.xpGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.xpGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded,
                            color: AppColors.xpGreen, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          '+$_totalPoints pts',
                          style: const TextStyle(
                            color: AppColors.xpGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Progress badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.financial.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.financial.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '$_completed/$_total',
                    style: const TextStyle(
                      color: AppColors.financial,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

        const SizedBox(height: 12),

        // Todo items
        ...widget.todos.asMap().entries.map((entry) {
          final idx = entry.key;
          final todo = entry.value;
          final isHighlighted = widget.highlightedIds.contains(todo.id);
          return _TodoTile(
            todo: todo,
            index: idx,
            isHighlighted: isHighlighted,
            onComplete: () => _completeTodoWithEffect(todo),
            onDelete: todo.isCustom ? () => widget.onDelete(todo) : null,
          );
        }),

        const SizedBox(height: 10),

        // Add custom todo
        if (_showAddField)
          _AddTodoField(
            controller: _addCtrl,
            onSubmit: _submitCustom,
            onCancel: () {
              _addCtrl.clear();
              setState(() => _showAddField = false);
            },
          ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0)
        else
          GestureDetector(
            onTap: () => setState(() => _showAddField = true),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.financial.withValues(alpha: 0.3),
                  // Dashed effect via border width trick
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.financial.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: AppColors.financial, size: 16),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tambah misi kustom...',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
      ],
        ),
        // Confetti launcher at the top center
        Positioned(
          top: 60,
          child: ConfettiWidget(
            confettiController: _confettiCtrl,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              AppColors.xpGreen,
              AppColors.gold,
              AppColors.financial,
              AppColors.primary,
              Colors.orangeAccent,
              Colors.cyanAccent,
            ],
            numberOfParticles: 24,
            gravity: 0.3,
            emissionFrequency: 0.05,
            maxBlastForce: 40,
            minBlastForce: 15,
          ),
        ),
      ],
    );
  }
}

// ── Mission Progress Bar ───────────────────────────────────────────────────────

class _MissionProgressBar extends StatelessWidget {
  final int completed;
  final int total;
  final double progress;

  const _MissionProgressBar({
    required this.completed,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isAllDone = completed == total && total > 0;
    final color = isAllDone ? AppColors.gold : AppColors.financial;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: isAllDone ? 0.5 : 0.25)),
        boxShadow: [
          if (isAllDone)
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 0,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    isAllDone ? '🏆' : '⚔️',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isAllDone ? 'SEMUA MISI SELESAI!' : 'PROGRESS MISI HARI INI',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Text(
                '$completed/$total',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  color: AppColors.cardBorder,
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: isAllDone
                            ? [AppColors.gold, Colors.orange]
                            : [AppColors.financial, AppColors.xpGreen],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .slideX(begin: -1, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0, duration: 400.ms);
  }
}

class _MotivationCard extends StatelessWidget {
  final String quote;

  const _MotivationCard({required this.quote});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.wealthMaster.withValues(alpha: 0.1),
            AppColors.wealthElite.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.wealthMaster.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💡',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MOTIVASI HARI INI',
                  style: TextStyle(
                    color: AppColors.wealthMaster.withValues(alpha: 0.7),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  quote,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.05, end: 0);
  }
}

class _TodoTile extends StatelessWidget {
  final FinancialTodo todo;
  final int index;
  final bool isHighlighted;
  final VoidCallback onComplete;
  final VoidCallback? onDelete;

  const _TodoTile({
    required this.todo,
    required this.index,
    this.isHighlighted = false,
    required this.onComplete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = todo.completed
        ? AppColors.xpGreen
        : isHighlighted
            ? AppColors.gold
            : AppColors.financial;

    return Dismissible(
      key: Key(todo.id),
      direction:
          todo.isCustom ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.danger, size: 22),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: todo.completed
              ? AppColors.xpGreen.withValues(alpha: 0.05)
              : isHighlighted
                  ? AppColors.gold.withValues(alpha: 0.03)
                  : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: todo.completed
                ? AppColors.xpGreen.withValues(alpha: 0.3)
                : isHighlighted
                    ? AppColors.gold.withValues(alpha: 0.4)
                    : AppColors.cardBorder,
            width: isHighlighted && !todo.completed ? 1.5 : 1.0,
          ),
          boxShadow: isHighlighted && !todo.completed
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.04),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: todo.completed ? null : onComplete,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: todo.completed ? AppColors.xpGreen : Colors.transparent,
                  border: Border.all(
                    color: todo.completed
                        ? AppColors.xpGreen
                        : isHighlighted
                            ? AppColors.gold.withValues(alpha: 0.7)
                            : AppColors.textMuted,
                    width: 2,
                  ),
                ),
                child: todo.completed
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
                    : null,
              ),
            ),

            const SizedBox(width: 12),

            // Icon + text
            Text(todo.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (isHighlighted && !todo.completed) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                          ),
                          child: const Text(
                            'UTAMA',
                            style: TextStyle(
                              color: AppColors.gold,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          todo.title,
                          style: TextStyle(
                            color: todo.completed
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            decoration:
                                todo.completed ? TextDecoration.lineThrough : null,
                            decorationColor: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!todo.isCustom && !todo.completed)
                    Text(
                      todo.desc,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Points badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Text(
                isHighlighted ? '+${todo.points * 2}' : '+${todo.points}',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 60 * index))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1, end: 0, duration: 400.ms);
  }
}

class _AddTodoField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _AddTodoField({
    required this.controller,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.financial.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.financial.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flag_outlined,
                color: AppColors.financial, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              decoration: const InputDecoration(
                hintText: 'Tulis misi kustom...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: const Icon(Icons.close_rounded,
                color: AppColors.textMuted, size: 18),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onSubmit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.financial,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
