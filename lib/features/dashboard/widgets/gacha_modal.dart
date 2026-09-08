import 'dart:async';
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
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => const GachaModal(),
    );
  }

  @override
  State<GachaModal> createState() => _GachaModalState();
}

class _GachaModalState extends State<GachaModal> {
  bool _isRolling = false;
  bool _hasResult = false;
  GachaReward? _result;

  void _roll() async {
    final provider = context.read<GachaProvider>();
    final auth = context.read<AuthProvider>();

    if (provider.tickets <= 0) return;

    setState(() {
      _isRolling = true;
      _hasResult = false;
    });

    // Determine result immediately but delay UI
    _result = await provider.rollGacha(auth);

    // Simulate suspense
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      setState(() {
        _isRolling = false;
        _hasResult = true;
      });
    }
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'Legendary':
        return AppColors.gold;
      case 'Epic':
        return AppColors.rankGrandmaster; // purple-ish
      case 'Rare':
        return AppColors.info; // blue
      default:
        return AppColors.textMuted; // gray
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GachaProvider>();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _hasResult && _result != null
                ? _getRarityColor(_result!.rarity)
                : AppColors.cardBorder,
            width: 2,
          ),
          boxShadow: _hasResult && _result != null
              ? [
                  BoxShadow(
                    color: _getRarityColor(_result!.rarity).withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            const Text(
              'FINANCIAL LOOT BOX',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gacha Tickets: ${provider.tickets}',
              style: TextStyle(
                color: AppColors.xpGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 32),

            // Box / Result Area
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 180),
                child: Center(
                  child: _buildBoxContent(),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action Button
            if (!_isRolling && !_hasResult)
              ElevatedButton(
                onPressed: provider.tickets > 0 ? _roll : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('OPEN BOX (1 Ticket)', style: TextStyle(fontWeight: FontWeight.w800)),
              ),

            if (_hasResult)
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('CLAIM REWARD', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
          ],
        ),
      ),
    ).animate().scaleXY(curve: Curves.easeOutBack, duration: 400.ms);
  }

  Widget _buildBoxContent() {
    if (_hasResult && _result != null) {
      // Result State
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars_rounded,
            size: 80,
            color: _getRarityColor(_result!.rarity),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.2, duration: 1.seconds)
              .shimmer(duration: 1.seconds, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            _result!.rarity.toUpperCase(),
            style: TextStyle(
              color: _getRarityColor(_result!.rarity),
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ).animate().fadeIn().slideY(begin: 0.5),
          const SizedBox(height: 4),
          Text(
            _result!.rewardName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.5),
          const SizedBox(height: 8),
          Text(
            '+${_result!.xpReward} Financial XP',
            style: const TextStyle(
              color: AppColors.xpGreen,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(delay: 400.ms).scaleXY(),
          if (_result!.motivation != null) ...[
            const SizedBox(height: 12),
            Text(
              '"${_result!.motivation!}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ).animate().fadeIn(delay: 600.ms),
          ],
        ],
      );
    }

    // Default / Rolling state (Chest Icon)
    Widget chest = const Icon(
      Icons.inventory_rounded,
      size: 100,
      color: Colors.white70,
    );

    if (_isRolling) {
      chest = chest
          .animate(onPlay: (c) => c.repeat())
          .rotate(duration: 500.ms)
          .then(delay: 1500.ms)
          .scaleXY(end: 1.5, duration: 200.ms)
          .fadeOut(duration: 200.ms);
    } else {
      chest = chest
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(begin: -5, end: 5, duration: 1000.ms);
    }

    return chest;
  }
}
