import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import 'package:life_rank/core/models/receipt_item_model.dart';

/// Parser teks OCR dari struk / nota belanja Indonesia.
///
/// Mendukung berbagai format umum:
/// - Indomaret / Alfamart / Alfamidi / Lawson
/// - KFC / McD / Pizza Hut / Chatime
/// - Struk generik kasir POS
/// - GoFood / GrabFood receipt
class ReceiptParserService {
  // ── AI Extraction ─────────────────────────────────────────────────────────

  static Future<ReceiptParseResult> parseWithAI(Uint8List imageBytes) async {
    final provider = dotenv.env['AI_PROVIDER']?.toLowerCase() ?? 'gemini';
    
    final prompt = '''
You are an expert receipt data extractor for Indonesian receipts.
Analyze the provided receipt image and extract the data into a JSON object with this exact structure:
{
  "merchant": "Name of the store (string or null)",
  "items": [
    {
      "name": "Item name / Tax / Service / Fee (string)",
      "qty": 1, 
      "unitPrice": 10000, 
      "total": 10000 
    }
  ],
  "grandTotal": 100000 
}
Rules:
- Only output valid JSON.
- Convert prices into numbers (remove Rp, dots, commas).
- EXTRACT ALL purchased items AND ALL additional charges/fees:
  * Regular purchased items / food / drinks / groceries
  * Pajak / Tax / PPN / PB1 / PB01 / Pajak Resto (extract as item, e.g. "Pajak (PB1/PPN)")
  * Biaya Layanan / Service Charge / Service Fee / Ongkir / Biaya Bungkus (extract as item, e.g. "Biaya Layanan (Service)")
  * Pembulatan / Rounding (if present)
  * Diskon / Potongan Harga (if discount applies, can be positive deduction amount)
- Do NOT include payment tender lines like "Tunai", "Cash", "Kembalian", "Change", "Debit", "QRIS", "Kembali", or overall summary lines like "Total Bayar" in the items array (put the overall final sum in grandTotal).
- Ensure qty is always an integer >= 1.
''';

    String text = '';

    if (provider == 'openrouter') {
      text = await _parseWithOpenRouter(prompt, imageBytes);
    } else {
      text = await _parseWithGemini(prompt, imageBytes);
    }

    if (text.isEmpty) {
      throw Exception('Gagal mendapatkan response dari AI');
    }

    // Bersihkan format markdown jika model mengembalikan blok ```json ... ```
    text = text.trim();
    if (text.startsWith('```json')) {
      text = text.substring(7);
    } else if (text.startsWith('```')) {
      text = text.substring(3);
    }
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    text = text.trim();

    try {
      final json = jsonDecode(text);
      final merchant = json['merchant'] as String?;
      final grandTotal = (json['grandTotal'] as num?)?.toDouble();
      
      final itemsList = json['items'] as List<dynamic>? ?? [];
      final items = itemsList.map((item) {
        return ReceiptItem(
          name: item['name']?.toString() ?? 'Unknown',
          qty: (item['qty'] as num?)?.toInt() ?? 1,
          unitPrice: (item['unitPrice'] as num?)?.toDouble() ?? 0,
          total: (item['total'] as num?)?.toDouble() ?? 0,
        );
      }).toList();

      return ReceiptParseResult(
        merchant: merchant,
        items: _filterItems(items),
        grandTotal: grandTotal,
      );
    } catch (e) {
      throw Exception('Format JSON tidak sesuai: $e\nResponse: $text');
    }
  }

