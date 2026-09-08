import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Ringkasan terukur dari hasil proses import data transaksi
class ImportResult {
  final int totalRows;
  final int successCount;
  final int skippedCount;
  final int errorCount;
  final double totalIncome;
  final double totalExpense;
  final double totalSaving;
  final double totalInvestment;
  final Map<String, int> categoryCounts;
  final Map<String, double> categoryAmounts;
  final List<String> validationErrors;

  const ImportResult({
    required this.totalRows,
    required this.successCount,
    required this.skippedCount,
    required this.errorCount,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalSaving,
    required this.totalInvestment,
    required this.categoryCounts,
    required this.categoryAmounts,
    required this.validationErrors,
  });

  bool get hasErrors => validationErrors.isNotEmpty;
  bool get isEmpty => successCount == 0 && errorCount == 0;
}

class BackupService {
  static final _supabase = Supabase.instance.client;
  static final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  // ──────────────────────────────────────────────────────────────────────────
  // EXPORT TRANSAKSI
  // ──────────────────────────────────────────────────────────────────────────

  /// Exports the user's transactions to a structured CSV or JSON file.
  /// Standard headers include: id, type, category, note, amount, income_type, date
  /// where 'note' explicitly details what the expense was for or where income came from.
  static Future<void> exportTransactions(
    String userId, {
    bool isJson = false,
  }) async {
    if (isJson) {
      await exportTransactionsJson(userId);
    } else {
      await exportTransactionsCsv(userId);
    }
  }

