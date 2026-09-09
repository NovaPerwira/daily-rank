import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Layanan untuk mengambil dan memperbarui kurs mata uang (USD ke IDR)
/// secara real-time dari internet dengan caching lokal offline.
class CurrencyService extends ChangeNotifier {
  CurrencyService._internal();
  static final CurrencyService instance = CurrencyService._internal();

  static const double fallbackRate = 16000.0;
  static const String _prefRateKey = 'cached_usd_to_idr_rate';
  static const String _prefTimeKey = 'cached_usd_to_idr_time';

  // Endpoint API gratis tanpa API key
  static const String _primaryApiUrl = 'https://open.er-api.com/v6/latest/USD';
  static const String _backupApiUrl = 'https://api.exchangerate-api.com/v4/latest/USD';

  static double _usdToIdr = fallbackRate;
  static DateTime? _lastUpdated;
  static bool _isLoading = false;
  static bool _isLive = false;

  /// Nilai kurs saat ini (1 USD = X IDR)
  static double get usdToIdr => _usdToIdr;

  /// Timestamp kapan kurs terakhir berhasil diperbarui dari internet
  static DateTime? get lastUpdated => _lastUpdated;

  /// True jika sedang proses fetching dari internet
  static bool get isLoading => _isLoading;

  /// True jika data berhasil diambil dari internet (bukan hanya nilai fallback)
  static bool get isLive => _isLive;

  /// Format kurs ke string yang rapi, contoh: "16.250"
  static String get formattedRate {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(_usdToIdr.round());
  }

  /// Format lengkap kurs, contoh: "1 USD = Rp 16.250"
  static String get formattedFullRate => '1 USD = Rp $formattedRate';

  /// Inisialisasi: memuat kurs dari cache lokal dan melakukan fetch real-time
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRate = prefs.getDouble(_prefRateKey);
      final cachedTimeStr = prefs.getString(_prefTimeKey);

      if (cachedRate != null && cachedRate > 0) {
        _usdToIdr = cachedRate;
        _isLive = true;
      }

      if (cachedTimeStr != null) {
        _lastUpdated = DateTime.tryParse(cachedTimeStr);
      }
    } catch (e) {
      debugPrint('[CurrencyService] Gagal memuat cache kurs: $e');
    }

    // Ambil kurs terkini secara asinkron tanpa memblokir startup aplikasi
    fetchRate();
  }

  /// Mengambil kurs USD -> IDR terkini dari internet.
  /// Jika [force] = false, hanya akan fetch jika data lebih dari 30 menit yang lalu.
  static Future<double> fetchRate({bool force = false}) async {
    // Jika tidak dipaksa dan data masih segar (< 30 menit), gunakan data saat ini
    if (!force && _lastUpdated != null) {
      final difference = DateTime.now().difference(_lastUpdated!);
      if (difference.inMinutes < 30) {
        return _usdToIdr;
      }
    }

    if (_isLoading) return _usdToIdr;
    _isLoading = true;
    instance.notifyListeners();

    try {
      double? fetchedRate;

      // 1. Coba Primary API (open.er-api.com)
      try {
        final response = await http
            .get(Uri.parse(_primaryApiUrl))
            .timeout(const Duration(seconds: 7));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map && data['rates'] is Map) {
            final rawIdr = data['rates']['IDR'];
            if (rawIdr is num && rawIdr > 0) {
              fetchedRate = rawIdr.toDouble();
            }
          }
        }
      } catch (e) {
        debugPrint('[CurrencyService] Primary API gagal ($e), mencoba backup...');
      }

      // 2. Coba Backup API jika primary gagal
      if (fetchedRate == null) {
        try {
          final response = await http
              .get(Uri.parse(_backupApiUrl))
              .timeout(const Duration(seconds: 7));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data is Map && data['rates'] is Map) {
              final rawIdr = data['rates']['IDR'];
              if (rawIdr is num && rawIdr > 0) {
                fetchedRate = rawIdr.toDouble();
              }
            }
          }
        } catch (e) {
          debugPrint('[CurrencyService] Backup API gagal: $e');
        }
      }

      // 3. Validasi & simpan kurs yang berhasil diambil
      if (fetchedRate != null && fetchedRate > 5000 && fetchedRate < 50000) {
        _usdToIdr = fetchedRate;
        _lastUpdated = DateTime.now();
        _isLive = true;

        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble(_prefRateKey, _usdToIdr);
          await prefs.setString(_prefTimeKey, _lastUpdated!.toIso8601String());
        } catch (e) {
          debugPrint('[CurrencyService] Gagal menyimpan cache kurs: $e');
        }
      }
    } catch (e) {
      debugPrint('[CurrencyService] Terjadi kesalahan saat fetch kurs: $e');
    } finally {
      _isLoading = false;
      instance.notifyListeners();
    }

    return _usdToIdr;
  }

  /// Konversi IDR ke USD dengan kurs real-time
  static double idrToUsd(double idrAmount) => idrAmount / _usdToIdr;

  /// Konversi USD ke IDR dengan kurs real-time
  static double usdToIdrAmount(double usdAmount) => usdAmount * _usdToIdr;

  /// Set kurs secara manual (misal untuk testing / mock)
  @visibleForTesting
  static void setMockRate(double rate, {bool isLive = true, DateTime? lastUpdated}) {
    _usdToIdr = rate;
    _isLive = isLive;
    _lastUpdated = lastUpdated ?? DateTime.now();
    instance.notifyListeners();
  }
}
