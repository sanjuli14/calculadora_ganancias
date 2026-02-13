import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:calcular_ganancias/services/database_service.dart';
import 'package:calcular_ganancias/screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final databaseService = DatabaseService();
  await databaseService.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora de Ganancias',
      theme: ThemeData(
        fontFamily: 'Poppins',
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFfff2e1),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFa79277),
          brightness: Brightness.light,
          primary: const Color(0xFFa79277),
          secondary: const Color(0xFFa79277),
          surface: const Color(0xFFfff2e1),
          onSurface: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFFa79277),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFFf5f5f5), // Slightly darker for cards in light theme
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: const Color(0xFFe8e8e8),
          labelStyle: const TextStyle(color: Colors.black54),
          prefixIconColor: const Color(0xFFa79277),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFa79277),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: const Color(0xFFa79277),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
