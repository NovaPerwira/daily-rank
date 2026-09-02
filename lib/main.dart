import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'core/router/app_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'features/auth/providers/auth_provider.dart';

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
      systemNavigationBarColor: Color(0xFF111827),
    ),
  );

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize DateFormatting for id_ID
  await initializeDateFormatting('id_ID', null);

  runApp(const LifeRankApp());
}

class LifeRankApp extends StatelessWidget {
  const LifeRankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
