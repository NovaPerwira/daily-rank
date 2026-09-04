/// Satu baris item yang diekstrak dari hasil scan struk / nota belanja.
class ReceiptItem {
  final String name;
  final int qty;
  final double unitPrice;
  final double total;

  ReceiptItem({
    required this.name,
    this.qty = 1,
    required this.unitPrice,
    required this.total,
  });

  /// Harga efektif yang akan disimpan sebagai transaksi.
  double get effectiveTotal => total > 0 ? total : unitPrice * qty;

  ReceiptItem copyWith({
    String? name,
    int? qty,
    double? unitPrice,
    double? total,
  }) =>
      ReceiptItem(
        name: name ?? this.name,
        qty: qty ?? this.qty,
        unitPrice: unitPrice ?? this.unitPrice,
        total: total ?? this.total,
      );

  @override
  String toString() =>
      'ReceiptItem(name: $name, qty: $qty, unitPrice: $unitPrice, total: $effectiveTotal)';
}
