import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/constants/wealth_config.dart';
import 'package:life_rank/shared/widgets/wealth_badge_widget.dart';

/// Result returned when user submits the net worth CRUD sheet
class NetWorthResult {
  final double amountIdr;
  final String? label;
  final bool isDelete;

  const NetWorthResult({
    required this.amountIdr,
    this.label,
    this.isDelete = false,
  });
}

/// Bottom sheet to add / update / delete current net worth (direct IDR input)
class NetWorthSheet extends StatefulWidget {
  /// Current net worth in IDR (null if no entry yet)
  final double? currentIdr;
  final CurrencyMode currencyMode;

  const NetWorthSheet({
    super.key,
    this.currentIdr,
    required this.currencyMode,
  });

  /// Show the sheet and return a [NetWorthResult] or null
  static Future<NetWorthResult?> show(
    BuildContext context, {
    double? currentIdr,
    required CurrencyMode currencyMode,
  }) {
    return showModalBottomSheet<NetWorthResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NetWorthSheet(
        currentIdr: currentIdr,
        currencyMode: currencyMode,
      ),
    );
  }

  @override
  State<NetWorthSheet> createState() => _NetWorthSheetState();
}

class _NetWorthSheetState extends State<NetWorthSheet> {
  final _ctrl = TextEditingController();
  final _labelCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late CurrencyMode _mode;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.currencyMode;
    _isEditing = widget.currentIdr != null;
    if (_isEditing) {
      // Pre-fill with existing amount in selected mode
      final val = _mode == CurrencyMode.idr
          ? widget.currentIdr!
          : widget.currentIdr! / WealthConfig.usdToIdr;
      _ctrl.text = _formatRaw(val);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  String _formatRaw(double v) {
    if (v == 0) return '';
    final formatter = NumberFormat('#,###', _mode == CurrencyMode.idr ? 'id_ID' : 'en_US');
    return formatter.format(v.round());
  }

  double _parseInput() {
    final raw = _ctrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final val = double.tryParse(raw) ?? 0;
    // Convert to IDR internally
    return _mode == CurrencyMode.idr ? val : val * WealthConfig.usdToIdr;
  }

  WealthRank _previewRank() {
    final idr = _parseInput();
    return WealthConfig.getRankFromIdr(idr);
  }

  double _previewProgress() {
    final idr = _parseInput();
    return WealthConfig.getProgressFromUsd(idr / WealthConfig.usdToIdr);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final idr = _parseInput();
    Navigator.of(context).pop(NetWorthResult(
      amountIdr: idr,
      label: _labelCtrl.text.isNotEmpty ? _labelCtrl.text : null,
    ));
  }

  void _delete() {
    Navigator.of(context).pop(const NetWorthResult(
      amountIdr: 0,
      isDelete: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final rank = _previewRank();
    final progress = _previewProgress();
    final prefix = _mode == CurrencyMode.idr ? 'Rp' : '\$';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: rank.color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: rank.glowColor,
              blurRadius: 40,
              spreadRadius: 0,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          WealthBadgeWidget(
                            financialXp: WealthConfig.idrToXp(_parseInput()),
                            size: WealthBadgeSize.small,
                            showLabel: false,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isEditing ? 'Update Net Worth' : 'Set Net Worth',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  '${rank.emoji} ${rank.name} · ${rank.subtitle}',
                                  style: TextStyle(
                                    color: rank.color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Currency toggle
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                final currentIdr = _parseInput();
                                _mode = _mode == CurrencyMode.idr
                                    ? CurrencyMode.usd
                                    : CurrencyMode.idr;
                                // Convert existing input
                                if (currentIdr > 0) {
                                  final converted = _mode == CurrencyMode.idr
                                      ? currentIdr
                                      : currentIdr / WealthConfig.usdToIdr;
                                  _ctrl.text = _formatRaw(converted);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Text(
                                _mode == CurrencyMode.idr ? 'IDR' : 'USD',
                                style: TextStyle(
                                  color: rank.color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Amount input
                      TextFormField(
                        controller: _ctrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: TextStyle(
                          color: rank.color,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        decoration: InputDecoration(
                          prefixText: '$prefix ',
                          prefixStyle: TextStyle(
                            color: rank.color.withValues(alpha: 0.6),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                          filled: true,
                          fillColor: rank.color.withValues(alpha: 0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: rank.color.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: rank.color.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: rank.color, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 18,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Masukkan jumlah net worth kamu';
                          }
                          final parsed = double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
                          if (parsed == null || parsed <= 0) return 'Jumlah harus lebih dari 0';
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      // Progress preview
                      _ProgressPreview(
                        progress: progress,
                        rank: rank,
                        currentIdr: _parseInput(),
                        currencyMode: _mode,
                      ),

                      const SizedBox(height: 16),

                      // Label/note field
                      TextFormField(
                        controller: _labelCtrl,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Catatan (opsional)',
                          hintText: 'misal: Tabungan + Saham Q2 2026',
                          prefixIcon: const Icon(Icons.edit_note_rounded,
                              color: AppColors.textMuted, size: 20),
                          labelStyle:
                              const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          hintStyle:
                              const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.cardBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: rank.color, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          if (_isEditing) ...[
                            GestureDetector(
                              onTap: _delete,
                              child: Container(
                                width: 48,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.danger.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.danger,
                                  size: 20,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: rank.color,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _isEditing
                                          ? Icons.check_circle_rounded
                                          : Icons.add_circle_rounded,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isEditing ? 'UPDATE NET WORTH' : 'SIMPAN NET WORTH',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().slideY(begin: 0.3, end: 0, duration: 350.ms, curve: Curves.easeOutCubic),
    );
  }
}

class _ProgressPreview extends StatelessWidget {
  final double progress;
  final WealthRank rank;
  final double currentIdr;
  final CurrencyMode currencyMode;

  const _ProgressPreview({
    required this.progress,
    required this.rank,
    required this.currentIdr,
    required this.currencyMode,
  });

  @override
  Widget build(BuildContext context) {
    final next = WealthConfig.getNextRankFromUsd(currentIdr / WealthConfig.usdToIdr);
    final targetStr = next != null
        ? WealthConfig.formatAmount(next.minUSD, currencyMode)
        : 'MAX RANK';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: rank.color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rank.color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress ke ${next?.name ?? 'Max'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '→ $targetStr',
                style: TextStyle(
                  color: rank.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  color: AppColors.cardBorder,
                ),
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.02, 1.0),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [rank.color.withValues(alpha: 0.7), rank.color],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: rank.glowColor,
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                color: rank.color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
