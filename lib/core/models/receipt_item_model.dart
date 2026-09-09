import 'dart:convert';

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

  /// True jika item ini merupakan pajak, biaya layanan, ongkir, dsb.
  bool get isChargeOrTax {
    final lower = name.toLowerCase();
    return lower.contains('pajak') ||
        lower.contains('ppn') ||
        lower.contains('pb1') ||
        lower.contains('pb01') ||
        lower.contains('tax') ||
        lower.contains('service') ||
        lower.contains('layanan') ||
        lower.contains('pembulatan') ||
        lower.contains('ongkir') ||
        lower.contains('delivery') ||
        lower.contains('kemasan') ||
        lower.contains('diskon') ||
        lower.contains('potongan');
  }

  /// Label kategori singkat untuk biaya tambahan
  String? get chargeTag {
    final lower = name.toLowerCase();
    if (lower.contains('pajak') || lower.contains('ppn') || lower.contains('pb1') || lower.contains('tax')) {
      return 'Pajak';
    }
    if (lower.contains('service') || lower.contains('layanan')) {
      return 'Service';
    }
    if (lower.contains('ongkir') || lower.contains('delivery')) {
      return 'Ongkir';
    }
    if (lower.contains('pembulatan')) {
      return 'Pembulatan';
    }
    if (lower.contains('diskon') || lower.contains('potongan')) {
      return 'Diskon';
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'qty': qty,
        'unitPrice': unitPrice,
        'total': effectiveTotal,
      };

  factory ReceiptItem.fromJson(Map<String, dynamic> json) => ReceiptItem(
        name: json['name']?.toString() ?? 'Item',
        qty: (json['qty'] as num?)?.toInt() ?? 1,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
      );

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

/// Data grup struk belanja yang berisi nama toko dan rincian item/biaya yang dibeli.
class ReceiptGroupData {
  final String merchant;
  final List<ReceiptItem> items;

  const ReceiptGroupData({
    required this.merchant,
    required this.items,
  });

  /// Total dari seluruh item di dalam grup struk
  double get totalAmount =>
      items.fold(0.0, (sum, item) => sum + item.effectiveTotal);

  /// Jumlah item murni (non-pajak/service)
  int get productCount => items.where((i) => !i.isChargeOrTax).length;

  /// Serialisasi ke string JSON yang disimpan ke kolom `note` transaksi
  String toEncodedNote() {
    return jsonEncode({
      'type': 'receipt_group',
      'merchant': merchant,
      'items': items.map((i) => i.toJson()).toList(),
    });
  }

  /// Coba parsing note menjadi [ReceiptGroupData]. Mengembalikan null jika note biasa.
  static ReceiptGroupData? tryParse(String? note) {
    if (note == null || note.trim().isEmpty) return null;
    final trimmed = note.trim();
    if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map &&
          (decoded['type'] == 'receipt_group' || decoded.containsKey('items'))) {
        final merchant = decoded['merchant']?.toString() ?? 'Struk Belanja';
        final itemsRaw = decoded['items'] as List<dynamic>? ?? [];
        final items = itemsRaw
            .whereType<Map<String, dynamic>>()
            .map((e) => ReceiptItem.fromJson(e))
            .toList();
        return ReceiptGroupData(merchant: merchant, items: items);
      }
    } catch (_) {}
    return null;
  }
}
