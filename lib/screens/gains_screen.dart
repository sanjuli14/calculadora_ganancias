import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/sale.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/payment_methods.dart';

class GainsScreen extends StatefulWidget {
  const GainsScreen({super.key});

  @override
  State<GainsScreen> createState() => _GainsScreenState();
}

class _GainsScreenState extends State<GainsScreen> {
  String _period = 'all';
  final _exchangeRateController = TextEditingController();
  bool _showUsd = false;

  @override
  void dispose() {
    _exchangeRateController.dispose();
    super.dispose();
  }

  double? get _usdRate {
    final v = double.tryParse(_exchangeRateController.text);
    return (v == null || v <= 0) ? null : v;
  }

  List<Sale> _filterSales(DatabaseService db, List<Sale> sales) {
    switch (_period) {
      case 'week':
        return db.getWeeklySalesCustom(DateTime.friday);
      case 'month':
        return db.getMonthlySales();
      default:
        return sales;
    }
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder<Box<Sale>>(
          valueListenable: databaseService.salesListenable,
          builder: (context, box, _) {
            final allSales = box.values.toList().cast<Sale>();
            final sales = _filterSales(databaseService, allSales);

            if (allSales.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.emeraldSoft,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Icon(Icons.trending_up, size: 44, color: AppColors.emerald),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No hay ventas registradas aún',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Registra tu primera venta desde el tab Vender',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            final totalRevenue = sales.fold(0.0, (s, x) => s + x.total);
            final totalProfit = sales.fold(0.0, (s, x) => s + x.profit);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ganancias',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PeriodSelector(
                          period: _period,
                          onChanged: (p) => setState(() => _period = p),
                        ),
                        const SizedBox(height: 16),
                        Container(
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
                                color: AppColors.navy.withOpacity(0.3),
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
                                  Icon(Icons.savings_outlined, color: Colors.white70, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Ganancia del período',
                                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formatMoney(totalProfit),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _HeaderStat(label: 'Ventas', value: '${sales.length}'),
                                  Container(width: 1, height: 32, color: Colors.white24),
                                  _HeaderStat(label: 'Ingresos', value: formatMoney(totalRevenue)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _DollarCard(
                          rate: _usdRate,
                          show: _showUsd,
                          totalRevenue: totalRevenue,
                          totalProfit: totalProfit,
                          controller: _exchangeRateController,
                          onChanged: () => setState(() {}),
                          onToggle: (v) => setState(() => _showUsd = v),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          sales.isEmpty
                              ? 'Sin ventas en este período'
                              : 'Historial de ventas (${sales.length})',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
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
                        final sale = sales[sales.length - 1 - index];
                        return _SaleTile(
                          sale: sale,
                          onDelete: () => _confirmDelete(context, databaseService, box, sales.length - 1 - index),
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
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    DatabaseService db,
    Box<Sale> box,
    int index,
  ) async {
    final key = box.keyAt(index);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Eliminar esta venta? El stock del producto será restaurado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.danger)),
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

class _DollarCard extends StatelessWidget {
  final double? rate;
  final bool show;
  final double totalRevenue;
  final double totalProfit;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final ValueChanged<bool> onToggle;

  const _DollarCard({
    required this.rate,
    required this.show,
    required this.totalRevenue,
    required this.totalProfit,
    required this.controller,
    required this.onChanged,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final hasRate = show && rate != null;
    final usdRevenue = hasRate ? totalRevenue / rate! : 0.0;
    final usdProfit = hasRate ? totalProfit / rate! : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_money_outlined, color: AppColors.navy, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Equivalente en USD',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Switch(
                value: show,
                activeThumbColor: AppColors.emerald,
                onChanged: onToggle,
              ),
            ],
          ),
          if (show) ...[
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              onChanged: (_) => onChanged(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Tipo de cambio (1 USD en CUP)',
                hintText: 'Ej: 120',
                prefixIcon: Icon(Icons.currency_exchange),
              ),
            ),
            if (hasRate) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total vendido', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text(
                    '\$${usdRevenue.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Ganancias', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text(
                    '\$${usdProfit.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ],
              ),
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

  const _PeriodSelector({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _periodChip('all', 'Todo'),
        const SizedBox(width: 8),
        _periodChip('month', 'Este mes'),
        const SizedBox(width: 8),
        _periodChip('week', 'Esta semana'),
      ],
    );
  }

  Widget _periodChip(String value, String label) {
    final selected = period == value;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.navy : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.navy : AppColors.border),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeaderStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
          ),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SaleTile extends StatelessWidget {
  final Sale sale;
  final VoidCallback onDelete;

  const _SaleTile({required this.sale, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy • HH:mm').format(sale.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: sale.isOwnExpense ? AppColors.warningSoft : AppColors.emeraldSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  sale.isOwnExpense ? Icons.person_outline : Icons.receipt_long_outlined,
                  color: sale.isOwnExpense ? AppColors.warning : AppColors.emerald,
                  size: 22,
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
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$dateStr • ${sale.quantity} u × ${formatMoney(sale.unitSellPrice)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: sale.isOwnExpense ? AppColors.warningSoft : AppColors.navySoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(PaymentMethod.icon(sale.paymentMethod), size: 11, color: sale.isOwnExpense ? AppColors.warning : AppColors.navy),
                    const SizedBox(width: 3),
                    Text(
                      PaymentMethod.label(sale.paymentMethod),
                      style: TextStyle(
                        color: sale.isOwnExpense ? AppColors.warning : AppColors.navy,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (sale.commission > 0) ...[
                const SizedBox(width: 6),
                Text(
                  'comisión ${formatMoney(sale.commission)}',
                  style: const TextStyle(color: AppColors.danger, fontSize: 11),
                ),
              ],
              if (sale.paymentMethod == 'dolar' && sale.exchangeRate != null) ...[
                const SizedBox(width: 6),
                Text(
                  'cambio ${formatMoney(sale.exchangeRate!)}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
              const Spacer(),
              if (sale.isOwnExpense)
                Text(
                  '-${formatMoney(sale.ownExpenseCost)}',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                )
              else
                Text(
                  '+${formatMoney(sale.total)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: sale.isOwnExpense
                ? Text(
                    'Descontado de la inversión',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Text(
                    sale.paymentMethod == 'dolar' && sale.usdAmount > 0
                        ? 'ganancia ${formatMoney(sale.profit)} • \$${sale.usdAmount.toStringAsFixed(2)} USD'
                        : 'ganancia ${formatMoney(sale.profit)}',
                    style: const TextStyle(
                      color: AppColors.emerald,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
