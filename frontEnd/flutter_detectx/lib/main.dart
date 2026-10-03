import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'config/api_config.dart';
import 'providers/auth_provider.dart';
import 'providers/simulation_provider.dart';
import 'providers/alertes_provider.dart';
import 'providers/regles_provider.dart';
import 'providers/utilisateurs_provider.dart';
import 'providers/journaux_provider.dart';
import 'providers/evaluations_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/historique_provider.dart';
import 'routes/app_router.dart';
import 'theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await windowManager.ensureInitialized();

  // Affiche l'URL API détectée au démarrage
  print('[APP] URL API détectée automatiquement: ${ApiConfig.baseUrl}');

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(1100, 700),
    center: true,
    title: 'FlowDetectX',
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(FlowDetectXApp(authProvider: authProvider));
}

class FlowDetectXApp extends StatelessWidget {
  const FlowDetectXApp({required this.authProvider, super.key});

  final AuthProvider authProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => SimulationProvider()),
        ChangeNotifierProvider(create: (_) => AlertesProvider()),
        ChangeNotifierProvider(create: (_) => ReglesProvider()),
        ChangeNotifierProvider(create: (_) => UtilisateursProvider()),
        ChangeNotifierProvider(create: (_) => JournauxProvider()),
        ChangeNotifierProvider(create: (_) => EvaluationsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => HistoriqueProvider()),
      ],
      child: MaterialApp.router(
        title: 'FlowDetectX',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: createAppRouter(authProvider),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('fr', 'FR'),
        ],
        locale: const Locale('fr', 'FR'),
      ),
    );
  }
}
