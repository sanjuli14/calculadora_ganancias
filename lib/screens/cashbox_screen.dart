import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/cashbox.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/section_header.dart';

class Denomination {
  final String label;
  final double value;
  final bool isCoin;

  const Denomination(this.label, this.value, {this.isCoin = false});
}

const List<Denomination> kBillDenominations = [
  Denomination('5000', 5000),
  Denomination('2000', 2000),
  Denomination('1000', 1000),
  Denomination('500', 500),
  Denomination('200', 200),
  Denomination('100', 100),
  Denomination('50', 50),
  Denomination('20', 20),
  Denomination('10', 10),
];

const List<Denomination> kCoinDenominations = [];

class CashBoxScreen extends StatefulWidget {
  const CashBoxScreen({super.key});

  @override
  State<CashBoxScreen> createState() => _CashBoxScreenState();
}

class _CashBoxScreenState extends State<CashBoxScreen> {
  late Map<String, int> _counts;
  final TextEditingController _expectedController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _showExpected = false;

  @override
  void initState() {
    super.initState();
    _counts = _initialCounts();
  }

  @override
  void dispose() {
    _expectedController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Map<String, int> _initialCounts() {
    final map = <String, int>{};
    for (final d in [...kBillDenominations, ...kCoinDenominations]) {
      map[d.label] = 0;
    }
    return map;
  }

  double get _total {
    double sum = 0;
    _counts.forEach((label, count) {
      sum += (double.tryParse(label) ?? 0) * count;
    });
    return sum;
  }

  double? get _expected {
    final t = double.tryParse(_expectedController.text);
    return t;
  }

  void _setCount(String label, int value) {
    setState(() {
      _counts[label] = value < 0 ? 0 : value;
    });
  }

  void _reset() {
    setState(() {
      _counts = _initialCounts();
      _expectedController.clear();
      _noteController.clear();
      _showExpected = false;
    });
  }

  Future<void> _save(DatabaseService db) async {
    final counts = Map<String, int>.from(_counts)..removeWhere((k, v) => v == 0);
    if (counts.isEmpty) {
      _showSnack('Ingresa al menos una cantidad');
      return;
    }
    final count = CashCount(
      date: DateTime.now(),
      denominations: counts,
      expectedAmount: _showExpected ? _expected : null,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    await db.addCashCount(count);
    _reset();
    _showSnack('Caja guardada correctamente');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Caja Contable',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Cuenta el dinero por billetes',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    _TotalCard(total: _total, expected: _showExpected ? _expected : null),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Billetes'),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final d = kBillDenominations[index];
                    return _DenominationTile(
                      denomination: d,
                      count: _counts[d.label] ?? 0,
                      onCountChanged: (v) => _setCount(d.label, v),
                    );
                  },
                  childCount: kBillDenominations.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.fact_check_outlined, color: AppColors.navy, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Caja esperada (opcional)',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: _showExpected,
                                  activeThumbColor: AppColors.emerald,
                                  onChanged: (v) => setState(() => _showExpected = v),
                                ),
                              ],
                            ),
                            if (_showExpected) ...[
                              const SizedBox(height: 8),
                              TextField(
                                controller: _expectedController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Monto esperado',
                                  prefixIcon: Icon(Icons.payments_outlined),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                            const SizedBox(height: 12),
                            TextField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                labelText: 'Nota (opcional)',
                                prefixIcon: Icon(Icons.notes),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const SectionHeader(
                      title: 'Billetes',
                      subtitle: 'Toca el número para ingresar manualmente',
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final d = kBillDenominations[index];
                    return _DenominationTile(
                      denomination: d,
                      count: _counts[d.label] ?? 0,
                      onCountChanged: (v) => _setCount(d.label, v),
                    );
                  },
                  childCount: kBillDenominations.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Limpiar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _save(db),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Guardar Caja'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: SectionHeader(title: 'Historial de cajas'),
                    ),
                    IconButton(
                      tooltip: 'Eliminar todo',
                      onPressed: () => _confirmClearHistory(db),
                      icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.danger),
                    ),
                  ],
                ),
              ),
            ),
            ValueListenableBuilder<Box<CashCount>>(
              valueListenable: db.cashboxListenable,
              builder: (context, box, _) {
                final counts = box.values.toList().cast<CashCount>();
                if (counts.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 56, color: AppColors.border),
                            SizedBox(height: 12),
                            Text(
                              'Aún no hay cajas guardadas',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final count = counts[counts.length - 1 - index];
                        final key = box.keyAt(counts.length - 1 - index);
                        return _HistoryTile(
                          count: count,
                          onDelete: () => _confirmDeleteHistory(db, key),
                          onTap: () => _showDetail(count),
                        );
                      },
                      childCount: counts.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteHistory(DatabaseService db, dynamic key) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar caja'),
        content: const Text('¿Quieres eliminar este registro de la caja contable?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await db.deleteCashCount(key);
    }
  }

  void _confirmClearHistory(DatabaseService db) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar historial'),
        content: const Text('Se eliminarán todas las cajas guardadas. ¿Continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar todo', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await db.cashboxBox.clear();
    }
  }

  void _showDetail(CashCount count) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final entries = count.denominations.entries.toList()
          ..sort((a, b) {
            final av = double.tryParse(a.key) ?? 0;
            final bv = double.tryParse(b.key) ?? 0;
            return bv.compareTo(av);
          });
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Detalle de la caja',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  DateFormat('EEEE, d MMM yyyy HH:mm', 'es').format(count.date),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              if (count.note != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    count.note!,
                    style: const TextStyle(color: AppColors.textPrimary, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, i) {
                    final e = entries[i];
                    final v = double.tryParse(e.key) ?? 0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${v >= 1 ? 'CUP' : '¢'} ${formatCents(v)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text('× ${e.value}'),
                        Text(
                          formatMoney(v * e.value),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    formatMoney(count.total),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.emerald),
                  ),
                ],
              ),
              if (count.difference != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Diferencia vs esperado',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      Text(
                        '${count.difference! >= 0 ? '+' : ''}${formatMoney(count.difference!)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: count.difference! >= 0 ? AppColors.emerald : AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;
  final double? expected;

  const _TotalCard({required this.total, required this.expected});

  @override
  Widget build(BuildContext context) {
    final diff = expected == null ? null : total - expected!;
    return Container(
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
          const Row(
            children: [
              Icon(Icons.payments_outlined, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'Total contado',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            formatMoney(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          if (diff != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: diff.abs() < 0.005
                    ? Colors.white.withOpacity(0.2)
                    : (diff > 0 ? AppColors.emerald : AppColors.danger),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                diff.abs() < 0.005
                    ? '✔ Coincide con la caja esperada'
                    : '${diff > 0 ? 'Sobra' : 'Faltan'} ${formatMoney(diff.abs())}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DenominationTile extends StatelessWidget {
  final Denomination denomination;
  final int count;
  final ValueChanged<int> onCountChanged;

  const _DenominationTile({
    required this.denomination,
    required this.count,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final subtotal = denomination.value * count;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: count > 0 ? AppColors.emerald.withOpacity(0.6) : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (denomination.isCoin)
                const Icon(Icons.circle, color: AppColors.turquoise, size: 13)
              else
                const Icon(Icons.rectangle_outlined, color: AppColors.navy, size: 13),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  'CUP ${formatCents(denomination.value)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepButton(
                icon: Icons.remove,
                onTap: () => onCountChanged(count - 1),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _editManual(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add,
                onTap: () => onCountChanged(count + 1),
              ),
            ],
          ),
          Text(
            subtotal == 0 ? '—' : formatMoneyCompact(subtotal),
            style: TextStyle(
              color: subtotal == 0 ? AppColors.textSecondary : AppColors.emerald,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _editManual(BuildContext context) {
    final controller = TextEditingController(text: '$count');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cantidad de CUP ${formatCents(denomination.value)}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Cantidad'),
          onSubmitted: (v) {
            final n = int.tryParse(v);
            if (n != null && n >= 0) onCountChanged(n);
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final n = int.tryParse(controller.text);
              if (n != null && n >= 0) onCountChanged(n);
              Navigator.pop(context);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.navySoft,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, size: 14, color: AppColors.navy),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final CashCount count;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _HistoryTile({
    required this.count,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(count.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.turquoiseSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.turquoise, size: 20),
        ),
        title: Text(
          formatMoney(count.total),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          count.note == null ? dateStr : '$dateStr • ${count.note}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count.difference != null)
              Text(
                '${count.difference! >= 0 ? '+' : ''}${formatMoney(count.difference!)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: count.difference! >= 0 ? AppColors.emerald : AppColors.danger,
                ),
              ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
