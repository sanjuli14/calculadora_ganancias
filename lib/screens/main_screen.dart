import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../notifiers/nav_notifier.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'sell_screen.dart';
import 'gains_screen.dart';
import 'cashbox_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MainNavNotifier>(
      create: (_) => MainNavNotifier(),
      child: const _MainScreenBody(),
    );
  }
}

class _MainScreenBody extends StatelessWidget {
  const _MainScreenBody();

  static const List<Widget> _screens = [
    DashboardScreen(),
    InventoryScreen(),
    SellScreen(),
    GainsScreen(),
    CashBoxScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = Provider.of<MainNavNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const AppLogo(fontSize: 20),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final db = Provider.of<DatabaseService>(context, listen: false);
              if (value == 'export') {
                await db.exportData();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copia de seguridad lista para compartir')),
                  );
                }
              } else if (value == 'import') {
                try {
                  await db.importData();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Datos restaurados correctamente')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al importar: $e')),
                    );
                  }
                }
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [Icon(Icons.upload_file, color: AppColors.navy), SizedBox(width: 8), Text('Exportar Copia')],
                  ),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [Icon(Icons.download, color: AppColors.emerald), SizedBox(width: 8), Text('Importar Copia')],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: nav.index,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: nav.index,
        onDestinationSelected: (index) => nav.goTo(index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventario',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_shopping_cart_outlined),
            selectedIcon: Icon(Icons.add_shopping_cart),
            label: 'Vender',
          ),
          NavigationDestination(
            icon: Icon(Icons.trending_up_outlined),
            selectedIcon: Icon(Icons.trending_up),
            label: 'Ganancias',
          ),
          NavigationDestination(
            icon: Icon(Icons.payments_outlined),
            selectedIcon: Icon(Icons.payments),
            label: 'Caja',
          ),
        ],
      ),
    );
  }
}
