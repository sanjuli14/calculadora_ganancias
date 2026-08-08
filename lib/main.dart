import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:calcular_ganancias/services/database_service.dart';
import 'package:calcular_ganancias/services/auth_service.dart';
import 'package:calcular_ganancias/theme/app_theme.dart';
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

  final showOnboarding = !databaseService.onboardingSeen;
  // Si ya hay una sesión activa (el teléfono conserva el login), se entra
  // directo a la pantalla principal. Esto evita que al volver del selector
  // de archivos (que puede reiniciar la app) se pida login otra vez.
  final alreadyLoggedIn = authService.isLoggedIn;

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        Provider<AuthService>.value(value: authService),
      ],
      child: MyApp(
        showOnboarding: showOnboarding,
        alreadyLoggedIn: alreadyLoggedIn,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  final bool alreadyLoggedIn;

  const MyApp({
    super.key,
    required this.showOnboarding,
    required this.alreadyLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    Widget home;
    if (showOnboarding) {
      home = const OnboardingScreen();
    } else if (alreadyLoggedIn) {
      home = const MainScreen();
    } else {
      home = const LoginScreen();
    }

    return MaterialApp(
      title: 'Cuentas Claras',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: home,
    );
  }
}
