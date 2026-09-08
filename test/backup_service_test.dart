import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_rank/core/models/category_models.dart';
import 'package:life_rank/core/services/backup_service.dart';

void main() {
  const testUserId = '11111111-2222-3333-4444-555555555555';

  group('TransactionModel Note & Serialization Tests', () {
    test('TransactionModel reads note directly when provided', () {
      final json = {
        'id': 'test-id-1',
        'user_id': testUserId,
        'type': 'expense',
        'amount': 45000,
        'category': 'Makanan',
        'note': 'Nasi Padang Rendang',
        'date': '2026-09-08',
        'income_type': null,
      };

      final tx = TransactionModel.fromJson(json);
      expect(tx.category, 'Makanan');
      expect(tx.note, 'Nasi Padang Rendang');
      expect(tx.type, 'expense');
      expect(tx.amount, 45000.0);

      final exported = tx.toJson();
      expect(exported['category'], 'Makanan');
      expect(exported['note'], 'Nasi Padang Rendang');
    });

    test('TransactionModel automatically extracts note from legacy "Category — Note" format', () {
      final json = {
        'id': 'test-id-2',
        'user_id': testUserId,
        'type': 'expense',
        'amount': 25000,
        'category': 'Makanan — Ayam Geprek Sambal Matah',
        'note': null,
        'date': '2026-09-08',
      };

      final tx = TransactionModel.fromJson(json);
      expect(tx.category, 'Makanan');
      expect(tx.note, 'Ayam Geprek Sambal Matah');
    });
  });

  group('BackupService Structured Import Tests', () {
    test('Parses new structured CSV with explicit note for expense and income', () async {
      const csvData = '''id,type,category,note,amount,income_type,date
uuid-1,expense,Makanan,Makan Siang Sate Padang,35000,,2026-09-01
uuid-2,income,Gaji,Gaji Bulanan PT Maju,12000000,fixed,2026-09-01
uuid-3,income,Freelance,Desain Logo Brand,2500000,side,2026-09-02
uuid-4,saving,Tabungan,Dana Darurat BCA,1000000,,2026-09-03
uuid-5,investment,Investasi,Saham BBCA,1500000,,2026-09-04
''';

      final result = await BackupService.parseCsvContent(
        csvData,
        testUserId,
        saveToDatabase: false,
      );

      expect(result.totalRows, 5);
      expect(result.successCount, 5);
      expect(result.skippedCount, 0);
      expect(result.errorCount, 0);

      // Financial accuracy
      expect(result.totalExpense, 35000.0);
      expect(result.totalIncome, 14500000.0);
      expect(result.totalSaving, 1000000.0);
      expect(result.totalInvestment, 1500000.0);

      // Category breakdown
      expect(result.categoryCounts['Makanan'], 1);
      expect(result.categoryCounts['Gaji'], 1);
      expect(result.categoryCounts['Freelance'], 1);
      expect(result.categoryAmounts['Makanan'], 35000.0);
    });

    test('Parses legacy CSV format where category has "Category — Note" string', () async {
      const legacyCsv = '''id,user_id,type,amount,category,date,income_type
,user-old,expense,50000,Transport — Bensin Motor Shell,2026-09-05,
,user-old,income,5000000,Gaji Pokok,2026-09-01,fixed
''';

      final result = await BackupService.parseCsvContent(
        legacyCsv,
        testUserId,
        saveToDatabase: false,
      );

      expect(result.totalRows, 2);
      expect(result.successCount, 2);
      expect(result.totalExpense, 50000.0);
      expect(result.totalIncome, 5000000.0);
      expect(result.categoryCounts['Transport'], 1);
      expect(result.categoryCounts['Gaji Pokok'], 1);
    });

    test('Supports Indonesian header aliases and currency formatting', () async {
      const indonesianCsv = '''tipe,kategori,keperluan,nominal,tanggal
pengeluaran,Tagihan,Bayar Listrik PLN,"Rp 250.000",2026-09-01
pemasukan,Sampingan,Jasa Konsultasi,"Rp 1.500.000",2026-09-02
investasi,Reksa Dana,Top up Bibit Pasar Uang,"Rp 500.000",2026-09-03
''';

      final result = await BackupService.parseCsvContent(
        indonesianCsv,
        testUserId,
        saveToDatabase: false,
      );

      expect(result.totalRows, 3);
      expect(result.successCount, 3);
      expect(result.totalExpense, 250000.0);
      expect(result.totalIncome, 1500000.0);
      expect(result.totalInvestment, 500000.0);
      expect(result.categoryCounts['Tagihan'], 1);
      expect(result.categoryCounts['Sampingan'], 1);
      expect(result.categoryCounts['Reksa Dana'], 1);
    });

    test('Handles malformed rows gracefully with validation errors report', () async {
      const malformedCsv = '''type,category,note,amount,date
expense,Makanan,Bakso,20000,2026-09-01
invalid_type,Makanan,Mie Ayam,15000,2026-09-01
expense,Belanja,Baju,-50000,2026-09-01
expense,Kesehatan,Obat,0,2026-09-01
expense,Hiburan,Bioskop,60000,2026-09-02
''';

      final result = await BackupService.parseCsvContent(
        malformedCsv,
        testUserId,
        saveToDatabase: false,
      );

      expect(result.totalRows, 5);
      expect(result.successCount, 2); // Baris 2 (Bakso) dan 6 (Bioskop)
      expect(result.skippedCount, 3);
      expect(result.errorCount, 3);
      expect(result.hasErrors, isTrue);
      expect(result.totalExpense, 80000.0);
    });

    test('Parses structured JSON backup with summary manifest', () async {
      final jsonData = {
        'version': '2.0',
        'app': 'LifeRank',
        'exported_at': '2026-09-08T12:00:00Z',
        'summary': {
          'total_transactions': 2,
          'total_income': 10000000,
          'total_expense': 75000,
        },
        'transactions': [
          {
            'id': 'uuid-json-1',
            'type': 'expense',
            'category': 'Makanan',
            'note': 'Makan Malam Sushi Tei',
            'amount': 75000,
            'date': '2026-09-08',
            'income_type': null,
          },
          {
            'id': 'uuid-json-2',
            'type': 'income',
            'category': 'Gaji',
            'note': 'Gaji Bulan September',
            'amount': 10000000,
            'date': '2026-09-01',
            'income_type': 'fixed',
          }
        ]
      };

      final result = await BackupService.parseJsonContent(
        jsonEncode(jsonData),
        testUserId,
        saveToDatabase: false,
      );

      expect(result.totalRows, 2);
      expect(result.successCount, 2);
      expect(result.totalExpense, 75000.0);
      expect(result.totalIncome, 10000000.0);
      expect(result.categoryCounts['Makanan'], 1);
      expect(result.categoryCounts['Gaji'], 1);
    });
  });
}