  static Future<String> _parseWithGemini(String prompt, Uint8List imageBytes) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key Gemini tidak ditemukan di .env. Silakan tambahkan GEMINI_API_KEY Anda.');
    }

    final model = GenerativeModel(
      model: 'gemini-1.5-flash', // Bisa diganti ke model lain
      apiKey: apiKey,
    );

    final response = await model.generateContent([
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imageBytes),
      ])
    ]);

    return response.text ?? '';
  }

  static Future<String> _parseWithOpenRouter(String prompt, Uint8List imageBytes) async {
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API Key OpenRouter tidak ditemukan di .env. Silakan tambahkan OPENROUTER_API_KEY Anda.');
    }

    final model = dotenv.env['OPENROUTER_MODEL'] ?? 'google/gemini-2.5-flash-lite';
    final base64Image = base64Encode(imageBytes);

    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
        'HTTP-Referer': 'https://github.com/novap/life_rank', // Required by OpenRouter
        'X-Title': 'Life Rank', // Optional by OpenRouter
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': prompt,
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                }
              }
            ]
          }
        ],
        'reasoning': {
          'enabled': true
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenRouter API Error: ${response.statusCode} - ${response.body}');
    }

    final json = jsonDecode(response.body);
    return json['choices']?[0]?['message']?['content'] ?? '';
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Parse teks OCR mentah menjadi daftar [ReceiptItem].
  /// Juga mengembalikan nama merchant jika terdeteksi.
  static ReceiptParseResult parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final merchant = _detectMerchant(rawText);
    final items = _extractItems(lines);
    final total = _extractTotal(lines);

    return ReceiptParseResult(
      merchant: merchant,
      items: items,
      grandTotal: total,
    );
  }

  // ── Merchant Detection ────────────────────────────────────────────────────

  static const _merchantKeywords = {
    'indomaret': 'Indomaret',
    'alfamart': 'Alfamart',
    'alfamidi': 'Alfamidi',
    'lawson': 'Lawson',
    'circle k': 'Circle K',
    'hypermart': 'Hypermart',
    'carrefour': 'Carrefour',
    'transmart': 'Transmart',
    'lottemart': 'LotteMart',
    'superindo': 'Super Indo',
    'giant': 'Giant',
    'hero': 'Hero Supermarket',
    'mcdonald': 'McDonald\'s',
    'kfc': 'KFC',
    'burger king': 'Burger King',
    'pizza hut': 'Pizza Hut',
    'domino': 'Domino\'s Pizza',
    'jco': 'J.Co',
    'starbucks': 'Starbucks',
    'chatime': 'Chatime',
    'hokben': 'Hoka-Hoka Bento',
    'hokkaido': 'Hokkaido',
    'solaria': 'Solaria',
    'gojek': 'GoFood',
    'gofood': 'GoFood',
    'grab': 'GrabFood',
    'grabfood': 'GrabFood',
    'shopee': 'ShopeeFood',
    'apotek': 'Apotek',
    'kimia farma': 'Kimia Farma',
    'century': 'Century',
    'guardian': 'Guardian',
    'watson': 'Watson',
  };

  static String? _detectMerchant(String text) {
    final lower = text.toLowerCase();
    for (final entry in _merchantKeywords.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  // ── Total Extraction ──────────────────────────────────────────────────────

  static double? _extractTotal(List<String> lines) {
    // Coba cari baris dengan kata kunci total (prioritas: grand total dulu)
    final totalPatterns = [
      // Grand Total / Total Bayar
      RegExp(
        r'(?:grand\s*total|total\s*bayar|jumlah\s*bayar|total\s*tagihan|total\s*pembayaran)[:\s]*(?:rp\.?\s*)?([0-9][0-9.,]+)',
        caseSensitive: false,
      ),
      // Total biasa
      RegExp(
        r'(?:^|\s)total[:\s]+(?:rp\.?\s*)?([0-9][0-9.,]+)',
        caseSensitive: false,
      ),
      // Jumlah / Amount
      RegExp(
        r'(?:jumlah|amount|tagihan|bayar)[:\s]+(?:rp\.?\s*)?([0-9][0-9.,]+)',
        caseSensitive: false,
      ),
      // Rp standalone (ambil yang terbesar)
      RegExp(r'rp\.?\s*([0-9][0-9.,]{3,})', caseSensitive: false),
    ];

    double? best;
    for (final pattern in totalPatterns) {
      for (final line in lines) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final val = _parseAmount(match.group(1)!);
          if (val != null && val > 0) {
            if (best == null || val > best) {
              best = val;
            }
          }
        }
      }
      if (best != null && totalPatterns.indexOf(pattern) < 3) { break; }
    }
    return best;
  }

  // ── Item Extraction ───────────────────────────────────────────────────────

  static List<ReceiptItem> _extractItems(List<String> lines) {
    final items = <ReceiptItem>[];

    // Baris yang harus dilewati (header / footer struk)
    final skipPatterns = RegExp(
      r'(?:struk|receipt|terima\s*kasih|thank\s*you|nota|invoice|kasir|cashier|'
      r'npwp|no\.?\s*trans|tanggal|date|jam|time|address|alamat|telepon|phone|'
      r'website|email|instagram|follow|powered|aplikasi|app|version|versi|'
      r'member|point|poin|diskon\s*member|'
      r'grand\s*total|total\s*bayar|jumlah\s*bayar|total\s*tagihan|'
      r'kembalian|change|kembali|tunai|cash|debit|kredit|credit|qris|'
      r'payment|lunas|paid)',
      caseSensitive: false,
    );

    // Pola 1: "NAMA ITEM   2 x 5.000   10.000"
    final patternQtyUnitTotal = RegExp(
      r'^(.+?)\s+(\d+)\s*[xX×]\s*(?:rp\.?\s*)?([0-9][0-9.,]+)\s+(?:rp\.?\s*)?([0-9][0-9.,]+)\s*$',
    );

    // Pola Khusus: Pajak, PB1, PPN, Service Charge, Biaya Layanan, Ongkir, Pembulatan
    final patternFeeLine = RegExp(
      r'^(?:biaya\s*)?(pajak.*?|ppn.*?|pb\s*1.*?|pb01.*?|tax.*?|service(?:\s*charge)?.*?|layanan.*?|ongkir.*?|pembulatan.*?|diskon.*?|potongan.*?)(?:[:\s]+)(?:rp\.?\s*)?([0-9][0-9.,]+)\s*$',
      caseSensitive: false,
    );

    // Pola 2: "NAMA ITEM   10.000"  (qty=1, tanpa satuan)
    final patternNameTotal = RegExp(
      r'^(.+?)\s{2,}(?:rp\.?\s*)?([0-9][0-9.,]{2,})\s*$',
    );

    // Pola 3: "NAMA ITEM .............. 10.000"
    final patternDottedTotal = RegExp(
      r'^(.+?)\s*\.{3,}\s*(?:rp\.?\s*)?([0-9][0-9.,]{2,})\s*$',
    );

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Skip baris header/footer
      if (skipPatterns.hasMatch(line)) continue;
      // Skip baris terlalu pendek
      if (line.length < 4) continue;
      // Skip baris yang isinya hanya angka / simbol
      if (RegExp(r'^[\d\s.,\-=*#@]+$').hasMatch(line)) continue;

      // Cek apakah baris ini adalah Pajak / Service / Layanan
      final mFee = patternFeeLine.firstMatch(line);
      if (mFee != null) {
        final feeName = _cleanName(mFee.group(1)!);
        final feeTotal = _parseAmount(mFee.group(2)!) ?? 0;
        if (feeName.isNotEmpty && feeTotal > 0) {
          items.add(ReceiptItem(name: feeName, qty: 1, unitPrice: feeTotal, total: feeTotal));
          continue;
        }
      }

      // Coba Pola 1: qty × unit = total
      final m1 = patternQtyUnitTotal.firstMatch(line);
      if (m1 != null) {
        final name = _cleanName(m1.group(1)!);
        final qty = int.tryParse(m1.group(2)!) ?? 1;
        final unit = _parseAmount(m1.group(3)!) ?? 0;
        final total = _parseAmount(m1.group(4)!) ?? 0;
        if (name.isNotEmpty && total > 0) {
          items.add(ReceiptItem(name: name, qty: qty, unitPrice: unit, total: total));
          continue;
        }
      }

      // Coba Pola 3: nama ........ harga
      final m3 = patternDottedTotal.firstMatch(line);
      if (m3 != null) {
        final name = _cleanName(m3.group(1)!);
        final total = _parseAmount(m3.group(2)!) ?? 0;
        if (name.isNotEmpty && total > 0) {
          items.add(ReceiptItem(name: name, qty: 1, unitPrice: total, total: total));
          continue;
        }
      }

      // Coba Pola 2: nama   harga
      final m2 = patternNameTotal.firstMatch(line);
      if (m2 != null) {
        final name = _cleanName(m2.group(1)!);
        final total = _parseAmount(m2.group(2)!) ?? 0;
        // Hindari angka yang mungkin nomor struk / tanggal (terlalu kecil)
        if (name.isNotEmpty && total >= 100) {
          items.add(ReceiptItem(name: name, qty: 1, unitPrice: total, total: total));
          continue;
        }
      }

      // Pola 4: baris nama saja, lalu baris berikut berisi "N x Rp.XXX"
      if (i + 1 < lines.length) {
        final nextLine = lines[i + 1].trim();
        final mQty = RegExp(
          r'^(\d+)\s*[xX×]\s*(?:rp\.?\s*)?([0-9][0-9.,]+)(?:\s+(?:rp\.?\s*)?([0-9][0-9.,]+))?',
          caseSensitive: false,
        ).firstMatch(nextLine);
        if (mQty != null) {
          final name = _cleanName(line);
          final qty = int.tryParse(mQty.group(1)!) ?? 1;
          final unit = _parseAmount(mQty.group(2)!) ?? 0;
          final total = _parseAmount(mQty.group(3) ?? '') ?? unit * qty;
          if (name.isNotEmpty && unit > 0) {
            items.add(ReceiptItem(name: name, qty: qty, unitPrice: unit, total: total));
            i++; // lewati baris berikut
            continue;
          }
        }
      }
    }

    // Deduplicate & filter item noise
    return _filterItems(items);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Bersihkan nama item dari karakter tak perlu
  static String _cleanName(String raw) {
    return raw
        .replaceAll(RegExp(r'[*@#\-=|]+'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  /// Parse string harga menjadi double (handle titik ribuan & koma desimal)
  static double? _parseAmount(String raw) {
    if (raw.isEmpty) return null;
    // Contoh input: "10.500", "10,500", "10.500,00", "10500"
    String cleaned = raw.trim();
    // Jika ada koma di akhir (desimal Indonesia): "10.500,00" → "10500"
    if (cleaned.contains(',')) {
      // Koma adalah desimal → hapus titik ribuan, ganti koma jadi titik
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else {
      // Titik mungkin ribuan → hapus saja
      cleaned = cleaned.replaceAll('.', '');
    }
    // Hapus karakter non-numeric kecuali titik
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned);
  }

  /// Filter item yang tidak masuk akal (duplikat nama, harga 0, nama terlalu pendek)
  static List<ReceiptItem> _filterItems(List<ReceiptItem> items) {
    final seen = <String>{};
    final result = <ReceiptItem>[];
    for (final item in items) {
      if (item.effectiveTotal <= 0) continue;
      if (item.name.length < 2) continue;

      // Tolak baris yang murni tender uang atau ringkasan grand total struk
      final lowerName = item.name.toLowerCase().trim();
      if (RegExp(
        r'^(?:total|grand\s*total|total\s*bayar|jumlah\s*bayar|subtotal|sub\s*total|kembalian|change|kembali|tunai|cash|debit|kredit|credit|qris|bayar)$',
      ).hasMatch(lowerName)) {
        continue;
      }

      final key = '${item.name.toLowerCase()}|${item.effectiveTotal}';
      if (seen.contains(key)) continue;
      seen.add(key);
      result.add(item);
    }
    return result;
  }
}

/// Hasil parse satu struk
class ReceiptParseResult {
  final String? merchant;
  final List<ReceiptItem> items;
  final double? grandTotal;

  const ReceiptParseResult({
    this.merchant,
    required this.items,
    this.grandTotal,
  });

  bool get hasItems => items.isNotEmpty;

  /// Kategori default berdasarkan merchant
  String get suggestedCategory {
    if (merchant == null) return 'Belanja';
    final lower = merchant!.toLowerCase();
    if (lower.contains('food') || lower.contains('kfc') || lower.contains('mcd') ||
        lower.contains('pizza') || lower.contains('burger') || lower.contains('jco') ||
        lower.contains('starbucks') || lower.contains('chatime') ||
        lower.contains('hokben') || lower.contains('solaria')) {
      return 'Makanan';
    }
    if (lower.contains('gofood') || lower.contains('grabfood') || lower.contains('shopee')) {
      return 'Makanan';
    }
    if (lower.contains('apotek') || lower.contains('kimia') || lower.contains('century') ||
        lower.contains('guardian') || lower.contains('watson')) {
      return 'Kesehatan';
    }
    if (lower.contains('gojek') || lower.contains('grab') || lower.contains('transjakarta') ||
        lower.contains('krl')) {
      return 'Transport';
    }
    return 'Belanja';
  }
}