  /// Exports transactions to a standardized CSV file
  static Future<void> exportTransactionsCsv(String userId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      List<List<dynamic>> rows = [];

      // Add Standardized Headers
      rows.add([
        "id",
        "type",
        "category",
        "note",
        "amount",
        "income_type",
        "date",
      ]);

      // Add Data Rows
      for (var row in response) {
        final rawCat = row['category'] as String?;
        String? cat = rawCat;
        String? note = row['note'] as String?;

        // Fallback backward-compatibility: extract note if category was "Category — Note"
        if ((note == null || note.trim().isEmpty) &&
            rawCat != null &&
            rawCat.contains(' — ')) {
          final parts = rawCat.split(' — ');
          cat = parts[0].trim();
          note = parts.sublist(1).join(' — ').trim();
        }

        rows.add([
          row['id'] ?? '',
          row['type'] ?? 'expense',
          cat ?? '',
          note ?? '',
          row['amount'] ?? 0,
          row['income_type'] ?? '',
          row['date'] ?? '',
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);

      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'transactions_backup_$dateStr.csv';

      await _shareFile(
        fileName: fileName,
        content: csvData,
        mimeType: 'text/csv',
        subject: 'Life Rank - Transactions Backup (CSV)',
      );
    } catch (e) {
      throw Exception('Gagal mengekspor transaksi ke CSV: $e');
    }
  }

  /// Exports transactions to a structured JSON file with manifest & summary
  static Future<void> exportTransactionsJson(String userId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('date', ascending: false);

      double totalIncome = 0;
      double totalExpense = 0;
      double totalSaving = 0;
      double totalInvestment = 0;

      final List<Map<String, dynamic>> items = [];

      for (var row in response) {
        final type = (row['type'] ?? 'expense').toString();
        final amount = ((row['amount'] ?? 0) as num).toDouble();
        final rawCat = row['category'] as String?;
        String? cat = rawCat;
        String? note = row['note'] as String?;

        if ((note == null || note.trim().isEmpty) &&
            rawCat != null &&
            rawCat.contains(' — ')) {
          final parts = rawCat.split(' — ');
          cat = parts[0].trim();
          note = parts.sublist(1).join(' — ').trim();
        }

        switch (type) {
          case 'income':
            totalIncome += amount;
            break;
          case 'expense':
            totalExpense += amount;
            break;
          case 'saving':
            totalSaving += amount;
            break;
          case 'investment':
            totalInvestment += amount;
            break;
        }

        items.add({
          'id': row['id'],
          'type': type,
          'category': cat ?? '',
          'note': note ?? '', // Pengeluaran untuk apa / pemasukan dari apa
          'amount': amount.round(),
          'income_type': row['income_type'],
          'date': row['date'],
        });
      }

      final backupData = {
        'version': '2.0',
        'app': 'LifeRank',
        'exported_at': DateTime.now().toIso8601String(),
        'summary': {
          'total_transactions': items.length,
          'total_income': totalIncome,
          'total_expense': totalExpense,
          'total_saving': totalSaving,
          'total_investment': totalInvestment,
        },
        'transactions': items,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'transactions_backup_$dateStr.json';

      await _shareFile(
        fileName: fileName,
        content: jsonString,
        mimeType: 'application/json',
        subject: 'Life Rank - Transactions Backup (JSON)',
      );
    } catch (e) {
      throw Exception('Gagal mengekspor transaksi ke JSON: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // IMPORT TRANSAKSI (TERUKUR & ROBUST)
  // ──────────────────────────────────────────────────────────────────────────

  /// Backwards-compatible import method returning the number of successful imports
  static Future<int> importTransactions(String userId) async {
    final result = await importTransactionsWithReport(userId);
    return result?.successCount ?? 0;
  }

  /// Prompts user to select a CSV or JSON file, validates and parses every row,
  /// upserts to database in batches, and returns a comprehensive ImportResult.
  static Future<ImportResult?> importTransactionsWithReport(String userId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json'],
        withData: true, // Required for Web
      );

      if (result == null || result.files.isEmpty) {
        return null; // User cancelled
      }

      final pickedFile = result.files.single;
      final extension = pickedFile.extension?.toLowerCase() ?? '';
      String fileContent;

      if (kIsWeb) {
        if (pickedFile.bytes == null) throw Exception("Gagal membaca file di web.");
        fileContent = utf8.decode(pickedFile.bytes!);
      } else {
        if (pickedFile.path == null) throw Exception("Gagal mendapatkan path file.");
        final file = File(pickedFile.path!);
        fileContent = await file.readAsString();
      }

      if (fileContent.trim().isEmpty) {
        throw Exception('File backup yang dipilih kosong.');
      }

      if (extension == 'json' || fileContent.trim().startsWith('{') || fileContent.trim().startsWith('[')) {
        return await parseJsonContent(fileContent, userId, saveToDatabase: true);
      } else {
        return await parseCsvContent(fileContent, userId, saveToDatabase: true);
      }
    } catch (e) {
      throw Exception('Gagal memproses import transaksi: $e');
    }
  }

  // ── Helper: Parse & Process CSV ───────────────────────────────────────────

  static Future<ImportResult> parseCsvContent(
    String csvString,
    String userId, {
    bool saveToDatabase = true,
  }) async {
    final normalizedContent = csvString.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final fields = const CsvToListConverter(eol: '\n', shouldParseNumbers: false)
        .convert(normalizedContent);

    if (fields.isEmpty) {
      throw Exception('File CSV tidak memiliki data.');
    }

    final rawHeaders = fields.first.map((e) => e.toString().trim()).toList();
    final headerMap = <String, int>{};

    for (int i = 0; i < rawHeaders.length; i++) {
      final key = _mapHeader(rawHeaders[i]);
      if (key != null && !headerMap.containsKey(key)) {
        headerMap[key] = i;
      }
    }

    List<Map<String, dynamic>> rawRows = [];
    for (int i = 1; i < fields.length; i++) {
      final row = fields[i];
      if (row.isEmpty || (row.length == 1 && row[0].toString().trim().isEmpty)) {
        continue;
      }

      final rowMap = <String, dynamic>{};
      for (final entry in headerMap.entries) {
        if (entry.value < row.length) {
          rowMap[entry.key] = row[entry.value];
        }
      }
      rawRows.add(rowMap);
    }

    return await processRecords(rawRows, userId, saveToDatabase: saveToDatabase);
  }

  // ── Helper: Parse & Process JSON ──────────────────────────────────────────

  static Future<ImportResult> parseJsonContent(
    String jsonString,
    String userId, {
    bool saveToDatabase = true,
  }) async {
    final dynamic decoded = jsonDecode(jsonString);
    List<dynamic> itemsList = [];

    if (decoded is List) {
      itemsList = decoded;
    } else if (decoded is Map && decoded.containsKey('transactions')) {
      itemsList = decoded['transactions'] as List;
    } else if (decoded is Map && decoded.containsKey('data')) {
      itemsList = decoded['data'] as List;
    } else {
      throw Exception('Format JSON backup tidak valid (harus array atau memiliki objek transactions).');
    }

    List<Map<String, dynamic>> rawRows = [];
    for (var item in itemsList) {
      if (item is Map) {
        final rowMap = <String, dynamic>{};
        item.forEach((k, v) {
          final mappedKey = _mapHeader(k.toString());
          if (mappedKey != null) {
            rowMap[mappedKey] = v;
          }
        });
        rawRows.add(rowMap);
      }
    }

    return await processRecords(rawRows, userId, saveToDatabase: saveToDatabase);
  }

  // ── Core: Process, Validate & Upsert to Supabase ───────────────────────────

  static Future<ImportResult> processRecords(
    List<Map<String, dynamic>> rawRows,
    String userId, {
    bool saveToDatabase = true,
  }) async {
    int totalRows = rawRows.length;
    int skippedCount = 0;
    List<String> validationErrors = [];
    List<Map<String, dynamic>> recordsToInsert = [];

    double totalIncome = 0;
    double totalExpense = 0;
    double totalSaving = 0;
    double totalInvestment = 0;
    final Map<String, int> categoryCounts = {};
    final Map<String, double> categoryAmounts = {};

    for (int i = 0; i < rawRows.length; i++) {
      final row = rawRows[i];
      final rowNum = i + 2; // Line 1 is header

      // 1. Parse & Normalize Type
      final normalizedType = _normalizeType(row['type']);
      if (normalizedType == null) {
        validationErrors.add('Baris $rowNum: Tipe transaksi tidak dikenal ("${row['type']}")');
        skippedCount++;
        continue;
      }

      // 2. Parse & Normalize Amount
      final amount = _parseAmount(row['amount']);
      if (amount == null || amount <= 0) {
        validationErrors.add('Baris $rowNum: Nominal transaksi tidak valid ("${row['amount']}")');
        skippedCount++;
        continue;
      }

      // 3. Parse & Normalize Date
      final date = _parseDate(row['date']) ?? DateTime.now();

      // 4. Parse Category & Note (Pengeluaran untuk apa / Pemasukan dari apa)
      String rawCategory = (row['category'] ?? '').toString().trim();
      String? note = (row['note'] != null && row['note'].toString().trim().isNotEmpty)
          ? row['note'].toString().trim()
          : null;

      // Backward-compatible fallback: jika note kosong tapi category mengandung ' — '
      if ((note == null || note.isEmpty) && rawCategory.contains(' — ')) {
        final parts = rawCategory.split(' — ');
        rawCategory = parts[0].trim();
        note = parts.sublist(1).join(' — ').trim();
      }

      if (rawCategory.isEmpty) {
        rawCategory = switch (normalizedType) {
          'income' => 'Pemasukan',
          'expense' => 'Pengeluaran',
          'saving' => 'Tabungan',
          'investment' => 'Investasi',
          _ => 'Lain-lain',
        };
      }

      // 5. Parse Income Type
      String? cleanIncomeType;
      if (normalizedType == 'income') {
        final rawIt = row['income_type']?.toString().trim().toLowerCase();
        if (rawIt == 'side' || rawIt == 'sampingan' || rawIt == 'freelance' || rawIt == 'bonus') {
          cleanIncomeType = 'side';
        } else {
          cleanIncomeType = 'fixed';
        }
      }

      // 6. Normalize ID (ensure valid UUID)
      final id = _normalizeId(row['id']);

      // 7. Track Statistics
      switch (normalizedType) {
        case 'income':
          totalIncome += amount;
          break;
        case 'expense':
          totalExpense += amount;
          break;
        case 'saving':
          totalSaving += amount;
          break;
        case 'investment':
          totalInvestment += amount;
          break;
      }

      categoryCounts[rawCategory] = (categoryCounts[rawCategory] ?? 0) + 1;
      categoryAmounts[rawCategory] = (categoryAmounts[rawCategory] ?? 0) + amount;

      recordsToInsert.add({
        'id': id,
        'user_id': userId,
        'type': normalizedType,
        'amount': amount.round(),
        'category': rawCategory,
        'note': note, // Catatan spesifik keperluan atau sumber dana
        'income_type': cleanIncomeType,
        'date': DateFormat('yyyy-MM-dd').format(date),
      });
    }

    // 8. Chunked Upsert to Supabase
    if (saveToDatabase && recordsToInsert.isNotEmpty) {
      const chunkSize = 100;
      for (var i = 0; i < recordsToInsert.length; i += chunkSize) {
        final end = (i + chunkSize < recordsToInsert.length)
            ? i + chunkSize
            : recordsToInsert.length;
        final chunk = recordsToInsert.sublist(i, end);
        await _supabase.from('transactions').upsert(chunk);
      }
    }

    return ImportResult(
      totalRows: totalRows,
      successCount: recordsToInsert.length,
      skippedCount: skippedCount,
      errorCount: validationErrors.length,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalSaving: totalSaving,
      totalInvestment: totalInvestment,
      categoryCounts: categoryCounts,
      categoryAmounts: categoryAmounts,
      validationErrors: validationErrors,
    );
  }

  // ── Helper: Map Header Aliases ────────────────────────────────────────────

  static String? _mapHeader(String header) {
    final h = header.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    if (['id', 'uuid', 'tx_id', 'transaction_id'].contains(h)) return 'id';
    if (['type', 'tipe', 'jenis', 'transaction_type', 'jenis_transaksi', 'kategori_arus'].contains(h)) return 'type';
    if (['category', 'kategori', 'pos', 'pos_anggaran'].contains(h)) return 'category';
    if ([
      'note',
      'notes',
      'catatan',
      'keterangan',
      'keperluan',
      'deskripsi',
      'description',
      'untuk_apa',
      'dari_apa',
      'sumber',
      'sumber_dana',
      'detail',
      'item',
      'rincian'
    ].contains(h)) {
      return 'note';
    }
    if (['amount', 'nominal', 'jumlah', 'total', 'nilai', 'harga', 'biaya', 'besar'].contains(h)) return 'amount';
    if (['income_type', 'tipe_pemasukan', 'jenis_pemasukan', 'sumber_pemasukan', 'income_source'].contains(h)) {
      return 'income_type';
    }
    if (['date', 'tanggal', 'tgl', 'waktu', 'tanggal_transaksi', 'created_at'].contains(h)) return 'date';
    return null;
  }

  // ── Helper: Normalizers ───────────────────────────────────────────────────

  static String? _normalizeType(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim().toLowerCase();
    if (['expense', 'pengeluaran', 'keluar', 'out', 'debit', 'belanja', 'biaya'].contains(s)) {
      return 'expense';
    }
    if (['income', 'pemasukan', 'masuk', 'in', 'credit', 'pendapatan', 'gaji'].contains(s)) {
      return 'income';
    }
    if (['saving', 'tabungan', 'simpanan', 'savings'].contains(s)) {
      return 'saving';
    }
    if (['investment', 'investasi', 'invest'].contains(s)) {
      return 'investment';
    }
    return null;
  }

  static double? _parseAmount(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    String s = raw.toString().trim();
    if (s.isEmpty) return null;

    s = s.replaceAll(RegExp(r'[rR][pP]\.?\s*'), '').replaceAll(RegExp(r'[iI][dD][rR]\s*'), '').trim();

    if (s.contains(',') && s.contains('.')) {
      if (s.lastIndexOf(',') > s.lastIndexOf('.')) {
        s = s.replaceAll('.', '').replaceAll(',', '.');
      } else {
        s = s.replaceAll(',', '');
      }
    } else if (s.contains('.')) {
      final parts = s.split('.');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        s = s.replaceAll('.', '');
      }
    } else if (s.contains(',')) {
      final parts = s.split(',');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        s = s.replaceAll(',', '');
      } else {
        s = s.replaceAll(',', '.');
      }
    }

    return double.tryParse(s);
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;

    final direct = DateTime.tryParse(s);
    if (direct != null) return direct;

    final dmyMatch = RegExp(r'^(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})').firstMatch(s);
    if (dmyMatch != null) {
      final d = int.tryParse(dmyMatch.group(1)!);
      final m = int.tryParse(dmyMatch.group(2)!);
      final y = int.tryParse(dmyMatch.group(3)!);
      if (d != null && m != null && y != null) {
        return DateTime(y, m, d);
      }
    }
    return null;
  }

  static String _normalizeId(dynamic raw) {
    if (raw != null) {
      final s = raw.toString().trim();
      if (_uuidRegex.hasMatch(s)) return s;
    }
    return const Uuid().v4();
  }

  static Future<void> _shareFile({
    required String fileName,
    required String content,
    required String mimeType,
    required String subject,
  }) async {
    if (kIsWeb) {
      final bytes = Uint8List.fromList(utf8.encode(content));
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: fileName, mimeType: mimeType)],
        text: subject,
      );
    } else {
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/$fileName";
      final file = File(path);
      await file.writeAsString(content);

      await Share.shareXFiles(
        [XFile(path)],
        text: subject,
      );
    }
  }
}

