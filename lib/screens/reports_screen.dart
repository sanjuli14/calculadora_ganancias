import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/purchase.dart';
import '../models/shrinkage.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/stat_card.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _period = 'all';
  DateTime? _customStart;
  DateTime? _customEnd;

  (DateTime, DateTime) _range() {
    final now = DateTime.now();
    switch (_period) {
      case 'today':
        final start = DateTime(now.year, now.month, now.day);
        return (start, now);
      case '7days':
        return (now.subtract(const Duration(days: 7)), now);
      case 'month':
        return (DateTime(now.year, now.month, 1), now);
      case 'year':
        return (DateTime(now.year), now);
      case 'custom':
        final start = _customStart ?? DateTime(2000);
        final end = _customEnd ?? now;
        return (start.isBefore(end) ? start : end, start.isBefore(end) ? end : start);
      default:
        return (DateTime(2000), now);
    }
  }

  String get _periodLabel {
    switch (_period) {
      case 'today':
        return 'Hoy';
      case '7days':
        return 'Últimos 7 días';
      case 'month':
        return 'Este mes';
      case 'year':
        return 'Este año';
      case 'custom':
        if (_customStart != null || _customEnd != null) {
          final f = DateFormat('dd/MM/yyyy');
          final f2 = DateFormat('MMM yyyy', 'es');
          if (_customStart != null && _customEnd != null) {
            return '${f.format(_customStart!)} – ${_customEnd!.year == DateTime.now().year && _customEnd!.month == DateTime.now().month && _customEnd!.day == DateTime.now().day ? 'hoy' : f.format(_customEnd!)}';
          }
          return _customStart != null
              ? 'Desde ${f.format(_customStart!)}'
              : 'Hasta ${f2.format(_customEnd!)}';
        }
        return 'Personalizado';
      default:
        return 'Desde el inicio';
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initial = isStart
        ? (_customStart ?? DateTime(2000))
        : (_customEnd ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: isStart ? 'Fecha de inicio' : 'Fecha de fin',
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _customStart = picked;
        } else {
          _customEnd = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reportes y Finanzas',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: db.salesListenable,
          builder: (context, salesBox, _) {
            return ValueListenableBuilder(
              valueListenable: db.purchasesListenable,
              builder: (context, purchasesBox, _) {
                return ValueListenableBuilder(
                  valueListenable: db.shrinkagesListenable,
                  builder: (context, shrinkagesBox, _) {
                    return ValueListenableBuilder(
                      valueListenable: db.expensesListenable,
                      builder: (context, expensesBox, _) =>
                          _buildBody(db),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(DatabaseService db) {
    final (start, end) = _range();

    final invested = db.getPurchasesTotalBetween(start, end);
    final revenue = db.getRevenueBetween(start, end);
    final cogs = db.getCOGSBetween(start, end);
    final grossProfit = db.getGrossProfitBetween(start, end);
    final shrinkage = db.getShrinkageCostBetween(start, end);
    final expenses = db.getExpensesBetween(start, end);
    final netProfit = db.getNetProfitBetween(start, end);

    final inventoryCost = db.getInvestedCapital();
    final inventoryValue = db.getInventoryValue();
    final historicCapital = db.getHistoricalCapitalInjected();
    final totalShrinkage = db.getTotalShrinkageCost();
    final margin = db.getRealMargin(start, end) * 100;
    final turnover = db.getInventoryTurnover(start, end);

    final periodPurchases = db.getPurchasesBetween(start, end);
    final periodShrinkages = db.getShrinkagesBetween(start, end);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PeriodSelector(
            period: _period,
            onChanged: (p) => setState(() => _period = p),
            onCustomStart: () => _selectDate(context, true),
            onCustomEnd: () => _selectDate(context, false),
            customStart: _customStart,
            customEnd: _customEnd,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.date_range, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 6),
              Text(
                _periodLabel,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _NetProfitHero(netProfit: netProfit, label: _periodLabel.toLowerCase()),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Invertido (compras)',
                  value: invested,
                  icon: Icons.shopping_bag_outlined,
                  color: AppColors.navy,
                  softColor: AppColors.navySoft,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Ingresos por ventas',
                  value: revenue,
                  icon: Icons.payments_outlined,
                  color: AppColors.turquoise,
                  softColor: AppColors.turquoiseSoft,
                  isCompact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Costo de ventas (COGS)',
                  value: cogs,
                  icon: Icons.local_shipping_outlined,
                  color: AppColors.info,
                  softColor: AppColors.navySoft,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Ganancia bruta',
                  value: grossProfit,
                  icon: Icons.trending_up,
                  color: AppColors.emerald,
                  softColor: AppColors.emeraldSoft,
                  isCompact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Mermas del período',
                  value: shrinkage,
                  icon: Icons.report_gmailerrorred_outlined,
                  color: AppColors.warning,
                  softColor: AppColors.warningSoft,
                  isCompact: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  label: 'Gastos operativos',
                  value: expenses,
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.danger,
                  softColor: AppColors.dangerSoft,
                  isCompact: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Salud del inventario',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _DetailRow(
                  label: 'Valor inventario (costo)',
                  value: formatMoney(inventoryCost),
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: 'Valor inventario (venta)',
                  value: formatMoney(inventoryValue),
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: 'Ganancia potencial',
                  value: formatMoney(inventoryValue - inventoryCost),
                  valueColor: AppColors.emerald,
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: 'Capital inyectado (histórico)',
                  value: formatMoney(historicCapital),
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: 'Mermas acumuladas',
                  value: '-${formatMoney(totalShrinkage)}',
                  valueColor: AppColors.warning,
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: 'Margen real del período',
                  value: '${margin.toStringAsFixed(1)}%',
                  valueColor: AppColors.emerald,
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: 'Rotación del inventario',
                  value: '${turnover.toStringAsFixed(2)}×',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (periodPurchases.isEmpty && periodShrinkages.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Sin movimientos de compras o mermas en este período.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else ...[
            if (periodPurchases.isNotEmpty) ...[
              Text(
                'Compras del período (${periodPurchases.length})',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              for (final purchase in periodPurchases)
                _MiniPurchaseTile(purchase: purchase),
            ],
            if (periodShrinkages.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Mermas del período (${periodShrinkages.length})',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              for (final shrinkage in periodShrinkages)
                _MiniShrinkageTile(shrinkage: shrinkage),
            ],
          ],
        ],
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  final String period;
  final ValueChanged<String> onChanged;
  final VoidCallback onCustomStart;
  final VoidCallback onCustomEnd;
  final DateTime? customStart;
  final DateTime? customEnd;

  const _PeriodSelector({
    required this.period,
    required this.onChanged,
    required this.onCustomStart,
    required this.onCustomEnd,
    this.customStart,
    this.customEnd,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <(String, String)>[
      ('all', 'Todo'),
      ('today', 'Hoy'),
      ('7days', '7 días'),
      ('month', 'Mes'),
      ('year', 'Año'),
      ('custom', 'Fechas'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, label) in chips) _chip(value, label),
        if (period == 'custom') ...[
          _dateChip('Inicio', customStart, onCustomStart),
          _dateChip('Fin', customEnd, onCustomEnd),
        ],
      ],
    );
  }

  Widget _chip(String value, String label) {
    final selected = period == value;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.navy : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _dateChip(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.turquoiseSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.turquoise.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 13, color: AppColors.turquoise),
            const SizedBox(width: 6),
            Text(
              date == null ? label : DateFormat('dd/MM/yy').format(date),
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetProfitHero extends StatelessWidget {
  final double netProfit;
  final String label;

  const _NetProfitHero({required this.netProfit, required this.label});

  @override
  Widget build(BuildContext context) {
    final positive = netProfit >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: positive
              ? [AppColors.navy, AppColors.emerald]
              : [AppColors.navy, AppColors.danger],
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
          Row(
            children: [
              Icon(
                positive ? Icons.savings_outlined : Icons.error_outline,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Utilidad neta · $label',
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
            formatMoney(netProfit),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ganancia bruta − mermas − gastos operativos',
            style: TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: AppColors.textSecondary)),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _MiniPurchaseTile extends StatelessWidget {
  final Purchase purchase;

  const _MiniPurchaseTile({required this.purchase});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(purchase.date);
    final details = purchase.items
        .map((i) => '${i.productName} ×${i.quantity}')
        .join('   ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag_outlined, color: AppColors.navy, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  purchase.supplierName.trim().isEmpty
                      ? 'Compra de mercancía'
                      : purchase.supplierName.trim(),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '-${formatMoney(purchase.totalCost)}',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$dateStr • $details',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MiniShrinkageTile extends StatelessWidget {
  final Shrinkage shrinkage;

  const _MiniShrinkageTile({required this.shrinkage});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(shrinkage.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.report_gmailerrorred_outlined,
            color: AppColors.warning,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${shrinkage.productName} · ${shrinkage.reason} · ${shrinkage.quantity} u',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${formatMoney(shrinkage.cost)}',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}