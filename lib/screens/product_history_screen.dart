import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/sale.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/payment_methods.dart';

/// Historial de todos los productos que han pasado por la tienda,
/// construido a partir del libro de ventas. Incluye productos que ya se
/// eliminaron del catálogo.
class ProductHistoryScreen extends StatelessWidget {
  const ProductHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Historial de Productos',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Box<Sale>>(
          valueListenable: db.salesListenable,
          builder: (context, box, _) {
            final summaries = _buildSummaries(box, db);
            if (summaries.isEmpty) {
              return const _EmptyState();
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              itemCount: summaries.length,
              itemBuilder: (context, index) {
                final summary = summaries[index];
                return _ProductHistoryTile(
                  summary: summary,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _ProductHistoryDetailScreen(
                        groupKey: summary.key,
                        productName: summary.name,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Agrupa las ventas por producto (por ID estable cuando existe, o por
  // nombre para registrar antiguos sin ID) y suma unidades, ingresos y costo.
  List<_ProductSummary> _buildSummaries(
    Box<Sale> box,
    DatabaseService db,
  ) {
    final byKey = <String, _ProductSummary>{};
    for (final sale in box.values) {
      if (sale.isOwnExpense) continue;
      final key = DatabaseService.saleGroupKey(sale);
      byKey.putIfAbsent(
        key,
        () => _ProductSummary(key: key, name: sale.productName),
      );
      final summary = byKey[key]!;
      summary.units += sale.quantity;
      summary.revenue += sale.total;
      summary.cost += sale.unitBuyPrice * sale.quantity;
    }
    // Prefiere el nombre actual del catálogo si el producto sigue existiendo.
    for (final summary in byKey.values) {
      final product = db.productById(summary.key);
      if (product != null) {
        summary.name = product.name;
      }
    }
    // Los que más ingresos generaron primero.
    final list = byKey.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    return list;
  }
}

class _ProductSummary {
  final String key;
  String name;
  int units = 0;
  double revenue = 0;
  double cost = 0;

  _ProductSummary({required this.key, required this.name});

  double get profit => revenue - cost;
}

class _ProductHistoryTile extends StatelessWidget {
  final _ProductSummary summary;
  final VoidCallback? onTap;

  const _ProductHistoryTile({required this.summary, this.onTap});

  @override
  Widget build(BuildContext context) {
    final profit = summary.profit;
    final profitColor = profit >= 0 ? AppColors.emerald : AppColors.danger;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.navySoft,
                child: Text(
                  summary.name.isNotEmpty
                      ? summary.name.substring(0, 1).toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${summary.units} unidades vendidas',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ingresos: ${formatMoney(summary.revenue)}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatMoney(profit),
                    style: TextStyle(
                      color: profitColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'ganancia',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductHistoryDetailScreen extends StatelessWidget {
  final String groupKey;
  final String productName;

  const _ProductHistoryDetailScreen({
    required this.groupKey,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          productName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Box<Sale>>(
          valueListenable: db.salesListenable,
          builder: (context, box, _) {
            final sales = db.getSalesForProductGroup(groupKey);
            if (sales.isEmpty) {
              return const Center(
                child: Text('Sin ventas registradas'),
              );
            }

            double units = 0;
            double revenue = 0;
            double cost = 0;
            for (final sale in sales) {
              units += sale.quantity;
              revenue += sale.total;
              cost += sale.unitBuyPrice * sale.quantity;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _StatsHeader(
                  units: units,
                  revenue: revenue,
                  cost: cost,
                  avgSellPrice: units > 0 ? revenue / units : 0,
                  avgCost: units > 0 ? cost / units : 0,
                ),
                const SizedBox(height: 18),
                Text(
                  'Ventas registradas (${sales.length})',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                for (final sale in sales) _SaleTile(sale: sale),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatsHeader extends StatelessWidget {
  final double units;
  final double revenue;
  final double cost;
  final double avgSellPrice;
  final double avgCost;

  const _StatsHeader({
    required this.units,
    required this.revenue,
    required this.cost,
    required this.avgSellPrice,
    required this.avgCost,
  });

  @override
  Widget build(BuildContext context) {
    final profit = revenue - cost;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navySoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.navy.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _StatValue(
                label: 'Unidades',
                value: units.toStringAsFixed(0),
              ),
              _StatValue(label: 'Ingresos', value: formatMoney(revenue)),
              _StatValue(label: 'Costo', value: formatMoney(cost)),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: AppColors.navy.withValues(alpha: 0.2)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _StatValue(
                label: 'Precio venta prom.',
                value: formatMoney(avgSellPrice),
              ),
              _StatValue(
                label: 'Costo prom.',
                value: formatMoney(avgCost),
              ),
              _StatValue(
                label: 'Ganancia',
                value: formatMoney(profit),
                valueColor:
                    profit >= 0 ? AppColors.emerald : AppColors.danger,
                emphasized: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatValue extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasized;

  const _StatValue({
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w700,
            fontSize: emphasized ? 16 : 13,
          ),
        ),
      ],
    );
  }
}

class _SaleTile extends StatelessWidget {
  final Sale sale;

  const _SaleTile({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            PaymentMethod.icon(sale.paymentMethod),
            color: AppColors.navy,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${sale.quantity} × ${formatMoney(sale.unitSellPrice)}',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('d MMM yyyy', 'es').format(sale.date)} • '
                  '${PaymentMethod.label(sale.paymentMethod)}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatMoney(sale.total),
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                'costo ${formatMoney(sale.unitBuyPrice * sale.quantity)}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.navySoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.storefront_outlined,
                size: 44,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aún no hay historial',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Los productos aparecerán aquí con sus ventas, '
              'cantidades y precios cuando registres ventas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}