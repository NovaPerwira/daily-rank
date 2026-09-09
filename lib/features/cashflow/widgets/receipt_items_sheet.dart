import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/models/receipt_item_model.dart';
import 'package:life_rank/core/services/receipt_parser_service.dart';

/// Bottom sheet yang menampilkan daftar item hasil scan struk.
/// User bisa centang/uncentang, edit nama & harga, lalu simpan semua sekaligus.
class ReceiptItemsSheet extends StatefulWidget {
  final ReceiptParseResult parseResult;
  final DateTime transactionDate;

  /// Callback ketika user klik simpan.
  /// Mengembalikan daftar item yang dipilih + kategori + tanggal + nama toko.
  final void Function(
    List<ReceiptItem> selectedItems,
    String category,
    DateTime date,
    String merchant,
  ) onSave;

  const ReceiptItemsSheet({
    super.key,
    required this.parseResult,
    required this.transactionDate,
    required this.onSave,
  });

  @override
  State<ReceiptItemsSheet> createState() => _ReceiptItemsSheetState();
}

class _ReceiptItemsSheetState extends State<ReceiptItemsSheet> {
  late List<ReceiptItem> _items;
  late List<bool> _checked;
  late String _category;
  late String _merchant;
  late DateTime _date;

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
    _items = List.from(widget.parseResult.items);
    _checked = List.filled(_items.length, true);
    _category = widget.parseResult.suggestedCategory;
    _merchant = (widget.parseResult.merchant != null &&
            widget.parseResult.merchant!.trim().isNotEmpty)
        ? widget.parseResult.merchant!.trim()
        : 'Struk Belanja';
    _date = widget.transactionDate;
  }

  int get _selectedCount => _checked.where((c) => c).length;

  double get _selectedTotal => [
        for (int i = 0; i < _items.length; i++)
          if (_checked[i]) _items[i].effectiveTotal,
      ].fold(0, (a, b) => a + b);

  void _toggleAll(bool value) {
    setState(() {
      for (int i = 0; i < _checked.length; i++) {
        _checked[i] = value;
      }
    });
  }

  void _editItem(int index) {
    final nameCtrl = TextEditingController(text: _items[index].name);
    final priceCtrl = TextEditingController(
      text: _items[index].effectiveTotal.toStringAsFixed(0),
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
            _DialogField(
              controller: nameCtrl,
              label: 'Nama Item',
              icon: Icons.label_outline_rounded,
            ),
            const SizedBox(height: 12),
            _DialogField(
              controller: priceCtrl,
              label: 'Harga (Rp)',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
            ),
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
                  _items[index].effectiveTotal;
              setState(() {
                _items[index] = _items[index].copyWith(
                  name: nameCtrl.text.trim().isEmpty
                      ? _items[index].name
                      : nameCtrl.text.trim(),
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

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
      _checked.removeAt(index);
    });
  }

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

  void _editMerchantName() {
    final ctrl = TextEditingController(text: _merchant);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Nama Toko / Tempat',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: _DialogField(
          controller: ctrl,
          label: 'Nama Toko',
          icon: Icons.storefront_rounded,
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
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _merchant = ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _save() {
    final selected = [
      for (int i = 0; i < _items.length; i++)
        if (_checked[i]) _items[i],
    ];
    if (selected.isEmpty) return;
    HapticFeedback.mediumImpact();
    Navigator.pop(context);
    widget.onSave(selected, _category, _date, _merchant);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // ── Handle ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    child: InkWell(
                      onTap: _editMerchantName,
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _merchant,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                          Text(
                            '${_items.length} item ditemukan • Ketuk ubah toko',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Pilih semua / batal semua
                  TextButton(
                    onPressed: () => _toggleAll(_selectedCount < _items.length),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text(
                      _selectedCount == _items.length ? 'Batal Semua' : 'Pilih Semua',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.cardBorder, height: 1),

            // ── Daftar Item ─────────────────────────────────────────────
            Expanded(
              child: _items.isEmpty
                  ? _EmptyState()
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 8,
                        bottom: 8 + bottomPad,
                      ),
                      itemCount: _items.length,
                      separatorBuilder: (_, ignore) => const SizedBox(height: 6),
                      itemBuilder: (context, i) => _ItemTile(
                        item: _items[i],
                        checked: _checked[i],
                        currency: _currency,
                        onToggle: (v) => setState(() => _checked[i] = v ?? false),
                        onEdit: () => _editItem(i),
                        onDelete: () => _deleteItem(i),
                      )
                          .animate(delay: (i * 40).ms)
                          .fadeIn(duration: 250.ms)
                          .slideX(begin: 0.1),
                    ),
            ),

            const Divider(color: AppColors.cardBorder, height: 1),

            // ── Footer: Kategori + Tanggal + Total + Simpan ─────────────
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomPad),
              child: Column(
                children: [
                  // Kategori & Tanggal
                  Row(
                    children: [
                      Expanded(
                        child: _FooterDropdown(
                          icon: Icons.label_outline_rounded,
                          label: _category,
                          color: AppColors.financial,
                          onTap: () => _showCategoryPicker(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _FooterDropdown(
                          icon: Icons.calendar_today_rounded,
                          label: DateFormat('dd MMM yyyy', 'id_ID').format(_date),
                          color: AppColors.career,
                          onTap: _selectDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Total + Simpan
                  Row(
                    children: [
                      // Total badge
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_selectedCount item dipilih',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currency.format(_selectedTotal),
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Tombol Simpan
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _selectedCount == 0 ? null : _save,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Simpan $_selectedCount Transaksi',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
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
                ],
              ),
            ),
          ],
        ),
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
                final isSelected = cat == _category;
                return GestureDetector(
                  onTap: () {
                    setState(() => _category = cat);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
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

// ── Sub-Widgets ──────────────────────────────────────────────────────────────

class _ItemTile extends StatelessWidget {
  final ReceiptItem item;
  final bool checked;
  final NumberFormat currency;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ItemTile({
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
        color: checked
            ? AppColors.card
            : AppColors.card.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: checked
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.cardBorder.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        onTap: () => onToggle(!checked),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Checkbox
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: checked,
                  onChanged: onToggle,
                  activeColor: AppColors.primary,
                  side: BorderSide(
                    color: checked
                        ? AppColors.primary
                        : AppColors.textMuted,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
              ),
              const SizedBox(width: 10),

              // Nama & qty
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (item.chargeTag != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: item.chargeTag == 'Pajak'
                                  ? Colors.orange.withValues(alpha: 0.15)
                                  : (item.chargeTag == 'Service'
                                      ? Colors.blue.withValues(alpha: 0.15)
                                      : AppColors.financial.withValues(alpha: 0.15)),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: item.chargeTag == 'Pajak'
                                    ? Colors.orange.withValues(alpha: 0.4)
                                    : (item.chargeTag == 'Service'
                                        ? Colors.blue.withValues(alpha: 0.4)
                                        : AppColors.financial.withValues(alpha: 0.4)),
                              ),
                            ),
                            child: Text(
                              item.chargeTag!,
                              style: TextStyle(
                                color: item.chargeTag == 'Pajak'
                                    ? Colors.orange
                                    : (item.chargeTag == 'Service'
                                        ? Colors.blue
                                        : AppColors.financial),
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        Expanded(
                          child: Text(
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
                        ),
                      ],
                    ),
                    if (item.qty > 1)
                      Text(
                        '${item.qty}x  ×  ${currency.format(item.unitPrice)}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Harga
              Text(
                currency.format(item.effectiveTotal),
                style: TextStyle(
                  color: checked ? AppColors.danger : AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(width: 4),

              // Menu edit/hapus
              PopupMenuButton<String>(
                color: AppColors.card,
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined,
                            color: AppColors.primary, size: 16),
                        SizedBox(width: 8),
                        Text('Edit',
                            style: TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            color: AppColors.danger, size: 16),
                        SizedBox(width: 8),
                        Text('Hapus',
                            style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
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

class _FooterDropdown extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _FooterDropdown({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  const _DialogField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
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

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded,
              color: AppColors.textMuted, size: 48),
          SizedBox(height: 12),
          Text(
            'Tidak ada item terdeteksi',
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Coba foto ulang dengan pencahayaan lebih baik',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
