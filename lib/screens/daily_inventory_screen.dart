import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class DailyInventoryScreen extends StatelessWidget {
  const DailyInventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
        ),
        title: const Text(
          'Inventario Diario',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Box<Sale>>(
          valueListenable: Provider.of<DatabaseService>(context, listen: false)
              .salesListenable,
          builder: (context, box, _) {
            final db = Provider.of<DatabaseService>(context);
            final allSales = box.values.toList().cast<Sale>();

            if (allSales.isEmpty) {
              return _emptyState();
            }

            final groups = _groupByDay(allSales);
            final todaySales = db.getTodaySales();
            final todayRevenue =
                todaySales.fold(0.0, (s, x) => s + x.total);
            final todayProfit =
                todaySales.fold(0.0, (s, x) => s + x.profit);
            final todayUnits =
                todaySales.fold<int>(0, (s, x) => s + x.quantity);

            final now = DateTime.now();
            final todayKey = DateTime(now.year, now.month, now.day)
                .millisecondsSinceEpoch;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TodayCard(
                          revenue: todayRevenue,
                          profit: todayProfit,
                          salesCount: todaySales.length,
                          units: todayUnits,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Historial por días',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Toca un día para consultar sus ventas.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final key = groups.keys.toList()[index];
                        final sales = groups[key]!;
                        final day = DateTime.fromMillisecondsSinceEpoch(key);
                        final revenue =
                            sales.fold(0.0, (s, x) => s + x.total);
                        final profit =
                            sales.fold(0.0, (s, x) => s + x.profit);
                        final units =
                            sales.fold<int>(0, (s, x) => s + x.quantity);
                        return _DayCard(
                          day: day,
                          isToday: key == todayKey,
                          salesCount: sales.length,
                          units: units,
                          revenue: revenue,
                          profit: profit,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _DaySalesScreen(day: day),
                            ),
                          ),
                        );
                      },
                      childCount: groups.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 56, color: AppColors.border),
            SizedBox(height: 12),
            Text(
              'Aún no hay ventas registradas',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Registra tu primera venta desde el tab Vender',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Map<int, List<Sale>> _groupByDay(List<Sale> sales) {
    final groups = <int, List<Sale>>{};
    for (final sale in sales) {
      final day = DateTime(sale.date.year, sale.date.month, sale.date.day);
      groups.putIfAbsent(day.millisecondsSinceEpoch, () => []).add(sale);
    }
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    final sorted = <int, List<Sale>>{};
    for (final key in keys) {
      final list = groups[key]!..sort(
          (a, b) => b.date.compareTo(a.date),
        );
      sorted[key] = list;
    }
    return sorted;
  }
}

class _TodayCard extends StatelessWidget {
  final double revenue;
  final double profit;
  final int salesCount;
  final int units;

  const _TodayCard({
    required this.revenue,
    required this.profit,
    required this.salesCount,
    required this.units,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.emerald],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.today_outlined, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'Ventas de hoy',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formatMoney(revenue),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroStat(label: 'Ventas', value: '$salesCount'),
              Container(width: 1, height: 32, color: Colors.white24),
              _HeroStat(label: 'Unidades', value: '$units'),
              Container(width: 1, height: 32, color: Colors.white24),
              _HeroStat(label: 'Ganancia', value: formatMoneyCompact(profit)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final int salesCount;
  final int units;
  final double revenue;
  final double profit;
  final VoidCallback onTap;

  const _DayCard({
    required this.day,
    required this.isToday,
    required this.salesCount,
    required this.units,
    required this.revenue,
    required this.profit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEEE, d MMMM', 'es').format(day);
    final dateText =
        '${dateStr[0].toUpperCase()}${dateStr.substring(1)}';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isToday ? AppColors.emeraldSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isToday ? AppColors.emerald : AppColors.border,
          width: isToday ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isToday ? AppColors.emerald : AppColors.navySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isToday ? Icons.today : Icons.calendar_today_outlined,
                color: isToday ? AppColors.emerald : AppColors.navy,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday ? 'Hoy • $dateText' : dateText,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$salesCount venta${salesCount == 1 ? '' : 's'} • $units u',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+${formatMoney(revenue)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'ganancia ${formatMoney(profit)}',
                  style: const TextStyle(
                    color: AppColors.emerald,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySalesScreen extends StatelessWidget {
  final DateTime day;

  const _DaySalesScreen({required this.day});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'es').format(day);
    final title = '${dateStr[0].toUpperCase()}${dateStr.substring(1)}';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: ValueListenableBuilder<Box<Sale>>(
        valueListenable: db.salesListenable,
        builder: (context, box, _) {
          final current = db.getSalesForDay(day);
          final currentRevenue = current.fold(0.0, (s, x) => s + x.total);
          final currentProfit = current.fold(0.0, (s, x) => s + x.profit);
          final currentUnits =
              current.fold<int>(0, (s, x) => s + x.quantity);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _DetailStat(
                            label: 'Ventas',
                            value: '${current.length}',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: _DetailStat(
                            label: 'Unidades',
                            value: '$currentUnits',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: _DetailStat(
                            label: 'Ingresos',
                            value: formatMoneyCompact(currentRevenue),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: AppColors.border,
                        ),
                        Expanded(
                          child: _DetailStat(
                            label: 'Ganancia',
                            value: formatMoneyCompact(currentProfit),
                            valueColor: AppColors.emerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (current.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 40, 20, 24),
                    child: Center(
                      child: Text(
                        'No hay ventas registradas este día.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final sale = current[current.length - 1 - index];
                        return _DaySaleTile(
                          sale: sale,
                          onDelete: () => _confirmDelete(
                            context,
                            db,
                            sale.key,
                          ),
                        );
                      },
                      childCount: current.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DatabaseService db,
    dynamic key,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
            '¿Eliminar esta venta? El stock del producto será restaurado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await db.deleteSale(key);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta eliminada')),
        );
      }
    }
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _DetailStat({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _DaySaleTile extends StatelessWidget {
  final Sale sale;
  final VoidCallback onDelete;

  const _DaySaleTile({required this.sale, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('HH:mm').format(sale.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: sale.isOwnExpense
                  ? AppColors.warningSoft
                  : AppColors.emeraldSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              sale.isOwnExpense
                  ? Icons.person_outline
                  : Icons.receipt_long_outlined,
              color: sale.isOwnExpense ? AppColors.warning : AppColors.emerald,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.productName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$timeStr • ${sale.quantity} u × ${formatMoney(sale.unitSellPrice)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                sale.isOwnExpense
                    ? '-${formatMoney(sale.ownExpenseCost)}'
                    : '+${formatMoney(sale.total)}',
                style: TextStyle(
                  color: sale.isOwnExpense
                      ? AppColors.warning
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              if (!sale.isOwnExpense) ...[
                Text(
                  'ganancia ${formatMoney(sale.profit)}',
                  style: const TextStyle(
                    color: AppColors.emerald,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}