import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../notifiers/nav_notifier.dart';
import '../services/database_service.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import 'dashboard_screen.dart';
import 'inventory_screen.dart';
import 'sell_screen.dart';
import 'gains_screen.dart';
import 'cashbox_screen.dart';
import 'transfer_accounts_screen.dart';
import 'categories_screen.dart';
import 'calculator_screen.dart';
import 'daily_inventory_screen.dart';
import 'expenses_screen.dart';
import 'appearance_screen.dart';
import 'publication_settings_screen.dart';

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
    final db = Provider.of<DatabaseService>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: AppColors.navy),
            tooltip: 'Menú',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const AppLogo(fontSize: 20),
        actions: [
          if (nav.index == 1)
            Builder(
              builder: (innerContext) => IconButton(
                icon: Icon(Icons.share, color: AppColors.navy),
                tooltip: 'Compartir publicación',
                onPressed: () =>
                    _shareInventoryPublication(innerContext, db, messenger),
              ),
            ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DrawerHeader(),
              const _DrawerSectionLabel('Cuentas'),
              _DrawerItem(
                icon: Icons.today_outlined,
                iconColor: AppColors.emerald,
                label: 'Inventario Diario',
                onTap: () {
                  Navigator.of(context).pop();
                  _handleMenuAction(messenger, db, context, 'daily_inventory');
                },
              ),
              _DrawerItem(
                icon: Icons.money_off_outlined,
                iconColor: AppColors.warning,
                label: 'Gastos',
                onTap: () {
                  Navigator.of(context).pop();
                  _handleMenuAction(messenger, db, context, 'expenses');
                },
              ),
              _DrawerItem(
                icon: Icons.account_balance_outlined,
                iconColor: AppColors.navy,
                label: 'Cuentas de Transferencia',
                onTap: () {
                  Navigator.of(context).pop();
                  _handleMenuAction(
                    messenger,
                    db,
                    context,
                    'transfer_accounts',
                  );
                },
              ),
              _DrawerItem(
                icon: Icons.category_outlined,
                iconColor: AppColors.navy,
                label: 'Categorías de Productos',
                onTap: () {
                  Navigator.of(context).pop();
                  _handleMenuAction(messenger, db, context, 'categories');
                },
              ),
              _DrawerItem(
                icon: Icons.calculate_outlined,
                iconColor: AppColors.turquoise,
                label: 'Calculadora',
                onTap: () {
                  Navigator.of(context).pop();
                  _handleMenuAction(messenger, db, context, 'calculator');
                },
              ),
              _DrawerItem(
                icon: Icons.palette_outlined,
                iconColor: AppColors.navy,
                label: 'Personalización',
                onTap: () {
                  Navigator.of(context).pop();
                  _handleMenuAction(messenger, db, context, 'appearance');
                },
              ),
              const Divider(
                thickness: 1,
                height: 24,
                indent: 20,
                endIndent: 20,
              ),
              const _DrawerSectionLabel('Compartir'),
              _DrawerItem(
                icon: Icons.campaign_outlined,
                iconColor: AppColors.turquoise,
                label: 'Publicación de inventario',
                onTap: () {
                  Navigator.of(context).pop();
                  _handleMenuAction(
                    messenger,
                    db,
                    context,
                    'publication_settings',
                  );
                },
              ),
              const Divider(
                thickness: 1,
                height: 24,
                indent: 20,
                endIndent: 20,
              ),
              const _DrawerSectionLabel('Respaldo de datos'),
              _DrawerItem(
                icon: Icons.save_alt,
                iconColor: AppColors.emerald,
                label: 'Hacer Backup',
                onTap: () {
                  Navigator.of(context).pop();
                  _handleMenuAction(messenger, db, context, 'backup');
                },
              ),
              _DrawerItem(
                icon: Icons.upload_file,
                iconColor: AppColors.navy,
                label: 'Exportar Copia',
                onTap: () {
                  Navigator.of(context).pop();
                  _handleMenuAction(messenger, db, context, 'export');
                },
              ),
              _DrawerItem(
                icon: Icons.download,
                iconColor: AppColors.navy,
                label: 'Importar Copia',
                onTap: () {
                  Navigator.of(context).pop();
                  _handleMenuAction(messenger, db, context, 'import');
                },
              ),
              const Spacer(),
              const _DrawerFooter(),
            ],
          ),
        ),
      ),
      body: IndexedStack(index: nav.index, children: _screens),
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

