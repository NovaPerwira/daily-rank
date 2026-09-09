import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'core/services/supabase_service.dart';
import 'core/services/currency_service.dart';
import 'core/router/app_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/cashflow/providers/boss_battle_provider.dart';
import 'features/cashflow/providers/gacha_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
    ),
  );

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize DateFormatting for id_ID
  await initializeDateFormatting('id_ID', null);

  // Initialize real-time currency exchange rate
  await CurrencyService.init();

  runApp(const LifeRankApp());
}

class LifeRankApp extends StatelessWidget {
  const LifeRankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BossBattleProvider()),
        ChangeNotifierProvider(create: (_) => GachaProvider()),
        ChangeNotifierProvider.value(value: CurrencyService.instance),
      ],
      child: Builder(
        builder: (ctx) {
          final router = createRouter(ctx);
          return MaterialApp.router(
            title: 'Life Rank',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
