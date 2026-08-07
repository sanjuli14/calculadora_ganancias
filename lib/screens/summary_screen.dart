import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/sale.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/stat_card.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  DateTime? _customStart;
  DateTime? _customEnd;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
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

    final customSales = (_customStart != null && _customEnd != null)
        ? db.getSalesBetween(_customStart!, _customEnd!)
        : <Sale>[];

    final summary = db.calculateSummary(customSales);
    final totalRevenue = summary['totalSales'] ?? 0;
    final totalProfit = summary['totalProfit'] ?? 0;
    final invested = db.getInvestedCapital();
    final inventoryValue = db.getInventoryValue();

    return Scaffold(
      appBar: AppBar(title: const Text('Resumen por fechas')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Período personalizado',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Selecciona un rango de fechas para ver los resultados',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: _customStart == null
                          ? 'Fecha inicio'
                          : DateFormat('dd/MM/yyyy').format(_customStart!),
                      icon: Icons.event,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateButton(
                      label: _customEnd == null
                          ? 'Fecha fin'
                          : DateFormat('dd/MM/yyyy').format(_customEnd!),
                      icon: Icons.event_available,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              if (_customStart != null && _customEnd != null) ...[
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.navy, AppColors.turquoise],
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
                      const Text(
                        'Ganancia del período',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
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
                          _SummaryStat(label: 'Ventas', value: '${customSales.length}'),
                          Container(width: 1, height: 32, color: Colors.white24),
                          _SummaryStat(label: 'Ingresos', value: formatMoney(totalRevenue)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Detalle',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'Dinero invertido',
                        value: invested,
                        icon: Icons.account_balance_wallet_outlined,
                        color: AppColors.navy,
                        softColor: AppColors.navySoft,
                        isCompact: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatCard(
                        label: 'Valor inventario',
                        value: inventoryValue,
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.turquoise,
                        softColor: AppColors.turquoiseSoft,
                        isCompact: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(label: 'Total de ventas', value: formatMoney(totalRevenue)),
                      const Divider(height: 24),
                      _DetailRow(label: 'Total de ganancias', value: formatMoney(totalProfit), valueColor: AppColors.emerald),
                      const Divider(height: 24),
                      _DetailRow(label: 'Número de ventas', value: '${customSales.length}'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DateButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.navy, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryStat({required this.label, required this.value});

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
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
