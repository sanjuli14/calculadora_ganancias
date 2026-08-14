import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:calcular_ganancias/services/database_service.dart';
import 'package:calcular_ganancias/services/auth_service.dart';
import 'package:calcular_ganancias/notifiers/theme_controller.dart';
import 'package:calcular_ganancias/theme/app_theme.dart';
import 'package:calcular_ganancias/theme/app_palettes.dart';
import 'package:calcular_ganancias/screens/login_screen.dart';
import 'package:calcular_ganancias/screens/main_screen.dart';
import 'package:calcular_ganancias/screens/onboarding_screen.dart';
import 'package:media_store_plus/media_store_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  MediaStore.appFolder = 'CuentasClaras';
  await MediaStore.ensureInitialized();

  final databaseService = DatabaseService();
  await databaseService.init();

  final authService = AuthService();
  await authService.init();

  final themeController = ThemeController(databaseService);
  await themeController.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final db = context.watch<DatabaseService>();
    final auth = context.watch<AuthService>();

    Widget home;
    if (!db.onboardingSeen) {
      home = const OnboardingScreen();
    } else if (auth.isLoggedIn) {
      home = const MainScreen();
    } else {
      home = const LoginScreen();
    }

    return MaterialApp(
      title: 'Cuentas Claras',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.forMode(themeController.mode),
      themeMode: AppTheme.themeModeOf(themeController.mode),
      darkTheme: AppTheme.forMode(AppThemeMode.dark),
      home: home,
    );
  }
}
