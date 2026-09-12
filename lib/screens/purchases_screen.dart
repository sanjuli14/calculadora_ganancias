import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = Provider.of<DatabaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Compras',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Box<Purchase>>(
          valueListenable: db.purchasesListenable,
          builder: (context, box, _) {
            final purchases = db.getPurchases();
            if (purchases.isEmpty) {
              return _EmptyState(
                onAdd: () => _openForm(context, db),
              );
            }
            final totalInvestment =
                purchases.fold(0.0, (s, p) => s + p.totalCost);
            final totalUnits = purchases.fold(
              0,
              (s, p) => s + p.totalUnits,
            );
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                _InvestmentSummary(
                  amount: totalInvestment,
                  lots: purchases.length,
                  units: totalUnits,
                ),
                const SizedBox(height: 16),
                for (final purchase in purchases)
                  _PurchaseTile(
                    purchase: purchase,
                    onDelete: () => _confirmDelete(context, db, purchase.key),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(context, db),
        label: const Text('Nueva Compra'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context, DatabaseService db) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _PurchaseFormScreen(db: db)),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DatabaseService db,
    dynamic key,
  ) async {
    final purchase = db.purchasesBox.get(key);
    final soldOut = <String>[];
    if (purchase != null) {
      for (final item in purchase.items) {
        final current = db.productByName(item.productName)?.stock ?? 0;
        if (current < item.quantity) {
          soldOut.add(
            '${item.productName}: quedan $current en stock, '
            '${item.quantity - current} ya se vendieron.',
          );
        }
      }
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar compra'),
        content: Text(
          soldOut.isEmpty
              ? 'Se quitará este lote del historial y se revertirá el stock '
                  'que subió. ¿Continuar?'
              : 'Se quitará este lote del historial y se revertirá el stock '
                  'que subió, pero parte ya se vendió:\n\n'
                  '${soldOut.join('\n')}\n\n¿Continuar?',
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
      await db.deletePurchase(key);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Compra eliminada')));
      }
    }
  }
}

class _InvestmentSummary extends StatelessWidget {
  final double amount;
  final int lots;
  final int units;

