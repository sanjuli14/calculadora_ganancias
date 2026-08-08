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
                await _showImportOptions(context, db);
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

// Muestra un diálogo con las copias automáticas guardadas en el teléfono.
// Así se restaura desde dentro de la app, sin abrir el selector de archivos
// del sistema (que al volver reiniciaba la app y pedía login de nuevo).
Future<void> _showImportOptions(BuildContext context, DatabaseService db) async {
  final backups = db.savedBackups;

  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Restaurar copia de seguridad',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Elige una copia guardada en este teléfono o selecciona un archivo.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (backups.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Aún no hay copias automáticas en este teléfono.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: backups.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final b = backups[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.description_outlined, color: AppColors.navy),
                        title: Text(
                          b['name'] ?? 'Copia',
                          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        ),
                        onTap: () => Navigator.of(sheetContext).pop('uri:${b['uri']}'),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(sheetContext).pop('picker'),
                icon: const Icon(Icons.folder_open, size: 18),
                label: const Text('Elegir otro archivo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.navy),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  if (action == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  try {
    if (action.startsWith('uri:')) {
      final uri = action.substring(4);
      await db.restoreFromUri(uri);
    } else {
      await db.importData();
    }
    messenger.showSnackBar(
      const SnackBar(content: Text('Datos restaurados correctamente')),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Error al importar: $e')),
    );
  }
}
