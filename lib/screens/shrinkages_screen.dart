import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/shrinkage.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class ShrinkagesScreen extends StatelessWidget {
  const ShrinkagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mermas',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Box<Shrinkage>>(
          valueListenable: db.shrinkagesListenable,
          builder: (context, box, _) {
            final shrinkages = db.getShrinkages();
            if (shrinkages.isEmpty) {
              return _EmptyState(
                onAdd: () => _openForm(context, db),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: shrinkages.length,
              itemBuilder: (context, index) {
                final shrinkage = shrinkages[index];
                return _ShrinkageTile(
                  shrinkage: shrinkage,
                  onDelete: () =>
                      _confirmDelete(context, db, shrinkage.key),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, db),
        label: const Text('Registrar Merma'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context, DatabaseService db) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _ShrinkageFormScreen(db: db)),
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
        title: const Text('Eliminar merma'),
        content: const Text(
          'Se quitará del historial y se devolverá el stock al producto. '
          '¿Continuar?',
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
      await db.deleteShrinkage(key);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Merma eliminada')));
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

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
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.do_not_disturb_alt,
                size: 44,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No hay mermas registradas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Registra productos dañados, vencidos o perdidos para que '
              'las cuentas del negocio no fallen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Registrar merma'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShrinkageTile extends StatelessWidget {
  final Shrinkage shrinkage;
  final VoidCallback onDelete;

  const _ShrinkageTile({required this.shrinkage, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy • HH:mm').format(shrinkage.date);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.report_gmailerrorred_outlined,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shrinkage.productName,
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
                  '$dateStr • ${shrinkage.reason} • ${shrinkage.quantity} u',
                  style: TextStyle(
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
                '-${formatMoney(shrinkage.cost)}',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                'costo por u: ${formatMoney(shrinkage.unitCost)}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
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
    );
  }
}

class _ShrinkageFormScreen extends StatefulWidget {
  final DatabaseService db;

  const _ShrinkageFormScreen({required this.db});

  @override
  State<_ShrinkageFormScreen> createState() => _ShrinkageFormScreenState();
}

class _ShrinkageFormScreenState extends State<_ShrinkageFormScreen> {
  final _quantityController = TextEditingController(text: '1');
  DateTime _date = DateTime.now();
  String? _selectedProductName;
  String _reason = Shrinkage.reasons.first;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.db.productsBox.values
        .toList()
        .cast<Product>()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Registrar Merma',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (products.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.warning,
                        size: 32,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Primero agrega productos en el inventario',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                _buildDatePicker(),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedProductName,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Producto',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  hint: const Text('Selecciona un producto'),
                  items: [
                    for (final p in products)
                      DropdownMenuItem(value: p.name, child: Text(p.name)),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedProductName = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _reason,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  items: [
                    for (final r in Shrinkage.reasons)
                      DropdownMenuItem(value: r, child: Text(r)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _reason = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad perdida',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 12),
                _costPreview(),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _selectedProductName == null
                      ? null
                      : () => _save(products),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('GUARDAR MERMA'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          helpText: 'Fecha de la merma',
        );
        if (picked != null) {
          setState(() {
            _date = DateTime(
              picked.year,
              picked.month,
              picked.day,
              _date.hour,
              _date.minute,
            );
          });
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.event, color: AppColors.navy, size: 20),
            const SizedBox(width: 10),
            Text(
              DateFormat('EEEE, d MMMM yyyy', 'es').format(_date),
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _costPreview() {
    final product = _selectedProductName == null
        ? null
        : widget.db.productByName(_selectedProductName!);
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final cost = product == null ? 0.0 : product.buyPrice * quantity;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Pérdida estimada',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            product == null
                ? '—'
                : '-${formatMoney(cost)}',
            style: TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _save(List<Product> products) async {
    final index = products.indexWhere(
      (p) => p.name == _selectedProductName,
    );
    if (index < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un producto')),
      );
      return;
    }
    final product = products[index];
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cantidad inválida')),
      );
      return;
    }
    await widget.db.addShrinkage(
      Shrinkage(
        date: _date,
        productName: product.name,
        productId: product.productId,
        quantity: quantity,
        unitCost: product.buyPrice,
        reason: _reason,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merma registrada. Stock actualizado')),
    );
  }
}