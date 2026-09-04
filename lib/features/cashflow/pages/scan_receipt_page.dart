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

// ML Kit only available on mobile
// ignore: uri_does_not_exist
import 'scan_helper_stub.dart' if (dart.library.io) 'scan_helper_native.dart';

/// Halaman scan nota yang langsung action:
/// Buka → pilih kamera/gallery → OCR → tampilkan item → Simpan.
/// Tidak ada form kosong, tidak ada input manual wajib.
class ScanReceiptPage extends StatefulWidget {
  const ScanReceiptPage({super.key});

  @override
  State<ScanReceiptPage> createState() => _ScanReceiptPageState();
}

enum _ScanState { idle, scanning, done, error, unsupported }

class _ScanReceiptPageState extends State<ScanReceiptPage> {
  _ScanState _state = _ScanState.idle;
  Uint8List? _imageBytes;
  ReceiptParseResult? _result;
  String? _errorMsg;

  // Edit state untuk item list
  List<ReceiptItem>? _items;
  List<bool>? _checked;
  String _category = 'Belanja';
  DateTime _date = DateTime.now();
  bool _isSaving = false;

  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static const _categories = [
    'Makanan', 'Transport', 'Belanja', 'Kesehatan',
    'Hiburan', 'Tagihan', 'Cicilan', 'Dana Darurat',
  ];

  @override
  void initState() {
    super.initState();
    // Langsung tampilkan picker saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSourcePicker());
  }

  // ── Source Picker ─────────────────────────────────────────────────────────

  Future<void> _showSourcePicker() async {
    if (kIsWeb) {
      await _pickAndScan(ImageSource.gallery);
      return;
    }

    final src = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SourcePickerSheet(
        onCamera: () => Navigator.pop(ctx, ImageSource.camera),
        onGallery: () => Navigator.pop(ctx, ImageSource.gallery),
      ),
    );