  const _InvestmentSummary({
    required this.amount,
    required this.lots,
    required this.units,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.turquoise],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.savings_outlined, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'Capital en mercancía (compras)',
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
            formatMoney(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryStat('$lots', 'compras'),
              Container(width: 1, height: 28, color: Colors.white24),
              _summaryStat('$units', 'unidades'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String value, String label) {
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
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
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
                color: AppColors.navySoft,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                Icons.local_shipping_outlined,
                size: 44,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No hay compras registradas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Registra cada compra de mercancía para llevar el historial '
              'de inversión del negocio.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Registrar compra'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  final Purchase purchase;
  final VoidCallback onDelete;

  const _PurchaseTile({required this.purchase, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy • HH:mm').format(purchase.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.navy, AppColors.turquoise],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      purchase.supplierName.trim().isEmpty
                          ? 'Compra de mercancía'
                          : purchase.supplierName.trim(),
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
                      '$dateStr • ${purchase.items.length} productos • '
                      '${purchase.totalUnits} u',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
          const SizedBox(height: 10),
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in purchase.items)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item.productName} ×${item.quantity}',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total invertido',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '-${formatMoney(purchase.totalCost)}',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PurchaseLine {
  final Product product;
  int quantity;
  double unitCost;

  _PurchaseLine(this.product, this.quantity, this.unitCost);
}

class _PurchaseFormScreen extends StatefulWidget {
  final DatabaseService db;

  const _PurchaseFormScreen({required this.db});

  @override
  State<_PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends State<_PurchaseFormScreen> {
  static const String _newProductValue = '__nuevo_producto__';

  final _supplierController = TextEditingController();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final List<_PurchaseLine> _lines = [];
  final Set<String> _newProductNames = {};
  DateTime _date = DateTime.now();
  String? _selectedProductName;

  @override
  void dispose() {
    _supplierController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    super.dispose();
  }

  double get _totalCost =>
      _lines.fold(0.0, (s, l) => s + l.quantity * l.unitCost);

  @override
  Widget build(BuildContext context) {
    final products = widget.db.productsBox.values
        .toList()
        .cast<Product>()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nueva Compra',
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
              if (products.isEmpty) _hintEmptyCatalogCard(),
              _buildDatePicker(),
              const SizedBox(height: 16),
              TextField(
                controller: _supplierController,
                decoration: const InputDecoration(
                  labelText: 'Proveedor (opcional)',
                  hintText: 'Nombre de quien vendió la mercancía',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.navySoft,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.add_box_outlined,
                      size: 20,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Agregar productos',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedProductName),
                initialValue: _selectedProductName,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Producto',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                hint: const Text('Selecciona o crea un producto'),
                items: [
                  for (final p in products)
                    DropdownMenuItem(value: p.name, child: Text(p.name)),
                  DropdownMenuItem(
                    value: _newProductValue,
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 18,
                          color: AppColors.emerald,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Crear producto nuevo',
                          style: TextStyle(
                            color: AppColors.emerald,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value == _newProductValue) {
                    _createNewProduct();
                    return;
                  }
                  if (value == null) return;
                  setState(() {
                    _selectedProductName = value;
                    final product = products.firstWhere(
                      (p) => p.name == value,
                      orElse: () => products.first,
                    );
                    _costController.text = formatCents(product.buyPrice);
                    _quantityController.text = '1';
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cantidad',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 5,
                    child: TextField(
                      controller: _costController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Costo unitario',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: IconButton.filled(
                        onPressed: _addLine,
                        tooltip: 'Agregar al lote',
                        icon: const Icon(Icons.add, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              if (_lines.isNotEmpty) ...[
                const SizedBox(height: 16),
                for (final line in _lines)
                  _LineTile(
                    line: line,
                    onRemove: () => setState(() => _lines.remove(line)),
                  ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.navy, AppColors.turquoise],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total del lote (${_lines.length} productos)',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        formatMoney(_totalCost),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _lines.isEmpty ? null : () => _save(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.save_outlined),
                label: const Text('GUARDAR COMPRA'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hintEmptyCatalogCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.warningSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: AppColors.warning, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tu catálogo está vacío. Crea el primer producto con la '
              'opción "Crear producto nuevo".',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
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
          helpText: 'Fecha de la compra',
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

  double _parseNumber(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _createNewProduct() async {
    final nameController = TextEditingController();
    final sellPriceController = TextEditingController();
    final categories = widget.db.getCategories();
    String selectedCategory = '';

    final product = await showDialog<Product>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo producto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Se agregará al catálogo para que puedas incluirlo en esta '
                  'y futuras compras.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Nombre*',
                    hintText: 'Ej: Galletas Soda',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: sellPriceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Precio de venta*',
                    hintText: 'Cuánto se cobra al cliente',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory.isEmpty
                      ? null
                      : selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  hint: const Text('Sin categoría'),
                  isExpanded: true,
                  items: [
                    if (selectedCategory.isNotEmpty &&
                        !categories.contains(selectedCategory))
                      DropdownMenuItem(
                        value: selectedCategory,
                        child: Text(selectedCategory),
                      ),
                    for (final c in categories)
                      DropdownMenuItem(value: c, child: Text(c)),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => selectedCategory = value ?? ''),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final sellPrice = _parseNumber(sellPriceController.text);
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El nombre es obligatorio')),
                  );
                  return;
                }
                if (sellPrice <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Precio de venta inválido')),
                  );
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  Product(
                    name: name,
                    buyPrice: 0,
                    sellPrice: sellPrice,
                    stock: 0,
                    category: selectedCategory.trim(),
                  ),
                );
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );

    if (product == null) return;
    await widget.db.addProduct(product);
    if (!mounted) return;
    setState(() {
      _newProductNames.add(product.name);
      _selectedProductName = product.name;
      _quantityController.text = '1';
      _costController.clear();
    });
  }

  void _addLine() {
    if (_selectedProductName == null) {
      _showSnack('Selecciona un producto');
      return;
    }
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final unitCost = _parseNumber(_costController.text);
    if (quantity <= 0) {
      _showSnack('Cantidad inválida');
      return;
    }
    if (unitCost < 0) {
      _showSnack('Costo inválido');
      return;
    }
    final product = widget.db.productByName(_selectedProductName!);
    if (product == null) {
      _showSnack('El producto ya no existe');
      return;
    }
    // Si el producto se creó en esta compra, usamos el costo real del lote
    // como su precio de compra base.
    if (_newProductNames.contains(product.name) && unitCost > 0) {
      product.buyPrice = unitCost;
      product.save();
    }
    setState(() {
      _lines.add(_PurchaseLine(product, quantity, unitCost));
      _quantityController.text = '1';
      _selectedProductName = null;
      _costController.clear();
    });
  }

  void _save() async {
    final items = [
      for (final line in _lines)
        PurchaseItem(
          productName: line.product.name,
          productId: line.product.productId,
          quantity: line.quantity,
          unitCost: line.unitCost,
        ),
    ];
    await widget.db.addPurchase(
      Purchase(
        date: _date,
        supplierName: _supplierController.text.trim(),
        items: items,
        totalCost: _totalCost,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compra registrada. Stock actualizado')),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LineTile extends StatelessWidget {
  final _PurchaseLine line;
  final VoidCallback onRemove;

  const _LineTile({required this.line, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.navySoft,
            child: Text(
              line.product.name.isNotEmpty
                  ? line.product.name.substring(0, 1).toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.product.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${line.quantity} u × ${formatMoney(line.unitCost)} = '
                  '${formatMoney(line.quantity * line.unitCost)}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: Icon(Icons.close, color: AppColors.danger, size: 20),
          ),
        ],
      ),
    );
  }
}