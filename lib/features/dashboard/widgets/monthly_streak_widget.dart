import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_rank/core/constants/app_colors.dart';

/// Monthly streak widget — calendar-style grid showing which days had transactions.
/// [activeDays] is a Set of day numbers (1–31) that had at least one transaction.
class MonthlyStreakWidget extends StatelessWidget {
  final Set<int> activeDays;
  final Color accentColor;

  const MonthlyStreakWidget({
    super.key,
    required this.activeDays,
    this.accentColor = AppColors.habit,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final firstWeekday = DateTime(
      now.year,
      now.month,
      1,
    ).weekday; // 1=Mon..7=Sun
    final streakCount = activeDays.length;
    final monthName = () {
      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${months[now.month - 1]} ${now.year}';
    }();

    // Calculate longest consecutive streak
    int longestStreak = 0;
    int currentStreak = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      if (activeDays.contains(d)) {
        currentStreak++;
        if (currentStreak > longestStreak) longestStreak = currentStreak;
      } else {
        currentStreak = 0;
      }
    }

    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.06),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.local_fire_department_rounded,
                      color: accentColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'STREAK BULANAN',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: streakCount > 0
                              ? Colors.red.withValues(alpha: 0.15)
                              : accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: streakCount > 0
                                ? Colors.orange.withValues(alpha: 0.5)
                                : accentColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (streakCount > 0) ...[
                              const Text('🔥', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              streakCount > 0
                                  ? 'x$streakCount aktif'
                                  : '$streakCount hari aktif',
                              style: TextStyle(
                                color: streakCount > 0
                                    ? Colors.orangeAccent
                                    : accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate(target: streakCount > 0 ? 1.0 : 0.0)
                      .shimmer(
                        duration: 1200.ms,
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                ],
              ),

              const SizedBox(height: 4),

              Text(
                monthName,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: 16),

              // Stats row
              Row(
                children: [
                  _StatChip(
                    label: 'Hari Aktif',
                    value: '$streakCount',
                    color: accentColor,
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    label: 'Streak Terpanjang',
                    value: '$longestStreak hari',
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 10),
                  _StatChip(
                    label: 'Total Hari',
                    value: '$daysInMonth',
                    color: AppColors.textSecondary,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Day-of-week header
              Row(
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                    .map(
                      (d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 6),

              // Calendar grid
              _buildCalendarGrid(daysInMonth, firstWeekday, now.day),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms, delay: 400.ms)
        .slideY(
          begin: 0.15,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildCalendarGrid(int daysInMonth, int firstWeekday, int today) {
    final offset = firstWeekday % 7;
    final cells = <Widget>[];

    for (int i = 0; i < offset; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final isActive = activeDays.contains(day);
      final isToday = day == today;
      final isFuture = day > today;

      cells.add(
        _DayCell(
          day: day,
          isActive: isActive,
          isToday: isToday,
          isFuture: isFuture,
          accentColor: accentColor,
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }
}

// ── Animated Day Cell ─────────────────────────────────────────────────────────

class _DayCell extends StatefulWidget {
  final int day;
  final bool isActive;
  final bool isToday;
  final bool isFuture;
  final Color accentColor;

  const _DayCell({
    required this.day,
    required this.isActive,
    required this.isToday,
    required this.isFuture,
    required this.accentColor,
  });

  @override
  State<_DayCell> createState() => _DayCellState();
}

class _DayCellState extends State<_DayCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.isToday || widget.isActive) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, _) {
        final glowOpacity = widget.isActive
            ? 0.3 + _pulseCtrl.value * 0.3
            : 0.0;
        final bgOpacity = widget.isActive ? 0.7 + _pulseCtrl.value * 0.15 : 0.0;

        return Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isActive
                ? widget.accentColor.withValues(alpha: bgOpacity)
                : widget.isFuture
                ? Colors.transparent
                : AppColors.surface.withValues(alpha: 0.5),
            border: widget.isToday
                ? Border.all(
                    color: widget.accentColor.withValues(
                      alpha: 0.6 + _pulseCtrl.value * 0.4,
                    ),
                    width: 1.5,
                  )
                : null,
            boxShadow: widget.isActive
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: glowOpacity),
                      blurRadius: 6 + _pulseCtrl.value * 4,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              '${widget.day}',
              style: TextStyle(
                color: widget.isActive
                    ? Colors.white
                    : widget.isFuture
                    ? AppColors.textMuted.withValues(alpha: 0.3)
                    : AppColors.textMuted.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: widget.isActive || widget.isToday
                    ? FontWeight.w800
                    : FontWeight.w400,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
