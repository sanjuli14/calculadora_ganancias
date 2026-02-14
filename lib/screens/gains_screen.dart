import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sale.dart';
import '../services/database_service.dart';
import 'package:intl/intl.dart';

class GainsScreen extends StatelessWidget {
  const GainsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      body: ValueListenableBuilder<Box<Sale>>(
        valueListenable: databaseService.salesListenable,
        builder: (context, box, _) {
          final sales = box.values.toList().cast<Sale>();
          
          if (sales.isEmpty) {
            return const Center(child: Text('No hay ventas registradas aún.'));
          }

          final totalRevenue = sales.fold(0.0, (sum, sale) => sum + sale.total);
          final totalProfit = sales.fold(0.0, (sum, sale) => sum + sale.profit);
          final totalSales = sales.length;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                       const Text(
                        'Resumen General',
                        style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'CUP ${totalProfit.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Ganancia Total',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildHeaderStat('Ventas', '$totalSales'),
                          Container(width: 1, height: 40, color: Colors.white24),
                          _buildHeaderStat('Ingresos', 'CUP ${totalRevenue.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      // Show latest first
                      final sale = sales[sales.length - 1 - index];
                      final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(sale.date);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          // leading: CircleAvatar(
                          //   backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          //   child: Icon(Icons.shopping_bag, color: Theme.of(context).colorScheme.onSecondaryContainer),
                          // ),
                          title: Text(sale.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('$dateStr\nCantidad: ${sale.quantity}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('+CUP ${sale.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(
                                    'Ganancia: CUP ${sale.profit.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final key = box.keyAt(sales.length - 1 - index);
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirmar eliminación'),
                                      content: const Text('¿Estás seguro de que quieres eliminar esta venta?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text('Eliminar'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    await databaseService.deleteSale(key);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Venta eliminada')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: sales.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
