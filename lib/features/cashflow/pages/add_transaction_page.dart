import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/models/category_models.dart';
import 'package:life_rank/core/models/receipt_item_model.dart';
import 'package:life_rank/core/services/receipt_parser_service.dart';
import 'package:life_rank/core/services/user_stats_service.dart';
import 'package:life_rank/features/auth/providers/auth_provider.dart';
import 'package:life_rank/features/cashflow/providers/gacha_provider.dart';
import 'package:life_rank/features/cashflow/widgets/receipt_items_sheet.dart';
// Using AI for parsing instead of ML Kit

class AddTransactionPage extends StatefulWidget {
  const AddTransactionPage({super.key});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _type = 'expense';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;
  bool _isScanning = false;

  Uint8List? _scannedBytes;  // Cross-platform image bytes
  String? _scanResult;

  late AnimationController _pulseController;

  static const _typeOptions = [
    _TxType('income', '💵', 'Pemasukan', AppColors.xpGreen),
    _TxType('expense', '💸', 'Pengeluaran', AppColors.danger),
    _TxType('saving', '🏦', 'Tabungan', AppColors.primary),
    _TxType('investment', '📈', 'Investasi', AppColors.financial),
  ];

  static const _expenseCategories = [
    'Makanan', 'Transport', 'Belanja', 'Kesehatan',
    'Hiburan', 'Tagihan', 'Cicilan', 'Dana Darurat',
    'Investasi', 'Bisnis',
  ];

  static const _incomeCategories = [
    'Gaji', 'Freelance', 'Bonus', 'Investasi', 'Lainnya',
  ];

  _TxType get _selected =>
      _typeOptions.firstWhere((t) => t.value == _type);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _notesCtrl.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── SCAN / UPLOAD GAMBAR NOTA ─────────────────────────────────────────────

  Future<void> _showScanSourcePicker() async {
    // Di web: langsung buka file picker (tidak ada kamera native)
    if (kIsWeb) {
      await _pickAndScan(ImageSource.gallery);
      return;
    }

    // Di mobile: tampilkan pilihan kamera vs gallery
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Scan Nota dari',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Foto atau upload gambar struk / nota belanja',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _ScanSourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Kamera',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickAndScan(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ScanSourceButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      color: AppColors.financial,
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickAndScan(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndScan(ImageSource source) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (xFile == null) return;

    final bytes = await xFile.readAsBytes();

    setState(() {
      _isScanning = true;
      _scannedBytes = bytes;
      _scanResult = null;
    });



    try {
      // ── Parse item-item dari struk menggunakan AI ────────────────────────────────
      final result = await ReceiptParserService.parseWithAI(bytes);

      setState(() {
        _isScanning = false;
        _scanResult = result.hasItems
            ? 'Scan berhasil ✓ — ${result.items.length} item ditemukan'
            : 'Scan berhasil ✓ — Tidak ada item, isi manual';
      });

      if (result.hasItems && mounted) {
        HapticFeedback.mediumImpact();
        // Tampilkan bottom sheet konfirmasi item
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ReceiptItemsSheet(
            parseResult: result,
            transactionDate: _selectedDate,
            onSave: _saveItemsFromReceipt,
          ),
        );
      } else {
        // Fallback: karena AI selalu mengembalikan total jika ada, kita langsung populate
        if (result.grandTotal != null && _amountCtrl.text.isEmpty) {
          _amountCtrl.text = result.grandTotal!.toStringAsFixed(0);
        }
        if (_categoryCtrl.text.isEmpty && result.merchant != null) {
          _categoryCtrl.text = result.suggestedCategory;
          if (_type != 'expense') setState(() => _type = 'expense');
        }
      }
    } catch (e) {
      setState(() {
        _isScanning = false;
        _scanResult = 'Gagal scan: ${e.toString()}';
      });
    }
  }



