import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/models/gacha_reward_model.dart';
import 'package:life_rank/features/auth/providers/auth_provider.dart';
import 'package:life_rank/features/cashflow/providers/gacha_provider.dart';

class GachaModal extends StatefulWidget {
  const GachaModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => const GachaModal(),
    );
  }

  @override
  State<GachaModal> createState() => _GachaModalState();
}

class _GachaModalState extends State<GachaModal>
    with SingleTickerProviderStateMixin {
  bool _isRolling = false;
  bool _hasResult = false;
  bool _showRates = false;
  GachaReward? _result;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> _roll() async {
    final provider = context.read<GachaProvider>();
    final auth = context.read<AuthProvider>();
    if (provider.tickets <= 0) return;

    setState(() {
      _isRolling = true;
      _hasResult = false;
      _result = null;
    });

    _result = await provider.rollGacha(auth);
    await Future.delayed(const Duration(milliseconds: 2200));

    if (mounted) {
      setState(() {
        _isRolling = false;
        _hasResult = true;
      });
    }
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'Legendary': return AppColors.gold;
      case 'Epic':      return AppColors.rankGrandmaster;
      case 'Rare':      return AppColors.info;
      case 'Uncommon':  return AppColors.xpGreen;
      default:          return AppColors.textMuted;
    }
  }

  String _getRarityEmoji(String rarity) {
    switch (rarity) {
      case 'Legendary': return '👑';
      case 'Epic':      return '💎';
      case 'Rare':      return '🔷';
      case 'Uncommon':  return '🟢';
      default:          return '⬜';
    }
  }


  String _getRewardDescription(String name) {
    switch (name) {
      case 'Bronze Pouch':    return 'A small XP boost. Good start!';
      case 'Mini Self Reward':return 'Treat yourself to something small — you earned it 🎉';
      case 'Silver Chest':    return 'A solid reward with a nice XP bonus!';
      case 'Golden Vault':    return 'Big XP haul — your finances are leveling up!';
      case 'Mythic Crystal':  return 'Massive XP surge — legendary financial warrior! 🏆';
      default:                return 'A mystery reward awaits!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GachaProvider>();
    final borderColor = _hasResult && _result != null
        ? _getRarityColor(_result!.rarity)
        : AppColors.cardBorder;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: _hasResult && _result != null
              ? [BoxShadow(
                  color: borderColor.withValues(alpha: 0.4),
                  blurRadius: 32,
                  spreadRadius: 4,
                )]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Lucky Box',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Ticket counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.confirmation_number_rounded,
                      color: AppColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '${provider.tickets} ticket${provider.tickets != 1 ? 's' : ''} remaining',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // How to earn
            const Text(
              'Earn 1 ticket every 3 days of streak',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 24),

            // ── Box / Result Area ─────────────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 180),
                child: Center(child: _buildBoxContent()),
              ),
            ),

            const SizedBox(height: 24),

            // ── Action Button ─────────────────────────────────────────────────
            if (!_isRolling && !_hasResult) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: provider.tickets > 0 ? _roll : null,
                  icon: const Icon(Icons.lock_open_rounded, size: 18),
                  label: Text(
                    provider.tickets > 0
                        ? 'Open Lucky Box  (1 Ticket)'
                        : 'No Tickets — Keep Your Streak!',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: provider.tickets > 0
                        ? AppColors.primary
                        : AppColors.cardBorder,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.cardBorder,
                    disabledForegroundColor: AppColors.textMuted,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle drop rates
              GestureDetector(
                onTap: () => setState(() => _showRates = !_showRates),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _showRates ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showRates ? 'Hide drop rates' : 'View drop rates',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),

              if (_showRates) ...[
                const SizedBox(height: 12),
                _buildDropRateTable(provider),
              ],
            ],

            if (_hasResult) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text(
                    'Awesome, Thanks!',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _result != null
                        ? _getRarityColor(_result!.rarity)
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              if (provider.tickets > 0) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasResult = false;
                        _result = null;
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      'Open Again  (${provider.tickets} left)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    ).animate().scaleXY(curve: Curves.easeOutBack, duration: 400.ms);
  }

  Widget _buildBoxContent() {
    if (_isRolling) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_rounded, size: 90, color: AppColors.primary)
              .animate(onPlay: (c) => c.repeat())
              .scaleXY(begin: 1.0, end: 1.15, duration: 400.ms, curve: Curves.easeInOut)
              .then()
              .scaleXY(begin: 1.15, end: 1.0, duration: 400.ms),
          const SizedBox(height: 20),
          const Text(
            'Opening your box...',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 600.ms),
        ],
      );
    }

    if (_hasResult && _result != null) {
      final rarityColor = _getRarityColor(_result!.rarity);
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Rarity badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: rarityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: rarityColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              '${_getRarityEmoji(_result!.rarity)}  ${_result!.rarity.toUpperCase()}',
              style: TextStyle(
                color: rarityColor,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ).animate().fadeIn().slideY(begin: -0.5),
          const SizedBox(height: 16),

          // Big icon
          Icon(
            Icons.stars_rounded,
            size: 72,
            color: rarityColor,
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.18, duration: 900.ms)
              .shimmer(duration: 1200.ms, color: Colors.white54),
          const SizedBox(height: 14),

          // Reward name
          Text(
            _result!.rewardName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.4),
          const SizedBox(height: 6),

          // Description
          Text(
            _getRewardDescription(_result!.rewardName),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ).animate().fadeIn(delay: 250.ms),
          const SizedBox(height: 12),

          // XP reward
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.xpGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: AppColors.xpGreen, size: 18),
                const SizedBox(width: 4),
                Text(
                  '+${_result!.xpReward} Financial XP',
                  style: const TextStyle(
                    color: AppColors.xpGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 350.ms).scaleXY(begin: 0.8),

          // Motivation quote
          if (_result!.motivation != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                '"${_result!.motivation!}"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ).animate().fadeIn(delay: 500.ms),
          ],
        ],
      );
    }

    // Default idle state
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.inventory_2_rounded, size: 90, color: AppColors.textMuted)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: -6, end: 6, duration: 1200.ms, curve: Curves.easeInOut),
        const SizedBox(height: 20),
        const Text(
          "What's inside? Tap to find out!",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDropRateTable(GachaProvider provider) {
    // Normalise rates
    final int total = provider.pool.fold(0, (s, r) => s + r.dropRate);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DROP RATES',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          ...provider.pool.map((reward) {
            final pct = (reward.dropRate / total * 100).toStringAsFixed(0);
            final color = _getRarityColor(reward.rarity);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Text(_getRarityEmoji(reward.rarity),
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              reward.rewardName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '$pct%  •  +${reward.xpReward} XP',
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: reward.dropRate / total,
                            backgroundColor: AppColors.cardBorder,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                color.withValues(alpha: 0.7)),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1);
  }
}
