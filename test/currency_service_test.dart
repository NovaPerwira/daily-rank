import 'package:flutter_test/flutter_test.dart';
import 'package:life_rank/core/services/currency_service.dart';
import 'package:life_rank/core/constants/wealth_config.dart';
import 'package:life_rank/core/constants/financial_rank_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CurrencyService tests', () {
    test('Default fallback rate is 16000.0', () async {
      await CurrencyService.init();
      expect(CurrencyService.usdToIdr, 16000.0);
      expect(WealthConfig.usdToIdr, 16000.0);
      expect(FinancialRankCalculator.usdToIdr, 16000.0);
    });

    test('Loads cached rate from SharedPreferences if available', () async {
      SharedPreferences.setMockInitialValues({
        'cached_usd_to_idr_rate': 16350.0,
        'cached_usd_to_idr_time': DateTime.now().toIso8601String(),
      });

      await CurrencyService.init();
      expect(CurrencyService.usdToIdr, 16350.0);
      expect(WealthConfig.usdToIdr, 16350.0);
      expect(FinancialRankCalculator.usdToIdr, 16350.0);
      expect(CurrencyService.isLive, true);
    });

    test('Conversion math helper methods work properly', () async {
      SharedPreferences.setMockInitialValues({
        'cached_usd_to_idr_rate': 16000.0,
      });
      await CurrencyService.init();

      expect(CurrencyService.idrToUsd(16000000), 1000.0);
      expect(CurrencyService.usdToIdrAmount(100), 1600000.0);
      expect(CurrencyService.formattedRate, '16.000');
    });

    test('setMockRate updates the rate and notifies listeners', () {
      bool notified = false;
      CurrencyService.instance.addListener(() {
        notified = true;
      });

      CurrencyService.setMockRate(16500.0);
      expect(CurrencyService.usdToIdr, 16500.0);
      expect(CurrencyService.isLive, true);
      expect(notified, true);
    });
  });
}
