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
  final String currencyCode;

  const Denomination(
    this.label,
    this.value, {
    this.isCoin = false,
    this.currencyCode = 'CUP',
  });
}

const List<Denomination> kBillDenominations = [
  Denomination('5000', 5000, currencyCode: 'CUP'),
  Denomination('2000', 2000, currencyCode: 'CUP'),
  Denomination('1000', 1000, currencyCode: 'CUP'),
  Denomination('500', 500, currencyCode: 'CUP'),
  Denomination('200', 200, currencyCode: 'CUP'),
  Denomination('100', 100, currencyCode: 'CUP'),
  Denomination('50', 50, currencyCode: 'CUP'),
  Denomination('20', 20, currencyCode: 'CUP'),
  Denomination('10', 10, currencyCode: 'CUP'),
];

const List<Denomination> kUsdBillDenominations = [
  Denomination('100', 100, currencyCode: 'USD'),
  Denomination('50', 50, currencyCode: 'USD'),
  Denomination('20', 20, currencyCode: 'USD'),
  Denomination('5', 5, currencyCode: 'USD'),
  Denomination('1', 1, currencyCode: 'USD'),
];

const List<Denomination> kCoinDenominations = [];

List<Denomination> _denomsFor(String code) =>
    code == 'USD' ? kUsdBillDenominations : kBillDenominations;

class CashBoxScreen extends StatefulWidget {
  const CashBoxScreen({super.key});

  @override
  State<CashBoxScreen> createState() => _CashBoxScreenState();
}

class _CashBoxScreenState extends State<CashBoxScreen> {
  String _currency = 'CUP';
  late Map<String, int> _countsCup;
  late Map<String, int> _countsUsd;
  final TextEditingController _expectedController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _showExpected = false;

  @override
  void initState() {
    super.initState();
    _countsCup = _initialCountsFor(kBillDenominations);
    _countsUsd = _initialCountsFor(kUsdBillDenominations);
  }

