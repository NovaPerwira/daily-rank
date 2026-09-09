import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:life_rank/core/constants/app_colors.dart';
import 'package:life_rank/core/models/category_models.dart';
import 'package:life_rank/core/models/receipt_item_model.dart';
import 'package:life_rank/core/services/user_stats_service.dart';
import 'package:life_rank/features/auth/providers/auth_provider.dart';

import '../widgets/add_transaction_bottom_sheet.dart';
import 'package:life_rank/shared/widgets/respect_modal.dart';

class CashflowPage extends StatefulWidget {
  const CashflowPage({super.key});

  @override
  State<CashflowPage> createState() => _CashflowPageState();
}

class _CashflowPageState extends State<CashflowPage> {
  bool _isLoading = false;
  final Set<String> _expandedReceiptIds = {};
  List<TransactionModel> _transactions = [];
  DateTime? _selectedMonth;
  List<DateTime> _availableMonths = [];
  final _formatter = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    if (auth.supabaseUser == null) {
      setState(() => _isLoading = false);
      return;
    }
    final txs = await UserStatsService.getTransactions(auth.supabaseUser!.id);
    if (mounted) {
      setState(() {
        _transactions = txs;
        
        final Set<String> monthSet = {};
        _availableMonths = [];
        for (final t in txs) {
           final mStr = '${t.date.year}-${t.date.month}';
           if (!monthSet.contains(mStr)) {
             monthSet.add(mStr);
             _availableMonths.add(DateTime(t.date.year, t.date.month));
           }
        }
        _availableMonths.sort((a, b) => b.compareTo(a));
        
        _isLoading = false;
      });
    }
  }

  // ── Add ────────────────────────────────────────────────────────────────────
  void _showAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AddTransactionBottomSheet(
          onTransactionAdded: () {
            Navigator.pop(ctx);
            _loadTransactions();
            // Tampilkan popup "Respect+" setelah berhasil menginput transaksi
            RespectModal.show(context);
          },
        ),
      ),
    );
  }

  // ── Edit ───────────────────────────────────────────────────────────────────
  void _showEditSheet(TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: AddTransactionBottomSheet(
          existingTransaction: tx,
          onTransactionAdded: () {
            Navigator.pop(ctx);
            _loadTransactions();
          },
        ),
      ),
    );
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> _deleteTransaction(TransactionModel tx) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 32),
        title: const Text(
          'Delete Transaction?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '"${tx.category ?? tx.type}" for Rp ${_formatter.format(tx.amount)} will be permanently removed.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await UserStatsService.deleteTransaction(tx.id);
      _loadTransactions();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filteredTransactions = _selectedMonth == null
        ? _transactions
        : _transactions.where((t) => t.date.year == _selectedMonth!.year && t.date.month == _selectedMonth!.month).toList();

    double totalIncome = 0;
    double totalPureExpense = 0;
    double totalAssetAllocation = 0;

    for (var tx in filteredTransactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else if (tx.type == 'expense') {
        final isAsset = tx.category?.toLowerCase().contains('investasi') == true ||
            tx.category?.toLowerCase().contains('tabungan') == true ||
            tx.category?.toLowerCase().contains('dana darurat') == true;
        if (isAsset) {
          totalAssetAllocation += tx.amount;
        } else {
          totalPureExpense += tx.amount;
        }
      } else if (tx.type == 'saving' || tx.type == 'investment') {
        totalAssetAllocation += tx.amount;
      }
    }
    
    final cashFlow = totalIncome - totalPureExpense;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Cash Flow',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                children: [
                  // ── Month Filter ─────────────────────────────────────────
                  _buildMonthFilter(),
                  const SizedBox(height: 16),

                  // ── Summary Cards ────────────────────────────────────────
                  _buildSummaryRow(totalIncome, totalPureExpense, totalAssetAllocation, cashFlow),
                  const SizedBox(height: 12),
                  _buildNetWorthBanner(cashFlow),
                  const SizedBox(height: 28),

                  // ── Section header ───────────────────────────────────────
                  const Text(
                    'RIWAYAT TRANSAKSI',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (filteredTransactions.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Column(
                          children: [
                            Text('📭', style: TextStyle(fontSize: 48)),
                            SizedBox(height: 12),
                            Text(
                              'Belum ada transaksi',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tekan + untuk menambah catatan baru',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...filteredTransactions.map((tx) => _buildTransactionTile(tx)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildMonthFilter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'FILTER BULAN',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<DateTime?>(
              value: _selectedMonth,
              dropdownColor: AppColors.card,
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Semua Waktu'),
                ),
                ..._availableMonths.map((m) => DropdownMenuItem(
                  value: m,
                  child: Text(DateFormat('MMMM yyyy', 'id_ID').format(m)),
                )),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedMonth = val;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Summary Row (Income vs Expense vs Allocation) ──────────────────────────

  Widget _buildSummaryRow(double totalIncome, double totalPureExpense, double totalAssetAllocation, double cashFlow) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Pemasukan',
                amount: totalIncome,
                color: AppColors.xpGreen,
                icon: Icons.arrow_downward_rounded,
                formatter: _formatter,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Pengeluaran Murni',
                amount: totalPureExpense,
                color: AppColors.danger,
                icon: Icons.arrow_upward_rounded,
                formatter: _formatter,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Alokasi Aset (Investasi)',
                amount: totalAssetAllocation,
                color: AppColors.financial,
                icon: Icons.savings_outlined,
                formatter: _formatter,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Sisa Kas (Belum Dialokasi)',
                amount: cashFlow,
                color: cashFlow >= 0 ? AppColors.textPrimary : AppColors.danger,
                icon: Icons.account_balance_wallet_outlined,
                formatter: _formatter,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Net Worth Banner (Saving + Investment → Rank) ──────────────────────────

  Widget _buildNetWorthBanner(double total) {
    final isPositive = total >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.financial.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.military_tech_rounded,
                color: AppColors.gold,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'ARUS KAS BERSIH',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Rp ${_formatter.format(total.abs())}${total < 0 ? ' (minus)' : ''}',
            style: TextStyle(
              color: isPositive ? AppColors.textPrimary : AppColors.danger,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total sisa uang dari Pemasukan dikurangi Pengeluaran murni (Investasi tidak mengurangi kas).',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ── Transaction Tile with Edit & Delete ────────────────────────────────────

  Widget _buildTransactionTile(TransactionModel tx) {
    final (amountColor, prefix, icon) = switch (tx.type) {
      'income' => (AppColors.xpGreen, '+', Icons.arrow_downward_rounded),
      'expense' => (AppColors.danger, '-', Icons.shopping_bag_outlined),
      'saving' => (AppColors.financial, '+', Icons.savings_outlined),
      'investment' => (AppColors.primary, '+', Icons.trending_up_rounded),
      _ => (AppColors.textSecondary, '+', Icons.receipt_outlined),
    };

    final typeLabel = switch (tx.type) {
      'income' => 'Pemasukan',
      'expense' => 'Pengeluaran',
      'saving' => 'Tabungan • Ikut Rank',
      'investment' => 'Investasi • Ikut Rank',
      _ => tx.type,
    };

    final dateStr = DateFormat('dd MMM yyyy', 'id_ID').format(tx.date);

    // ── Receipt Group (Struk Belanja Terstruktur) ──────────────────────────
    if (tx.isReceiptGroup) {
      final group = tx.receiptData!;
      final isExpanded = _expandedReceiptIds.contains(tx.id);
      final products = group.items.where((i) => !i.isChargeOrTax).toList();
      final charges = group.items.where((i) => i.isChargeOrTax).toList();

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          children: [
            // ── Header baris utama ──────────────────────────────────────
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() {
                if (isExpanded) {
                  _expandedReceiptIds.remove(tx.id);
                } else {
                  _expandedReceiptIds.add(tx.id);
                }
              }),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Receipt icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.danger,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nama Toko (group header)
                          Row(
                            children: [
                              const Icon(
                                Icons.storefront_rounded,
                                size: 13,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  group.merchant,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tx.category ?? 'Belanja',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                typeLabel,
                                style: TextStyle(
                                  color: amountColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Text(' · ',
                                  style: TextStyle(
                                      color: AppColors.textMuted, fontSize: 10)),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 10),
                              ),
                              const Text(' · ',
                                  style: TextStyle(
                                      color: AppColors.textMuted, fontSize: 10)),
                              Text(
                                '${group.items.length} item',
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 10),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Amount + actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '- Rp ${_formatter.format(tx.amount)}',
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _ActionButton(
                              icon: Icons.edit_outlined,
                              color: AppColors.textSecondary,
                              onTap: () => _showEditSheet(tx),
                            ),
                            const SizedBox(width: 6),
                            _ActionButton(
                              icon: Icons.delete_outline_rounded,
                              color: AppColors.danger,
                              onTap: () => _deleteTransaction(tx),
                            ),
                            const SizedBox(width: 4),
                            AnimatedRotation(
                              turns: isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                Icons.expand_more_rounded,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Expandable Detail ────────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16)),
                        border: Border(
                          top: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Produk
                          if (products.isNotEmpty) ...[
                            const Text(
                              'DETAIL PEMBELIAN',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...products.map((item) => _ReceiptItemRow(
                                  item: item,
                                  formatter: _formatter,
                                )),
                          ],
                          // Biaya tambahan (pajak, service, dsb)
                          if (charges.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'PAJAK & BIAYA LAINNYA',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ...charges.map((item) => _ReceiptItemRow(
                                  item: item,
                                  formatter: _formatter,
                                  isCharge: true,
                                )),
                          ],
                          // Garis total
                          const SizedBox(height: 8),
                          Container(
                            height: 1,
                            color: AppColors.cardBorder,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Rp ${_formatter.format(tx.amount)}',
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }

    // ── Transaksi Biasa ─────────────────────────────────────────────────────
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: amountColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: amountColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.category ?? 'Lain-lain',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (tx.note != null && tx.note!.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      tx.note!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        typeLabel,
                        style: TextStyle(
                          color: amountColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        ' · ',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$prefix Rp ${_formatter.format(tx.amount)}',
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                // Edit & Delete buttons
                Row(
                  children: [
                    _ActionButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.textSecondary,
                      onTap: () => _showEditSheet(tx),
                    ),
                    const SizedBox(width: 6),
                    _ActionButton(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.danger,
                      onTap: () => _deleteTransaction(tx),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Receipt Item Row (used inside expanded receipt detail) ────────────────────

class _ReceiptItemRow extends StatelessWidget {
  final ReceiptItem item;
  final NumberFormat formatter;
  final bool isCharge;

  const _ReceiptItemRow({
    required this.item,
    required this.formatter,
    this.isCharge = false,
  });

  @override
  Widget build(BuildContext context) {
    final tagColor = item.chargeTag == 'Pajak'
        ? Colors.orange
        : (item.chargeTag == 'Service'
            ? Colors.blue
            : AppColors.financial);

    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          // Charge tag badge or bullet
          if (item.chargeTag != null)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: tagColor.withValues(alpha: 0.35)),
              ),
              child: Text(
                item.chargeTag!,
                style: TextStyle(
                    color: tagColor, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            )
          else
            Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.only(right: 8, left: 1),
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
          // Nama item
          Expanded(
            child: Text(
              item.qty > 1 ? '${item.name} (${item.qty}×)' : item.name,
              style: TextStyle(
                color: isCharge ? AppColors.textSecondary : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // Harga
          Text(
            'Rp ${formatter.format(item.effectiveTotal)}',
            style: TextStyle(
              color: isCharge ? AppColors.textSecondary : AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;
  final NumberFormat formatter;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.formatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Rp ${formatter.format(amount)}',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
    );
  }
}