    if (src == null) {
      // User dismiss → kembali
      if (mounted) context.pop();
      return;
    }
    await _pickAndScan(src);
  }

  // ── OCR + Parse ───────────────────────────────────────────────────────────

  Future<void> _pickAndScan(ImageSource source) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2048,
    );

    if (xFile == null) {
      if (mounted) context.pop();
      return;
    }

    final bytes = await xFile.readAsBytes();
    setState(() {
      _state = _ScanState.scanning;
      _imageBytes = bytes;
    });

    if (kIsWeb) {
      // Web: tidak ada OCR, tampilkan pesan
      setState(() {
        _state = _ScanState.unsupported;
        _result = ReceiptParseResult(items: [], merchant: null, grandTotal: null);
      });
      return;
    }

    try {
      // ignore: undefined_function, undefined_method
      final fullText = await performOcr(xFile.path);

      if (fullText.isEmpty) {
        setState(() {
          _state = _ScanState.error;
          _errorMsg = 'Teks tidak terbaca.\nCoba foto ulang dengan cahaya yang lebih terang.';
        });
        return;
      }

      final result = ReceiptParserService.parse(fullText);
      _result = result;

      if (result.hasItems) {
        _items = List.from(result.items);
        _checked = List.filled(result.items.length, true);
        _category = result.suggestedCategory;
      }

      setState(() => _state = _ScanState.done);
    } catch (e) {
      setState(() {
        _state = _ScanState.error;
        _errorMsg = 'Gagal memproses gambar:\n${e.toString()}';
      });
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_items == null || _checked == null) return;
    final selected = [
      for (int i = 0; i < _items!.length; i++)
        if (_checked![i]) _items![i],
    ];
    if (selected.isEmpty) return;

    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      for (final item in selected) {
        final tx = TransactionModel(
          id: '',
          userId: auth.supabaseUser!.id,
          type: 'expense',
          amount: item.effectiveTotal,
          date: _date,
          category: '$_category — ${item.name}',
          incomeType: null,
        );
        await UserStatsService.addTransaction(tx);
      }

      await auth.refreshStats();

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
                Text(
                  '${selected.length} transaksi tersimpan!',
                  style: const TextStyle(
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
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int get _selectedCount => _checked?.where((c) => c).length ?? 0;
  double get _selectedTotal => _items == null || _checked == null
      ? 0
      : [
          for (int i = 0; i < _items!.length; i++)
            if (_checked![i]) _items![i].effectiveTotal,
        ].fold(0, (a, b) => a + b);

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (ctx, child) => Theme(
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
    if (picked != null && mounted) setState(() => _date = picked);
  }

  void _editItem(int index) {
    final nameCtrl = TextEditingController(text: _items![index].name);
    final priceCtrl = TextEditingController(
      text: _items![index].effectiveTotal.toStringAsFixed(0),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Edit Item',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TextField(ctrl: nameCtrl, label: 'Nama Item', icon: Icons.label_outline_rounded),
            const SizedBox(height: 12),
            _TextField(ctrl: priceCtrl, label: 'Harga (Rp)', icon: Icons.payments_outlined, numeric: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final price = double.tryParse(
                    priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
                  ) ??
                  _items![index].effectiveTotal;
              setState(() {
                _items![index] = _items![index].copyWith(
                  name: nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : _items![index].name,
                  total: price,
                  unitPrice: price,
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Scan Nota',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_state == _ScanState.done || _state == _ScanState.error)
            TextButton.icon(
              onPressed: _showSourcePicker,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Scan Lagi'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _state == _ScanState.done && _items != null && _items!.isNotEmpty
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildBody() {
    return switch (_state) {
      _ScanState.idle => const SizedBox.shrink(),
      _ScanState.scanning => _buildScanningView(),
      _ScanState.done => _buildResultView(),
      _ScanState.error => _buildErrorView(),
      _ScanState.unsupported => _buildWebUnsupportedView(),
    };
  }

  // ── Scanning View ─────────────────────────────────────────────────────────

  Widget _buildScanningView() {
    return Column(
      children: [
        // Gambar yang sedang di-scan
        if (_imageBytes != null)
          Expanded(
            flex: 2,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(_imageBytes!, fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        AppColors.background,
                      ],
                    ),
                  ),
                ),
                // Scan line animasi
                _ScanLineAnimation(),
              ],
            ),
          ),

        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulsing icon
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(milliseconds: 800),
                builder: (_, scale, child) => Transform.scale(
                  scale: scale,
                  child: child,
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(
                    Icons.document_scanner_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Membaca teks dari nota...',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ).animate(onPlay: (c) => c.repeat()).shimmer(
                    duration: 1500.ms,
                    color: AppColors.primary,
                  ),
              const SizedBox(height: 8),
              const Text(
                'AI sedang menganalisis struk belanjamu',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Result View ───────────────────────────────────────────────────────────

  Widget _buildResultView() {
    final hasItems = _items != null && _items!.isNotEmpty;

    return CustomScrollView(
      slivers: [
        // ── Image thumbnail + merchant ────────────────────────────────
        SliverToBoxAdapter(
          child: _buildImageHeader(),
        ),

        if (!hasItems) ...[
          SliverToBoxAdapter(
            child: _buildNoItemsCard(),
          ),
        ] else ...[
          // ── Kategori & Tanggal strip ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: _FilterChip(
                      icon: Icons.label_outline_rounded,
                      label: _category,
                      color: AppColors.financial,
                      onTap: _showCategoryPicker,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FilterChip(
                      icon: Icons.calendar_today_rounded,
                      label: DateFormat('dd MMM yyyy', 'id_ID').format(_date),
                      color: AppColors.career,
                      onTap: _selectDate,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Header list ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text(
                    'ITEM DARI STRUK',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      final allOn = _selectedCount < _items!.length;
                      setState(() {
                        _checked = List.filled(_items!.length, allOn);
                      });
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _selectedCount == _items!.length
                          ? 'Batal Semua'
                          : 'Pilih Semua',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // ── Item list ─────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ItemRow(
                    item: _items![i],
                    checked: _checked![i],
                    currency: _currency,
                    onToggle: (v) => setState(() => _checked![i] = v ?? false),
                    onEdit: () => _editItem(i),
                    onDelete: () => setState(() {
                      _items!.removeAt(i);
                      _checked!.removeAt(i);
                    }),
                  )
                      .animate(delay: (i * 50).ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.15),
                ),
                childCount: _items!.length,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Gambar struk
          if (_imageBytes != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Image.memory(
                  _imageBytes!,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // Info merchant + badge
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _result?.merchant ?? 'Struk Belanja',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _items != null && _items!.isNotEmpty
                            ? '${_items!.length} item terdeteksi'
                            : 'Item tidak terdeteksi',
                        style: TextStyle(
                          color: _items != null && _items!.isNotEmpty
                              ? AppColors.xpGreen
                              : AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Total badge
                if (_result?.grandTotal != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _currency.format(_result!.grandTotal!),
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1);
  }

  Widget _buildNoItemsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded,
              color: AppColors.warning, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Item tidak terdeteksi',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'OCR berhasil membaca teks, tapi format struk tidak dikenali. Coba foto ulang atau input manual.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showSourcePicker,
                  icon: const Icon(Icons.camera_alt_rounded, size: 16),
                  label: const Text('Foto Ulang'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.pop();
                    context.push('/add-transaction');
                  },
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Input Manual'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.card,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 24),
            const Icon(Icons.image_not_supported_rounded,
                color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMsg ?? 'Gagal membaca nota',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showSourcePicker,
                    icon: const Icon(Icons.camera_alt_rounded, size: 16),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.pop();
                      context.push('/add-transaction');
                    },
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Manual'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.cardBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebUnsupportedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.web_asset_off_rounded,
                color: AppColors.warning, size: 56),
            const SizedBox(height: 20),
            const Text(
              'OCR tidak tersedia di Web',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fitur scan nota menggunakan ML Kit yang hanya tersedia di perangkat Android/iOS.',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Kembali'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Save Bar ───────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          // Total badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_selectedCount item',
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  _currency.format(_selectedTotal),
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Tombol simpan
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: (_selectedCount == 0 || _isSaving) ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Simpan $_selectedCount Transaksi',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Pilih Kategori',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((cat) {
                final isSel = cat == _category;
                return GestureDetector(
                  onTap: () {
                    setState(() => _category = cat);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isSel
                              ? AppColors.primary
                              : AppColors.cardBorder),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color:
                            isSel ? AppColors.primary : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SourcePickerSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _SourcePickerSheet({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
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
            // Header
            const Row(
              children: [
                Text('📸', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Scan Nota',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Foto struk → item otomatis terdeteksi',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SourceBtn(
                    icon: Icons.camera_alt_rounded,
                    label: 'Kamera',
                    sublabel: 'Foto langsung',
                    color: AppColors.primary,
                    onTap: onCamera,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SourceBtn(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    sublabel: 'Pilih foto',
                    color: AppColors.financial,
                    onTap: onGallery,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  const _SourceBtn({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(sublabel,
                style:
                    TextStyle(color: color.withValues(alpha: 0.6), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final ReceiptItem item;
  final bool checked;
  final NumberFormat currency;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemRow({
    required this.item,
    required this.checked,
    required this.currency,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: checked ? AppColors.card : AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: checked
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.cardBorder.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () => onToggle(!checked),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Checkbox(
                value: checked,
                onChanged: onToggle,
                activeColor: AppColors.primary,
                side: BorderSide(
                  color: checked ? AppColors.primary : AppColors.textMuted,
                  width: 1.5,
                ),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        color: checked
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.qty > 1)
                      Text(
                        '${item.qty}× ${currency.format(item.unitPrice)}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                currency.format(item.effectiveTotal),
                style: TextStyle(
                  color: checked ? AppColors.danger : AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              PopupMenuButton<String>(
                color: AppColors.card,
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textMuted, size: 18),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, color: AppColors.primary, size: 16),
                      SizedBox(width: 8),
                      Text('Edit', style: TextStyle(color: AppColors.textPrimary)),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded,
                          color: AppColors.danger, size: 16),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: AppColors.danger)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ScanLineAnimation extends StatefulWidget {
  @override
  State<_ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<_ScanLineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Positioned(
        top: _anim.value * 160,
        left: 0,
        right: 0,
        child: Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.primary.withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool numeric;

  const _TextField({
    required this.ctrl,
    required this.label,
    required this.icon,
    this.numeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
