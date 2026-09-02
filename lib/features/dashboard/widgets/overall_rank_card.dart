import 'dart:io' as io;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/constants/wealth_config.dart';
import 'package:life_rank/core/constants/financial_rank_config.dart';
import 'package:life_rank/core/models/user_models.dart';
import 'package:life_rank/core/services/user_stats_service.dart';
import 'package:life_rank/features/auth/providers/auth_provider.dart';

/// Compact user profile header — wealth rank as the PRIMARY identity.
class UserProfileHeader extends StatefulWidget {
  final UserStats stats;
  final String username;
  final String? avatarUrl;
  final CurrencyMode currencyMode;
  final VoidCallback onCurrencyToggle;

  /// Net worth in IDR derived from savings transactions
  final double netWorthIdr;
  final int streakCount;
  final String? userId;

  const UserProfileHeader({
    super.key,
    required this.stats,
    required this.username,
    this.avatarUrl,
    required this.currencyMode,
    required this.onCurrencyToggle,
    required this.netWorthIdr,
    this.streakCount = 0,
    this.userId,
  });

  @override
  State<UserProfileHeader> createState() => _UserProfileHeaderState();
}

class _UserProfileHeaderState extends State<UserProfileHeader>
    with TickerProviderStateMixin {
  late AnimationController _ringCtrl;
  late AnimationController _pulseCtrl;
  bool _isUploading = false;
  // For web: store image bytes; for native: store file path
  Uint8List? _localImageBytes;
  String? _localAvatarPath;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    if (widget.userId == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null || !mounted) return;

    setState(() => _isUploading = true);

    try {
      // Preview locally before upload
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        if (mounted) setState(() => _localImageBytes = bytes);
      } else {
        if (mounted) setState(() => _localAvatarPath = picked.path);
      }

      // Upload to Supabase
      final dynamic fileArg = kIsWeb ? picked : io.File(picked.path);
      final url = await UserStatsService.uploadAvatar(widget.userId!, fileArg);
      if (url != null && mounted) {
        await context.read<AuthProvider>().refreshProfile();
      }
    } catch (e) {
      debugPrint('Avatar upload error: $e');
    }
    if (mounted) setState(() => _isUploading = false);
  }

  @override
  Widget build(BuildContext context) {
    final rankProgress = FinancialRankCalculator.calculate(widget.netWorthIdr);
    final mlRank = rankProgress.rank;

    final initials = widget.username.length >= 2
        ? widget.username.substring(0, 2).toUpperCase()
        : widget.username.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            mlRank.primaryColor.withValues(alpha: 0.12),
            AppColors.card,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: mlRank.primaryColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: mlRank.glowColor,
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Animated Avatar with Rank Ring ────────────────────────────────
          GestureDetector(
            onTap: _pickAndUploadAvatar,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating rank ring
                  AnimatedBuilder(
                    animation: _ringCtrl,
                    builder: (_, __) => CustomPaint(
                      size: const Size(64, 64),
                      painter: _RankRingPainter(
                        color: mlRank.primaryColor,
                        progress: _ringCtrl.value,
                        glowColor: mlRank.glowColor,
                      ),
                    ),
                  ),

                  // Pulse ring
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, __) => Container(
                      width: 54 + _pulseCtrl.value * 4,
                      height: 54 + _pulseCtrl.value * 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: mlRank.primaryColor.withValues(alpha: 0.15 + _pulseCtrl.value * 0.1),
                          width: 1,
                        ),
                      ),
                    ),
                  ),

                  // Avatar circle
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          mlRank.primaryColor.withValues(alpha: 0.85),
                          mlRank.primaryColor.withValues(alpha: 0.35),
                        ],
                      ),
                      border: Border.all(
                        color: mlRank.primaryColor.withValues(alpha: 0.7),
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: _buildAvatarContent(initials),
                    ),
                  ),

                  // Upload indicator
                  if (_isUploading)
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ),

                  // Camera edit icon
                  if (!_isUploading)
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: mlRank.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 14),

          // ── Name + ML RANK ────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.username,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.streakCount > 0) ...[
                      const SizedBox(width: 8),
                      _StreakBadge(count: widget.streakCount, color: mlRank.primaryColor),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            mlRank.primaryColor.withValues(alpha: 0.25),
                            mlRank.primaryColor.withValues(alpha: 0.10),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: mlRank.primaryColor.withValues(alpha: 0.5)),
                        boxShadow: [
                          BoxShadow(
                            color: mlRank.glowColor,
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(mlRank.iconAsset,
                              style: const TextStyle(fontSize: 10)),
                          const SizedBox(width: 4),
                          Text(
                            mlRank.displayName,
                            style: TextStyle(
                              color: mlRank.primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          ...List.generate(
                              rankProgress.star,
                              (_) => Text('★',
                                  style: TextStyle(
                                      color: mlRank.starColor, fontSize: 8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ── Currency toggle ────────────────────────────────────────────────
          GestureDetector(
            onTap: widget.onCurrencyToggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CurrencyPill(
                    label: 'USD',
                    active: widget.currencyMode == CurrencyMode.usd,
                    color: mlRank.primaryColor,
                  ),
                  const SizedBox(width: 2),
                  _CurrencyPill(
                    label: 'IDR',
                    active: widget.currencyMode == CurrencyMode.idr,
                    color: mlRank.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(
            begin: -0.1, end: 0, duration: 600.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildAvatarContent(String initials) {
    // Web: use bytes
    if (kIsWeb && _localImageBytes != null) {
      return Image.memory(_localImageBytes!, fit: BoxFit.cover);
    }
    // Native: use file path
    if (!kIsWeb && _localAvatarPath != null) {
      return Image.file(io.File(_localAvatarPath!), fit: BoxFit.cover);
    }
    // Remote avatar with cache-busting
    final rawUrl = widget.avatarUrl;
    if (rawUrl != null && rawUrl.isNotEmpty) {
      final cacheBustedUrl = rawUrl.contains('?')
          ? '$rawUrl&v=${DateTime.now().millisecondsSinceEpoch ~/ 60000}'
          : '$rawUrl?v=${DateTime.now().millisecondsSinceEpoch ~/ 60000}';
      return CachedNetworkImage(
        imageUrl: cacheBustedUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => _initialsWidget(initials),
        errorWidget: (_, __, ___) => _initialsWidget(initials),
      );
    }
    return _initialsWidget(initials);
  }

  Widget _initialsWidget(String initials) {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

// ── Animated Rank Ring Painter ────────────────────────────────────────────────

class _RankRingPainter extends CustomPainter {
  final Color color;
  final double progress; // 0.0–1.0 (rotation)
  final Color glowColor;

  _RankRingPainter({
    required this.color,
    required this.progress,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 2;

    // Glow ring
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(cx, cy), r, glowPaint);

    // Arc segments (dashed effect)
    final segmentPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const numSegments = 8;
    const gap = 0.08; // radians gap between segments
    final segmentLen = (2 * math.pi - numSegments * gap) / numSegments;

    for (int i = 0; i < numSegments; i++) {
      final startAngle = (progress * 2 * math.pi) + i * (segmentLen + gap);
      final opacity = (i % 2 == 0) ? 0.9 : 0.4;
      segmentPaint.color = color.withValues(alpha: opacity);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        startAngle,
        segmentLen,
        false,
        segmentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RankRingPainter old) =>
      old.progress != progress;
}

// ── Streak Badge ──────────────────────────────────────────────────────────────

class _StreakBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _StreakBadge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepOrange.withValues(alpha: 0.25),
            Colors.orange.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 3),
          Text(
            'x$count',
            style: const TextStyle(
              color: Colors.orangeAccent,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .shimmer(duration: 1200.ms, color: Colors.orange.withValues(alpha: 0.3));
  }
}

// ── Currency Pill ─────────────────────────────────────────────────────────────

class _CurrencyPill extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;

  const _CurrencyPill({
    required this.label,
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? color.withValues(alpha: 0.6) : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? color : AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
