import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/debt.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/payment_methods.dart';

class FiadosScreen extends StatefulWidget {
  const FiadosScreen({super.key});

  @override
  State<FiadosScreen> createState() => _FiadosScreenState();
}

class _FiadosScreenState extends State<FiadosScreen> {
  bool _showPaid = false;

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuentas por Cobrar'),
        actions: [
          IconButton(
            tooltip: 'Nuevo Fiado',
            onPressed: () => _showNewFiadoDialog(context, db),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Box<Debt>>(
          valueListenable: db.debtsListenable,
          builder: (context, box, _) {
            final all = box.values.toList().cast<Debt>();
            final outstanding = db.getTotalOutstanding();
            final collected = db.getTotalCreditCollected();
            final debts = _showPaid ? db.getPaidDebts() : db.getActiveDebts();
            debts.sort((a, b) => b.date.compareTo(a.date));

            return RefreshIndicator(
              onRefresh: () async {},
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HeaderCard(
                            outstanding: outstanding,
                            totalSold: db.getTotalCreditSold(),
                            collected: collected,
                          ),
                          const SizedBox(height: 16),
                          _ToggleTabs(
                            showPaid: _showPaid,
                            activeCount: db.getActiveDebts().length,
                            paidCount: db.getPaidDebts().length,
                            onChanged: (v) => setState(() => _showPaid = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (all.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  else if (debts.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          _showPaid
                              ? 'No hay fiados pagados'
                              : '¡No tienes deudas pendientes!',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final debt = debts[index];
                          final key = box.keyAt(
                            box.values.toList().indexWhere(
                              (d) => identical(d, debt),
                            ),
                          );
                          return _DebtTile(
                            debt: debt,
                            onTap: () =>
                                _showDebtDetail(context, db, debt, key),
                            onPay: () =>
                                _showAbonoDialog(context, db, debt, key),
                            onDelete: () => _confirmDelete(db, key, debt),
                          );
                        }, childCount: debts.length),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(DatabaseService db, dynamic key, Debt debt) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar fiado'),
        content: Text(
          'Se eliminará la deuda de ${debt.customerName} y se repondrá el stock del producto.',
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
      await db.deleteDebt(key);
    }
  }

  void _showNewFiadoDialog(BuildContext context, DatabaseService db) {
    final productBox = db.productsBox;
    final products = productBox.values.toList().cast<Product>();

    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero agrega productos al inventario')),
      );
      return;
    }

    Product? selected;
    for (final p in products) {
      if (p.stock > 0) {
        selected = p;
        break;
      }
    }
    selected ??= products.isNotEmpty ? products.first : null;
    final qtyController = TextEditingController(text: '1');
    final customerController = TextEditingController();
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Nuevo Fiado'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Product>(
                    value: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Producto',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                    items: products.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text('${p.name} (Stock: ${p.stock})'),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => selected = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: customerController,
                    decoration: const InputDecoration(
                      labelText: 'Cliente',
                      hintText: 'Nombre del cliente',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Nota (opcional)',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (selected != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Total a deber: ${formatMoney(selected!.sellPrice * (int.tryParse(qtyController.text) ?? 1))}',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = customerController.text.trim();
                  final qty = int.tryParse(qtyController.text) ?? 0;
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ingresa el nombre del cliente'),
                      ),
                    );
                    return;
                  }
                  if (selected == null || qty <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cantidad inválida')),
                    );
                    return;
                  }
                  if (qty > selected!.stock) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Stock insuficiente (Máx: ${selected!.stock})',
                        ),
                      ),
                    );
                    return;
                  }
                  await db.registerCreditSale(
                    selected!,
                    qty,
                    name,
                    note: noteController.text.trim().isEmpty
                        ? null
                        : noteController.text.trim(),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAbonoDialog(
    BuildContext context,
    DatabaseService db,
    Debt debt,
    dynamic key,
  ) {
    final amountController = TextEditingController(
      text: formatCents(debt.balance),
    );
    String method = PaymentMethod.cash;
    final commissionController = TextEditingController();
    bool applyCommission = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final amount = double.tryParse(amountController.text) ?? 0;
          final commission = applyCommission
              ? (double.tryParse(commissionController.text) ?? 0)
              : 0.0;
          return AlertDialog(
            title: const Text('Registrar Abono'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Cliente: ${debt.customerName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Saldo pendiente: ${formatMoney(debt.balance)}',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Monto del abono',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: PaymentMethod.cash,
                        icon: Icon(Icons.payments_outlined),
                        label: Text('Efectivo'),
                      ),
                      ButtonSegment(
                        value: PaymentMethod.transfer,
                        icon: Icon(Icons.account_balance_outlined),
                        label: Text('Transf.'),
                      ),
                    ],
                    selected: {method},
                    onSelectionChanged: (s) => setState(() => method = s.first),
                  ),
                  if (method == PaymentMethod.transfer) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Comisión',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        Switch(
                          value: applyCommission,
                          activeThumbColor: AppColors.emerald,
                          onChanged: (v) => setState(() => applyCommission = v),
                        ),
                      ],
                    ),
                    if (applyCommission) ...[
                      TextField(
                        controller: commissionController,
                        decoration: const InputDecoration(
                          labelText: 'Comisión (CUP)',
                          prefixIcon: Icon(Icons.percent),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      Text(
                        'Neto recibido: ${formatMoney(amount - commission)}',
                        style: TextStyle(
                          color: AppColors.emerald,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amt = double.tryParse(amountController.text) ?? 0;
                  if (amt <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Monto inválido')),
                    );
                    return;
                  }
                  if (amt > debt.balance + 0.001) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'El abono excede el saldo (${formatMoney(debt.balance)})',
                        ),
                      ),
                    );
                    return;
                  }
                  await db.addDebtPayment(
                    key,
                    amt,
                    method,
                    commissionAmount: applyCommission ? commission : null,
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Guardar Abono'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDebtDetail(
    BuildContext context,
    DatabaseService db,
    Debt debt,
    dynamic key,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final dateStr = DateFormat('dd/MM/yyyy').format(debt.date);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person_outline, color: AppColors.navy, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt.customerName,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          '$dateStr • ${debt.productName} × ${debt.quantity}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: debt.isPaid
                          ? AppColors.emeraldSoft
                          : AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      debt.isPaid ? 'PAGADO' : 'ADEUDA',
                      style: TextStyle(
                        color: debt.isPaid
                            ? AppColors.emerald
                            : AppColors.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (debt.note != null) ...[
                const SizedBox(height: 8),
                Text(
                  debt.note!,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total de la deuda',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    formatMoney(debt.total),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Abonado',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    formatMoney(debt.paid),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.emerald,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saldo pendiente',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  Text(
                    formatMoney(debt.balance),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: debt.isPaid ? AppColors.emerald : AppColors.danger,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (debt.payments.isNotEmpty) ...[
                const Divider(height: 24),
                const Text(
                  'Abonos',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: debt.payments.length,
                    separatorBuilder: (_, _) => const Divider(height: 16),
                    itemBuilder: (context, i) {
                      final p = debt.payments[i];
                      final pDate = DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(p.date);
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                PaymentMethod.icon(p.method),
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${PaymentMethod.label(p.method)} • $pDate',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '-${formatMoney(p.amount)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (p.commissionAmount != null)
                                Text(
                                  'comisión ${formatMoney(p.commissionAmount!)}',
                                  style: TextStyle(
                                    color: AppColors.danger,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (!debt.isPaid)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAbonoDialog(context, db, debt, key);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                    ),
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Registrar Abono'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final double outstanding;
  final double totalSold;
  final double collected;

  const _HeaderCard({
    required this.outstanding,
    required this.totalSold,
    required this.collected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
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
              Icon(Icons.handshake_outlined, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'Por cobrar en total',
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
            formatMoney(outstanding),
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
              _HeaderStat(label: 'Fiado', value: formatMoney(totalSold)),
              Container(width: 1, height: 32, color: Colors.white24),
              _HeaderStat(label: 'Cobrado', value: formatMoney(collected)),
            ],
          ),
        ],
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ToggleTabs extends StatelessWidget {
  final bool showPaid;
  final int activeCount;
  final int paidCount;
  final ValueChanged<bool> onChanged;

  const _ToggleTabs({
    required this.showPaid,
    required this.activeCount,
    required this.paidCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _tab(false, 'Activas', activeCount)),
        const SizedBox(width: 8),
        Expanded(child: _tab(true, 'Pagadas', paidCount)),
      ],
    );
  }

  Widget _tab(bool isPaid, String label, int count) {
    final selected = showPaid == isPaid;
    return InkWell(
      onTap: () => onChanged(isPaid),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.navy : AppColors.border,
          ),
        ),
        child: Text(
          '$label ($count)',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.turquoiseSoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.handshake_outlined,
                size: 44,
                color: AppColors.turquoise,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No hay fiados registrados',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Usa el botón + para registrar una venta a crédito',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtTile extends StatelessWidget {
  final Debt debt;
  final VoidCallback onTap;
  final VoidCallback onPay;
  final VoidCallback onDelete;

  const _DebtTile({
    required this.debt,
    required this.onTap,
    required this.onPay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(debt.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: debt.isPaid
              ? AppColors.emerald.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: debt.isPaid
                    ? AppColors.emeraldSoft
                    : AppColors.warningSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.person_outline,
                color: debt.isPaid ? AppColors.emerald : AppColors.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.customerName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${debt.productName} × ${debt.quantity} • $dateStr',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMoney(debt.balance),
                  style: TextStyle(
                    color: debt.isPaid ? AppColors.emerald : AppColors.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  debt.isPaid ? 'pagado' : 'de ${formatMoney(debt.total)}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            if (!debt.isPaid) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Registrar abono',
                onPressed: onPay,
                icon: Icon(
                  Icons.payments_outlined,
                  color: AppColors.emerald,
                  size: 20,
                ),
              ),
            ],
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
