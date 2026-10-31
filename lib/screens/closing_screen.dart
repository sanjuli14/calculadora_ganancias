import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/inventory_closing.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

class ClosingScreen extends StatelessWidget {
  const ClosingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cierre de Inventario',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: db.periodListenable,
          builder: (context, _) {
            final current = db.computeCurrentPeriod();
            final closings = db.getClosings().reversed.toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _ProfitHero(period: current, title: 'Período actual'),
                const SizedBox(height: 12),
                if (closings.isEmpty) ...[
                  _ManualClosingCard(db: db),
                  const SizedBox(height: 12),
                ],
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => _CountScreen(db: db)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.lock_clock_outlined),
                  label: const Text('CONTAR Y CERRAR INVENTARIO'),
                ),
                const SizedBox(height: 20),
                _PeriodDetails(period: current),
                const SizedBox(height: 20),
                Text(
                  'Cierres anteriores',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                if (closings.isEmpty)
                  Text(
                    'Aún no has cerrado ningún período en la app.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                for (final closing in closings)
                  _ClosingTile(
                    closing: closing,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _ClosingDetailScreen(closing: closing),
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
}

String _periodLabel(InventoryClosing period) {
  final start = period.periodStart;
  return start == null
      ? 'Desde el inicio de tus datos'
      : 'Desde ${_dateFormat.format(start)}';
}

class _ProfitHero extends StatelessWidget {
  final InventoryClosing period;
  final String title;

  const _ProfitHero({required this.period, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.navy,
            period.netProfit >= 0 ? AppColors.emerald : AppColors.danger,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _periodLabel(period),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          const Text(
            'Utilidad neta',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            formatMoney(period.netProfit),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualClosingCard extends StatelessWidget {
  final DatabaseService db;

  const _ManualClosingCard({required this.db});

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = db.manualLastClosing ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Fecha del último cierre',
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Hora del último cierre',
    );
    if (time == null || !context.mounted) return;
    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (picked.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha no puede ser futura')),
      );
      return;
    }
    await db.setManualLastClosing(picked);
  }

  @override
  Widget build(BuildContext context) {
    final manual = db.manualLastClosing;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.navySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            manual == null
                ? '¿Ya hiciste un cierre fuera de la app?'
                : 'Último cierre: ${_dateFormat.format(manual)}',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'El período empieza en esa fecha y hora. Solo cuenta lo '
            'registrado después. Puedes cambiarla hasta tu primer cierre.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pick(context),
                icon: const Icon(Icons.event, size: 18),
                label: Text(
                  manual == null ? 'Indicar último cierre' : 'Cambiar fecha',
                ),
              ),
              if (manual != null)
                TextButton(
                  onPressed: () => db.setManualLastClosing(null),
                  child: const Text('Quitar'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodDetails extends StatelessWidget {
  final InventoryClosing period;

  const _PeriodDetails({required this.period});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _Row('Ventas', '${period.salesCount}'),
          _Row('Unidades vendidas', '${period.unitsSold}'),
          _Row('Ingresos por ventas', formatMoney(period.revenue)),
          _Row('Costo de lo vendido', '-${formatMoney(period.cogs)}'),
          _Row(
            'Ganancia bruta',
            formatMoney(period.grossProfit),
            color: AppColors.emerald,
          ),
          _Row('Mermas', '-${formatMoney(period.shrinkageCost)}'),
          _Row('Gastos', '-${formatMoney(period.expenses)}'),
          _Row(
            'Utilidad neta',
            formatMoney(period.netProfit),
            color: period.netProfit >= 0 ? AppColors.emerald : AppColors.danger,
          ),
          const Divider(height: 24),
          _Row('Compras de mercancía', formatMoney(period.purchases)),
          _Row('Comisiones', formatMoney(period.commissions)),
          const Divider(height: 24),
          _Row('Fiado entregado', formatMoney(period.creditSold)),
          _Row('Fiado cobrado', formatMoney(period.creditCollected)),
          _Row(
            'Ganancia en fiado cobrado',
            formatMoney(period.creditProfitCollected),
            color: AppColors.emerald,
          ),
          _Row('Fiado pendiente', formatMoney(period.creditOutstanding)),
          const SizedBox(height: 4),
          Text(
            'El fiado y las comisiones no están incluidos en la utilidad '
            'neta, igual que en Reportes.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const Divider(height: 24),
          _Row('Unidades en stock', '${period.stockUnits}'),
          _Row('Stock a costo', formatMoney(period.stockCost)),
          _Row('Stock a precio de venta', formatMoney(period.stockValue)),
          if (period.surplusUnits > 0)
            _Row('Sobrantes del conteo', '${period.surplusUnits} u'),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _Row(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClosingTile extends StatelessWidget {
  final InventoryClosing closing;
  final VoidCallback onTap;

  const _ClosingTile({required this.closing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        title: Text(
          _dateFormat.format(closing.closedAt),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          '${closing.salesCount} ventas • ${formatMoney(closing.revenue)}',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Text(
          formatMoney(closing.netProfit),
          style: TextStyle(
            color: closing.netProfit >= 0
                ? AppColors.emerald
                : AppColors.danger,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ClosingDetailScreen extends StatelessWidget {
  final InventoryClosing closing;

  const _ClosingDetailScreen({required this.closing});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cierre ${DateFormat('dd/MM/yyyy').format(closing.closedAt)}',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _ProfitHero(
              period: closing,
              title: 'Cerrado el ${_dateFormat.format(closing.closedAt)}',
            ),
            const SizedBox(height: 16),
            _PeriodDetails(period: closing),
          ],
        ),
      ),
    );
  }
}

// Conteo físico: cada producto parte de lo que dice la app, así que solo hay
// que corregir los que no coinciden.
class _CountScreen extends StatefulWidget {
  final DatabaseService db;

  const _CountScreen({required this.db});

  @override
  State<_CountScreen> createState() => _CountScreenState();
}

class _CountScreenState extends State<_CountScreen> {
  late final List<Product> _products;
  final _controllers = <dynamic, TextEditingController>{};
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _products = widget.db.productsBox.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    for (final product in _products) {
      _controllers[product.key] = TextEditingController(
        text: '${product.stock}',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  int? _counted(Product product) {
    final value = int.tryParse(_controllers[product.key]!.text.trim());
    return value == null || value < 0 ? null : value;
  }

  Future<void> _confirm() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final counted = <dynamic, int>{};
    var missingCost = 0.0;
    var surplus = 0;
    for (final product in _products) {
      final value = _counted(product);
      if (value == null) {
        messenger.showSnackBar(
          SnackBar(content: Text('Cantidad inválida en ${product.name}')),
        );
        return;
      }
      final difference = value - product.stock;
      if (difference == 0) continue;
      counted[product.key] = value;
      if (difference < 0) {
        missingCost += -difference * product.buyPrice;
      } else {
        surplus += difference;
      }
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar inventario'),
        content: Text(
          '${counted.isEmpty ? 'Sin diferencias en el conteo.' : 'Faltantes: ${formatMoney(missingCost)} en mermas. Sobrantes: $surplus u.'}\n\n'
          'El cierre no se puede deshacer y los registros de este período '
          'ya no se podrán cambiar. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _closing = true);
    try {
      await widget.db.closeInventory(counted: counted);
      messenger.showSnackBar(
        const SnackBar(content: Text('Inventario cerrado. Período nuevo')),
      );
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('No se pudo cerrar: $e')));
      if (mounted) setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Conteo físico',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Text(
                'Corrige solo lo que no coincida. Lo que falte se registra '
                'como merma y lo que sobre se suma al stock.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  final value = _counted(product);
                  final difference = value == null
                      ? null
                      : value - product.stock;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      product.name,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      difference == null || difference == 0
                          ? 'En la app: ${product.stock}'
                          : 'En la app: ${product.stock} • diferencia ${difference > 0 ? '+' : ''}$difference',
                      style: TextStyle(
                        color: difference == null || difference == 0
                            ? AppColors.textSecondary
                            : AppColors.warning,
                        fontSize: 12,
                      ),
                    ),
                    trailing: SizedBox(
                      width: 72,
                      child: TextField(
                        controller: _controllers[product.key],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _closing ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('CERRAR INVENTARIO'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