  @override
  void dispose() {
    _expectedController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Map<String, int> _initialCountsFor(List<Denomination> denoms) {
    final map = <String, int>{};
    for (final d in denoms) {
      map[d.label] = 0;
    }
    return map;
  }

  double get _totalCup {
    double sum = 0;
    _countsCup.forEach((label, count) {
      sum += (double.tryParse(label) ?? 0) * count;
    });
    return sum;
  }

  double get _totalUsd {
    double sum = 0;
    _countsUsd.forEach((label, count) {
      sum += (double.tryParse(label) ?? 0) * count;
    });
    return sum;
  }

  Map<String, int> get _activeCounts =>
      _currency == 'USD' ? _countsUsd : _countsCup;

  List<Denomination> get _activeDenoms => _denomsFor(_currency);

  double? get _expected {
    final t = double.tryParse(_expectedController.text);
    return t;
  }

  void _setCount(String label, int value) {
    setState(() {
      _activeCounts[label] = value < 0 ? 0 : value;
    });
  }

  void _reset() {
    setState(() {
      _countsCup = _initialCountsFor(kBillDenominations);
      _countsUsd = _initialCountsFor(kUsdBillDenominations);
      _expectedController.clear();
      _noteController.clear();
      _showExpected = false;
    });
  }

  Future<void> _save(DatabaseService db) async {
    final cupCounts = Map<String, int>.from(_countsCup)
      ..removeWhere((k, v) => v == 0);
    final usdCounts = Map<String, int>.from(_countsUsd)
      ..removeWhere((k, v) => v == 0);

    if (cupCounts.isEmpty && usdCounts.isEmpty) {
      _showSnack('Ingresa al menos una cantidad');
      return;
    }

    final expected = _showExpected ? _expected : null;
    final now = DateTime.now();
    final note = _noteController.text.trim().isEmpty
        ? null
        : _noteController.text.trim();

    if (cupCounts.isNotEmpty) {
      await db.addCashCount(
        CashCount(
          date: now,
          denominations: cupCounts,
          expectedAmount: expected,
          note: note,
          currencyCode: 'CUP',
        ),
      );
    }
    if (usdCounts.isNotEmpty) {
      await db.addCashCount(
        CashCount(
          date: now,
          denominations: usdCounts,
          expectedAmount: null,
          note: note,
          currencyCode: 'USD',
        ),
      );
    }

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
                    Text(
                      'Caja Contable',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Cuenta el dinero por billetes (CUP y USD)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _TotalsCards(
                      totalCup: _totalCup,
                      totalUsd: _totalUsd,
                      expected: _showExpected ? _expected : null,
                    ),
                    const SizedBox(height: 14),
                    _CurrencySelector(
                      value: _currency,
                      onChanged: (v) => setState(() => _currency = v),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Billetes (${_currency == 'USD' ? 'USD' : 'CUP'})',
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
                delegate: SliverChildBuilderDelegate((context, index) {
                  final d = _activeDenoms[index];
                  return _DenominationTile(
                    denomination: d,
                    count: _activeCounts[d.label] ?? 0,
                    onCountChanged: (v) => _setCount(d.label, v),
                  );
                }, childCount: _activeDenoms.length),
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
                                Icon(
                                  Icons.fact_check_outlined,
                                  color: AppColors.navy,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
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
                                  onChanged: (v) =>
                                      setState(() => _showExpected = v),
                                ),
                              ],
                            ),
                            if (_showExpected) ...[
                              const SizedBox(height: 8),
                              TextField(
                                controller: _expectedController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Monto esperado (CUP)',
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
                  ],
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
                      icon: Icon(
                        Icons.delete_sweep_outlined,
                        color: AppColors.danger,
                      ),
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
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 56,
                              color: AppColors.border,
                            ),
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
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final count = counts[counts.length - 1 - index];
                      final key = box.keyAt(counts.length - 1 - index);
                      return _HistoryTile(
                        count: count,
                        onDelete: () => _confirmDeleteHistory(db, key),
                        onTap: () => _showDetail(count),
                      );
                    }, childCount: counts.length),
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
        content: const Text(
          '¿Quieres eliminar este registro de la caja contable?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: TextStyle(color: AppColors.danger)),
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
        content: const Text(
          'Se eliminarán todas las cajas guardadas. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Eliminar todo',
              style: TextStyle(color: AppColors.danger),
            ),
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
        final isUsd = count.currency == CashCurrency.usd;
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
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isUsd ? AppColors.navySoft : AppColors.turquoiseSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    count.currencyLabel,
                    style: TextStyle(
                      color: isUsd ? AppColors.navy : AppColors.turquoise,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (count.note != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    count.note!,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontStyle: FontStyle.italic,
                    ),
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
                          '${isUsd ? 'USD' : 'CUP'} ${formatCents(v)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text('× ${e.value}'),
                        Text(
                          isUsd
                              ? formatUsd(v * e.value)
                              : formatMoney(v * e.value),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
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
                    isUsd ? formatUsd(count.total) : formatMoney(count.total),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald,
                    ),
                  ),
                ],
              ),
              if (count.difference != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Diferencia vs esperado',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${count.difference! >= 0 ? '+' : ''}'
                        '${isUsd ? formatUsd(count.difference!) : formatMoney(count.difference!)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: count.difference! >= 0
                              ? AppColors.emerald
                              : AppColors.danger,
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

class _TotalsCards extends StatelessWidget {
  final double totalCup;
  final double totalUsd;
  final double? expected;

  const _TotalsCards({
    required this.totalCup,
    required this.totalUsd,
    required this.expected,
  });

  @override
  Widget build(BuildContext context) {
    final diff = expected == null ? null : totalCup - expected!;
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.navy, AppColors.turquoise],
            ),
            borderRadius: BorderRadius.circular(20),
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
                  Icon(
                    Icons.payments_outlined,
                    color: Colors.white70,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Total contado (CUP)',
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
                formatMoney(totalCup),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              if (diff != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.navySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.attach_money,
                  color: AppColors.navy,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total contado (USD)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatUsd(totalUsd),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CurrencySelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _CurrencySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'CUP',
          label: Text('CUP'),
          icon: Icon(Icons.flag_outlined),
        ),
        ButtonSegment(
          value: 'USD',
          label: Text('USD'),
          icon: Icon(Icons.attach_money),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return value == 'USD' ? AppColors.navy : AppColors.turquoise;
          }
          return AppColors.surface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return AppColors.textPrimary;
        }),
        side: WidgetStateProperty.all(BorderSide(color: AppColors.border)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
    final isUsd = denomination.currencyCode == 'USD';
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: count > 0
              ? (isUsd
                    ? AppColors.navy.withOpacity(0.6)
                    : AppColors.emerald.withOpacity(0.6))
              : AppColors.border,
        ),
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
                Icon(Icons.circle, color: AppColors.turquoise, size: 13)
              else
                Icon(
                  Icons.rectangle_outlined,
                  color: isUsd ? AppColors.navy : AppColors.navy,
                  size: 13,
                ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${isUsd ? 'USD' : 'CUP'} ${formatCents(denomination.value)}',
                  style: TextStyle(
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
                        style: TextStyle(
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
            subtotal == 0
                ? '—'
                : (isUsd
                      ? formatUsdCompact(subtotal)
                      : formatMoneyCompact(subtotal)),
            style: TextStyle(
              color: subtotal == 0
                  ? AppColors.textSecondary
                  : (isUsd ? AppColors.navy : AppColors.emerald),
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
    final isUsd = denomination.currencyCode == 'USD';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Cantidad de ${isUsd ? 'USD' : 'CUP'} ${formatCents(denomination.value)}',
        ),
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
    final isUsd = count.currency == CashCurrency.usd;
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
            color: isUsd ? AppColors.navySoft : AppColors.turquoiseSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isUsd ? Icons.attach_money : Icons.account_balance_wallet_outlined,
            color: isUsd ? AppColors.navy : AppColors.turquoise,
            size: 20,
          ),
        ),
        title: Text(
          isUsd ? formatUsd(count.total) : formatMoney(count.total),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          count.note == null ? dateStr : '$dateStr • ${count.note}',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count.difference != null)
              Text(
                '${count.difference! >= 0 ? '+' : ''}'
                '${isUsd ? formatUsd(count.difference!) : formatMoney(count.difference!)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: count.difference! >= 0
                      ? AppColors.emerald
                      : AppColors.danger,
                ),
              ),
            IconButton(
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline,
                color: AppColors.danger,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
