import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/models/fixed_bill_model.dart';
import 'package:life_rank/features/auth/providers/auth_provider.dart';
import 'package:life_rank/features/cashflow/providers/boss_battle_provider.dart';

class BossBattleCard extends StatelessWidget {
  final FixedBill boss;

  const BossBattleCard({super.key, required this.boss});

  @override
  Widget build(BuildContext context) {
    final bool isOverdue = boss.status == 'overdue';
    final bool isDefeated = boss.status == 'defeated';
    final formatter = NumberFormat('#,###', 'id_ID');

    // Calculate days remaining
    final now = DateTime.now();
    final difference = boss.dueDate.difference(now).inDays;
    
    String timerText;
    if (isDefeated) {
      timerText = 'DEFEATED';
    } else if (isOverdue) {
      timerText = 'ATTACKING YOU!';
    } else {
      timerText = difference == 0 ? 'HARI INI' : '$difference HARI LAGI';
    }

    // Colors
    final Color mainColor = isDefeated
        ? AppColors.textMuted
        : (isOverdue ? AppColors.danger : Colors.orangeAccent);
        
    final Color bgColor = AppColors.card;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue ? mainColor.withValues(alpha: 0.5) : AppColors.cardBorder,
          width: isOverdue ? 2 : 1,
        ),
        boxShadow: isOverdue
            ? [
                BoxShadow(
                  color: mainColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 1,
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isDefeated
                          ? Icons.check_circle_outline
                          : (isOverdue ? Icons.warning_amber_rounded : Icons.calendar_today_rounded),
                      color: mainColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'BOSS BATTLE',
                      style: TextStyle(
                        color: mainColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                Text(
                  timerText,
                  style: TextStyle(
                    color: mainColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Boss Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: mainColor.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      isDefeated 
                        ? '💀' 
                        : (boss.bossIcon ?? (isOverdue ? '👹' : '👾')),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        boss.bossName ?? boss.name,
                        style: TextStyle(
                          color: isDefeated ? AppColors.textMuted : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          decoration: isDefeated ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (boss.bossName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          boss.name,
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            decoration: isDefeated ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'HP: Rp ${formatter.format(boss.amount)}',
                        style: TextStyle(
                          color: isDefeated ? AppColors.textMuted : Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!isDefeated && boss.bossTaunt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '"${boss.bossTaunt!}"',
                          style: TextStyle(
                            color: isOverdue ? AppColors.danger : AppColors.textSecondary,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ).animate(onPlay: (c) => isOverdue ? c.repeat(reverse: true) : null)
                         .shake(duration: 1.seconds, hz: isOverdue ? 2 : 0),
                      ],
                    ],
                  ),
                ),
                // Action Button
                if (!isDefeated)
                  GestureDetector(
                    onTap: () {
                      final provider = context.read<BossBattleProvider>();
                      final auth = context.read<AuthProvider>();
                      provider.defeatBoss(boss, auth);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Boss Defeated! +150 Financial XP 🔥'),
                          backgroundColor: AppColors.xpGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            mainColor.withValues(alpha: 0.8),
                            mainColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: mainColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: const Text(
                        'SERANG',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ).animate(onPlay: (c) => isOverdue ? c.repeat(reverse: true) : null)
                   .scaleXY(begin: 1.0, end: 1.05, duration: 600.ms),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
