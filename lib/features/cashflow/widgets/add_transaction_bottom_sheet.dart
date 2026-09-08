import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/models/category_models.dart';
import 'package:life_rank/core/services/user_stats_service.dart';
import 'package:life_rank/features/auth/providers/auth_provider.dart';

class AddTransactionBottomSheet extends StatefulWidget {
  final VoidCallback onTransactionAdded;
  final TransactionModel? existingTransaction;

  const AddTransactionBottomSheet({
    super.key,
    required this.onTransactionAdded,
    this.existingTransaction,
  });

  @override
  State<AddTransactionBottomSheet> createState() => _AddTransactionBottomSheetState();
}

class _AddTransactionBottomSheetState extends State<AddTransactionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  // 'income', 'expense', 'saving', 'investment'
  String _type = 'income';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get _isEditMode => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingTransaction != null) {
      _type = widget.existingTransaction!.type;
      if (_type != 'income' && _type != 'expense') {
        _type = 'expense';
      }
      _amountCtrl.text = widget.existingTransaction!.amount.toStringAsFixed(0);
      _categoryCtrl.text = widget.existingTransaction!.category ?? '';
      _noteCtrl.text = widget.existingTransaction!.note ?? '';
      _selectedDate = widget.existingTransaction!.date;
    }
  }

  static const _typeOptions = [
    _TxType('income',     '💵', 'Pemasukan',  AppColors.xpGreen),
    _TxType('expense',    '💸', 'Pengeluaran', AppColors.danger),
  ];

  _TxType get _selected => _typeOptions.firstWhere((t) => t.value == _type);

  @override
  void dispose() {
    _amountCtrl.dispose();
    _categoryCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
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
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kamu belum login'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final rawText = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
      final amount = double.tryParse(rawText) ?? 0;
      if (amount <= 0) return;

      final defaultCategory = switch (_type) {
        'income'     => 'Pemasukan',
        'expense'    => 'Pengeluaran',
        'saving'     => 'Tabungan',
        'investment' => 'Investasi',
        _            => 'Lain-lain',
      };

      final tx = TransactionModel(
        id: _isEditMode ? widget.existingTransaction!.id : '',
        userId: auth.supabaseUser!.id,
        type: _type,
        amount: amount,
        date: _selectedDate,
        category: _categoryCtrl.text.trim().isNotEmpty
            ? _categoryCtrl.text.trim()
            : defaultCategory,
        incomeType: _type == 'income' ? 'fixed' : null,
        note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
      );

      if (_isEditMode) {
        await UserStatsService.updateTransaction(tx);
      } else {
        await UserStatsService.addTransaction(tx);
      }

      if (mounted) widget.onTransactionAdded();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sel = _selected;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditMode ? 'Edit Transaksi' : 'Tambah Transaksi',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Tipe transaksi (4 pilihan) ─────────────────────────────────
            const Text(
              'TIPE TRANSAKSI',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: _typeOptions.map((opt) {
                final isActive = _type == opt.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = opt.value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.only(
                        right: opt == _typeOptions.last ? 0 : 8,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? opt.color.withValues(alpha: 0.18)
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? opt.color
                              : AppColors.cardBorder,
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(opt.emoji,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(
                            opt.label,
                            style: TextStyle(
                              color: isActive
                                  ? opt.color
                                  : AppColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),


            const SizedBox(height: 20),

            // ── Jumlah ────────────────────────────────────────────────────
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(
                  color: sel.color, fontWeight: FontWeight.w700, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'Jumlah (Rp)',
                labelStyle:
                    const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: sel.color),
                ),
                prefixText: 'Rp ',
                prefixStyle: TextStyle(
                    color: sel.color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Harap isi jumlah';
                final val = double.tryParse(
                    v.replaceAll(RegExp(r'[^0-9]'), ''));
                if (val == null || val <= 0) return 'Jumlah harus > 0';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // ── Kategori ──────────────────────────────────────────────────
            TextFormField(
              controller: _categoryCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Kategori / Keterangan (opsional)',
                labelStyle:
                    const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.category,
                    color: AppColors.textSecondary),
              ),
            ),
            if (_type == 'expense') ...[
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'Kebutuhan Pokok',
                    'Investasi',
                    'Tabungan',
                    'Dana Darurat',
                    'Healing',
                  ].map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(cat, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                        backgroundColor: AppColors.card,
                        side: const BorderSide(color: AppColors.cardBorder),
                        onPressed: () {
                          _categoryCtrl.text = cat;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: 14),

            // ── Keperluan / Sumber (Catatan) ──────────────────────────────
            TextFormField(
              controller: _noteCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: _type == 'expense'
                    ? 'Pengeluaran untuk apa? (Catatan)'
                    : 'Pemasukan dari apa? (Catatan)',
                hintText: _type == 'expense'
                    ? 'Contoh: Nasi padang, bayar wifi, beli baju'
                    : 'Contoh: Gaji pokok, freelance web, bonus',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(
                  _type == 'expense'
                      ? Icons.receipt_long_outlined
                      : Icons.account_balance_wallet_outlined,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Tanggal ───────────────────────────────────────────────────
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.textSecondary, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd MMM yyyy').format(_selectedDate),
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down,
                        color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Tombol Simpan ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: sel.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(sel.emoji,
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(_isEditMode ? 'Simpan Perubahan' : 'Simpan Transaksi',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
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