// Ejecuta la acción seleccionada en el menú lateral.
Future<void> _handleMenuAction(
  ScaffoldMessengerState messenger,
  DatabaseService db,
  BuildContext context,
  String value,
) async {
  if (value == 'transfer_accounts') {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute(builder: (_) => const TransferAccountsScreen()),
    );
  } else if (value == 'categories') {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute(builder: (_) => const CategoriesScreen()),
    );
  } else if (value == 'calculator') {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute(builder: (_) => const CalculatorScreen()),
    );
  } else if (value == 'daily_inventory') {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute(builder: (_) => const DailyInventoryScreen()),
    );
  } else if (value == 'expenses') {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute(builder: (_) => const ExpensesScreen()),
    );
  } else if (value == 'backup') {
    final ok = await db.makeBackup();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Copia guardada en Descargas/CuentasClaras'
              : 'No se pudo guardar la copia',
        ),
      ),
    );
  } else if (value == 'export') {
    await db.exportData();
    if (context.mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Copia de seguridad lista para compartir'),
        ),
      );
    }
  } else if (value == 'import') {
    await _showImportOptions(context, db);
  } else if (value == 'publication_settings') {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute(builder: (_) => const PublicationSettingsScreen()),
    );
  } else if (value == 'appearance') {
    final navigator = Navigator.of(context);
    await navigator.push(
      MaterialPageRoute(builder: (_) => const AppearanceScreen()),
    );
  }
}

// Comparte la lista de inventario (con fotos adjuntas) usando la plantilla
// configurada por el usuario en PublicationSettingsScreen.
Future<void> _shareInventoryPublication(
  BuildContext context,
  DatabaseService db,
  ScaffoldMessengerState messenger,
) async {
  final products = db.productsBox.values.toList();
  if (products.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Agrega productos antes de compartir')),
    );
    return;
  }
  try {
    final service = ShareService(db);
    final status = await service.sharePublication(products);
    if (status == ShareResultStatus.unavailable) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No hay app disponible para compartir')),
      );
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('No se pudo compartir: $e')));
  }
}

// Muestra un diálogo con las copias automáticas guardadas en el teléfono.
// Así se restaura desde dentro de la app, sin abrir el selector de archivos
// del sistema (que al volver reiniciaba la app y pedía login de nuevo).
Future<void> _showImportOptions(
  BuildContext context,
  DatabaseService db,
) async {
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
              Text(
                'Restaurar copia de seguridad',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Elige una copia guardada en este teléfono o selecciona un archivo.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              if (backups.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Aún no hay copias guardadas en este teléfono.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: backups.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final b = backups[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.description_outlined,
                          color: AppColors.navy,
                        ),
                        title: Text(
                          b['name'] ?? 'Copia',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        onTap: () =>
                            Navigator.of(sheetContext).pop('uri:${b['uri']}'),
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
                  side: BorderSide(color: AppColors.navy),
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
    messenger.showSnackBar(SnackBar(content: Text('Error al importar: $e')));
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDark, AppColors.navyLight],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: AppLogo(
              fontSize: 22,
              cuentasColor: Colors.white,
              clarasColor: AppColors.turquoise,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Inventario, ventas y ganancias claras',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerSectionLabel extends StatelessWidget {
  final String label;

  const _DrawerSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Text(
        'Cuentas Claras v1.5.2',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
      ),
    );
  }
}
