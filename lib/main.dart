import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:calcular_ganancias/services/database_service.dart';
import 'package:calcular_ganancias/services/auth_service.dart';
import 'package:calcular_ganancias/theme/app_theme.dart';
import 'package:calcular_ganancias/screens/login_screen.dart';
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

  final showOnboarding = !databaseService.onboardingSeen;

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        Provider<AuthService>.value(value: authService),
      ],
      child: MyApp(showOnboarding: showOnboarding),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;

  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cuentas Claras',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: showOnboarding ? const OnboardingScreen() : const LoginScreen(),
    );
  }
}