  /// Simpan semua item yang dipilih dari ReceiptItemsSheet sebagai transaksi grup struk terstruktur.
  Future<void> _saveItemsFromReceipt(
    List<ReceiptItem> items,
    String category,
    DateTime date,
    String merchant,
  ) async {
    if (items.isEmpty) return;

    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;

    setState(() => _isSaving = true);

    try {
      final totalAmount = items.fold<double>(0.0, (sum, i) => sum + i.effectiveTotal);
      final finalMerchant = merchant.trim().isNotEmpty ? merchant.trim() : 'Struk Belanja';
      final receiptGroup = ReceiptGroupData(
        merchant: finalMerchant,
        items: items,
      );

      final tx = TransactionModel(
        id: '',
        userId: auth.supabaseUser!.id,
        type: 'expense',
        amount: totalAmount,
        date: date,
        category: category,
        incomeType: null,
        note: receiptGroup.toEncodedNote(),
      );
      await UserStatsService.addTransaction(tx);

      await auth.refreshStats();

      // Award gacha streak
      if (mounted) {
        final gacha = context.read<GachaProvider>();
        final activeDays = await UserStatsService.getMonthlyActivedays(
          auth.supabaseUser!.id,
        );
        gacha.checkStreakAndAwardTicket(activeDays.length);
      }

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('🧾', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Struk $finalMerchant (${items.length} item) tersimpan!',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.card,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal simpan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── SAVE ───────────────────────────────────────────────────────────────────

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;

    setState(() => _isSaving = true);

    try {
      final rawText = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = double.tryParse(rawText) ?? 0;
      if (amount <= 0) return;

      final defaultCategory = switch (_type) {
        'income' => 'Pemasukan',
        'expense' => 'Pengeluaran',
        'saving' => 'Tabungan',
        'investment' => 'Investasi',
        _ => 'Lain-lain',
      };

      final notes = _notesCtrl.text.trim();
      final catText = _categoryCtrl.text.trim();

      final tx = TransactionModel(
        id: '',
        userId: auth.supabaseUser!.id,
        type: _type,
        amount: amount,
        date: _selectedDate,
        category: catText.isNotEmpty ? catText : defaultCategory,
        incomeType: _type == 'income' ? 'fixed' : null,
        note: notes.isNotEmpty ? notes : null,
      );

      await UserStatsService.addTransaction(tx);
      await auth.refreshStats();

      // Award gacha streak
      if (mounted) {
        final gacha = context.read<GachaProvider>();
        final activeDays = await UserStatsService.getMonthlyActivedays(
          auth.supabaseUser!.id,
        );
        gacha.checkStreakAndAwardTicket(activeDays.length);
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(_selected.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                const Text(
                  'Transaksi tersimpan!',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.card,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.card,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sel = _selected;
    final cats = _type == 'income' ? _incomeCategories : _expenseCategories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
        ),
        title: const Text(
          'Catat Transaksi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _isScanning ? null : _showScanSourcePicker,
              icon: _isScanning
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2))
                  : Icon(
                      kIsWeb
                          ? Icons.upload_file_rounded
                          : Icons.document_scanner_rounded,
                      size: 16,
                    ),
              label: Text(
                _isScanning
                    ? 'Loading...'
                    : (kIsWeb ? 'Upload Nota' : 'Scan Nota'),
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            // ── Scan Result Banner ─────────────────────────────────────────
            if (_scannedBytes != null) ...[
              _ScanResultCard(
                imageBytes: _scannedBytes!,
                scanResult: _scanResult,
                isScanning: _isScanning,
                pulseController: _pulseController,
                onRetry: _showScanSourcePicker,
              ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2),
              const SizedBox(height: 20),
            ],

            // ── Tipe Transaksi ─────────────────────────────────────────────
            const _SectionHeader(label: 'TIPE TRANSAKSI'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.9,
              children: _typeOptions.asMap().entries.map((entry) {
                final i = entry.key;
                final opt = entry.value;
                final isActive = _type == opt.value;
                return GestureDetector(
                  onTap: () => setState(() => _type = opt.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isActive
                          ? opt.color.withValues(alpha: 0.15)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isActive ? opt.color : AppColors.cardBorder,
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(opt.emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 6),
                        Text(
                          opt.label,
                          style: TextStyle(
                            color: isActive ? opt.color : AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: (i * 60).ms).fadeIn().scale(begin: const Offset(0.8, 0.8));
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Nominal ────────────────────────────────────────────────────
            const _SectionHeader(label: 'NOMINAL'),
            const SizedBox(height: 10),
            _AmountField(controller: _amountCtrl, color: sel.color),

            const SizedBox(height: 20),

            // ── Kategori ───────────────────────────────────────────────────
            const _SectionHeader(label: 'KATEGORI'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _categoryCtrl,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Contoh: Makan siang, Bensin, Gaji...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: sel.color),
                ),
                prefixIcon: const Icon(Icons.label_outline_rounded,
                    color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: cats.map((cat) {
                  final isSelected = _categoryCtrl.text == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _categoryCtrl.text = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? sel.color.withValues(alpha: 0.2)
                              : AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? sel.color : AppColors.cardBorder,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected
                                ? sel.color
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            // ── Catatan ────────────────────────────────────────────────────
            const _SectionHeader(label: 'CATATAN (opsional)'),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 2,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tulis catatan tambahan...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: sel.color.withValues(alpha: 0.5)),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Tanggal ────────────────────────────────────────────────────
            const _SectionHeader(label: 'TANGGAL'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: sel.color, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                          .format(_selectedDate),
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down_rounded,
                        color: AppColors.textMuted),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // ── Bottom Save Button ─────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: sel.color,
              disabledBackgroundColor: sel.color.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 22, width: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(sel.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      const Text(
                        'Simpan Transaksi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 2,
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final Color color;

  const _AmountField({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 22),
      decoration: InputDecoration(
        hintText: '0',
        hintStyle: TextStyle(
          color: color.withValues(alpha: 0.3),
          fontWeight: FontWeight.w800,
          fontSize: 22,
        ),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 1.5),
        ),
        prefixText: 'Rp ',
        prefixStyle: TextStyle(
          color: color.withValues(alpha: 0.7),
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Harap isi nominal';
        final val = double.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));
        if (val == null || val <= 0) return 'Nominal harus > 0';
        return null;
      },
    );
  }
}

class _ScanSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ScanSourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanResultCard extends StatelessWidget {
  final Uint8List imageBytes;
  final String? scanResult;
  final bool isScanning;
  final AnimationController pulseController;
  final VoidCallback onRetry;

  const _ScanResultCard({
    required this.imageBytes,
    required this.scanResult,
    required this.isScanning,
    required this.pulseController,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = scanResult?.contains('✓') == true;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isScanning
              ? AppColors.primary.withValues(alpha: 0.5)
              : (isSuccess
                  ? AppColors.xpGreen.withValues(alpha: 0.5)
                  : AppColors.cardBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: SizedBox(
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(imageBytes, fit: BoxFit.cover),
                  if (isScanning)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedBuilder(
                              animation: pulseController,
                              builder: (_, _) => Opacity(
                                opacity: 0.5 + pulseController.value * 0.5,
                                child: const Icon(
                                  Icons.document_scanner_rounded,
                                  color: AppColors.primary,
                                  size: 40,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Membaca teks nota...',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isScanning
                      ? Icons.hourglass_top_rounded
                      : (isSuccess
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded),
                  color: isScanning
                      ? AppColors.primary
                      : (isSuccess ? AppColors.xpGreen : AppColors.warning),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isScanning
                        ? 'Sedang menganalisis nota...'
                        : (scanResult ?? 'Siap'),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Ganti foto',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TxType {
  final String value;
  final String emoji;
  final String label;
  final Color color;

  const _TxType(this.value, this.emoji, this.label, this.color);
}
