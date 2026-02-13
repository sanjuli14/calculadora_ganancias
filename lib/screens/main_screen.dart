import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import 'inventory_screen.dart';
import 'sell_screen.dart';
import 'gains_screen.dart';
import 'summary_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    InventoryScreen(),
    SellScreen(),
    GainsScreen(),
    SummaryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Ganancias'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final db = Provider.of<DatabaseService>(context, listen: false);
              if (value == 'export') {
                await db.exportData();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copia de seguridad lista para compartir')));
              } else if (value == 'import') {
                try {
                  await db.importData();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Datos restaurados correctamente')));
                  setState(() {}); // Refresh UI
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al importar: $e')));
               }
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(
                  value: 'export',
                  child: Row(
                    children: [Icon(Icons.upload_file, color: Colors.blue), SizedBox(width: 8), Text('Exportar Copia')],
                  ),
                ),
                const PopupMenuItem(
                  value: 'import',
                  child: Row(
                    children: [Icon(Icons.download, color: Colors.green), SizedBox(width: 8), Text('Importar Copia')],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale),
            label: 'Vender',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Ganancias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Resumen',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.black54,
        onTap: _onItemTapped,
      ),
    );
  }
}
