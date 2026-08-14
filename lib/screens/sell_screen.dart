import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/transfer_account.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/payment_methods.dart';
import 'transfer_accounts_screen.dart';
import 'calculator_screen.dart';

class _CartItem {
  final Product product;
  int quantity;

  _CartItem(this.product, this.quantity);
}

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  final List<_CartItem> _cart = [];
  final _customerController = TextEditingController();
  final _commissionController = TextEditingController();
  final _exchangeRateController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _paymentMethod = PaymentMethod.cash;
  bool _applyCommission = false;
  dynamic _selectedAccountKey;

  @override
  void dispose() {
    _customerController.dispose();
    _commissionController.dispose();
    _exchangeRateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _commission {
    if (_paymentMethod != PaymentMethod.transfer || !_applyCommission) return 0;
    return double.tryParse(_commissionController.text) ?? 0;
  }

  double? get _exchangeRate {
    if (_paymentMethod != PaymentMethod.dollar) return null;
    final v = double.tryParse(_exchangeRateController.text);
    return (v == null || v <= 0) ? null : v;
  }

  int _inCartFor(Product product) {
    return _cart
        .where((i) => i.product.name == product.name)
        .fold(0, (sum, i) => sum + i.quantity);
  }

  int get _cartItemCount => _cart.fold(0, (sum, i) => sum + i.quantity);

  bool get _isOwnExpense => _paymentMethod == PaymentMethod.ownExpense;

  double get _cartTotal {
    return _cart.fold(0.0, (s, i) => s + i.quantity * (i.product.buyPrice));
  }

  void _addUnit(Product product) {
    if (product.stock <= 0) {
      _showSnack('${product.name}: agotado');
      return;
    }
    final inCart = _inCartFor(product);
    if (inCart >= product.stock) {
      _showSnack('Stock insuficiente de ${product.name} (Máx: ${product.stock})');
      return;
    }
    final existing = _cart
        .where((i) => i.product.name == product.name)
        .toList();
    setState(() {
      if (existing.isNotEmpty) {
        existing.first.quantity += 1;
      } else {
        _cart.add(_CartItem(product, 1));
      }
    });
  }

  void _changeQuantity(_CartItem item, int delta) {
    final next = item.quantity + delta;
    if (next <= 0) {
      setState(() => _cart.remove(item));
      return;
    }
    if (next > item.product.stock) {
      _showSnack('Stock insuficiente (Máx: ${item.product.stock})');
      return;
    }
    setState(() => item.quantity = next);
  }

  void _clearCart() {
    setState(() => _cart.clear());
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Registrar Venta',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Abrir calculadora',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CalculatorScreen())),
            icon: Icon(Icons.calculate_outlined, color: AppColors.navy),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Registrar Venta',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Toca un producto para añadirlo. Toca de nuevo para sumar más unidades',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                ValueListenableBuilder<Box<Product>>(
                  valueListenable: databaseService.productsListenable,
                  builder: (context, box, _) {
                    final products = box.values.toList().cast<Product>();

                    if (products.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.textSecondary,
                              size: 40,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No hay productos disponibles',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Agrega inventario primero',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Productos',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Toca para añadir',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            return _ProductTile(
                              product: product,
                              inCart: _inCartFor(product),
                              onTap: () => _addUnit(product),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                if (_cart.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Carrito ($_cartItemCount producto${_cartItemCount == 1 ? '' : 's'})',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _clearCart,
                        icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                        label: const Text('Vaciar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._cart.map(
                    (item) => _CartLine(
                      item: item,
                      isOwnExpense: _isOwnExpense,
                      onChange: (delta) => _changeQuantity(item, delta),
                      onRemove: () => setState(() => _cart.remove(item)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                _MethodSelector(
                  selected: _paymentMethod,
                  onChanged: (m) => setState(() {
                    _paymentMethod = m;
                    if (m != PaymentMethod.transfer) {
                      _selectedAccountKey = null;
                    }
                  }),
                ),
                const SizedBox(height: 16),
                if (_paymentMethod == PaymentMethod.credit) ...[
                  TextFormField(
                    controller: _customerController,
                    decoration: const InputDecoration(
                      labelText: 'Cliente',
                      hintText: 'Nombre del cliente',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingrese el nombre del cliente';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      labelText: 'Nota (opcional)',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                ] else if (_paymentMethod == PaymentMethod.transfer) ...[
                  ValueListenableBuilder<Box<TransferAccount>>(
                    valueListenable: databaseService.transferAccountsListenable,
                    builder: (context, box, _) {
                      final accounts = databaseService.getTransferAccounts();
                      return _TransferAccountPicker(
                        accounts: accounts,
                        selectedKey: _selectedAccountKey,
                        onSelected: (key) =>
                            setState(() => _selectedAccountKey = key),
                        onCreate: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TransferAccountsScreen(),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.navySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.percent, color: AppColors.navy, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '¿Aplica comisión por transferencia?',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Switch(
                          value: _applyCommission,
                          activeThumbColor: AppColors.emerald,
                          onChanged: (v) =>
                              setState(() => _applyCommission = v),
                        ),
                      ],
                    ),
                  ),
                  if (_applyCommission) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _commissionController,
                      decoration: const InputDecoration(
                        labelText: 'Comisión (CUP)',
                        prefixIcon: Icon(Icons.percent),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        final v = double.tryParse(value ?? '');
                        if (value == null ||
                            value.isEmpty ||
                            v == null ||
                            v < 0) {
                          return 'Comisión inválida';
                        }
                        return null;
                      },
                    ),
                  ],
                ] else if (_paymentMethod == PaymentMethod.dollar) ...[
                  TextFormField(
                    controller: _exchangeRateController,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de cambio (1 USD en CUP)',
                      hintText: 'Ej: 120',
                      prefixIcon: Icon(Icons.currency_exchange),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final v = double.tryParse(value ?? '');
                      if (value == null ||
                          value.isEmpty ||
                          v == null ||
                          v <= 0) {
                        return 'Ingresa el tipo de cambio';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 20),
                _SaleSummaryCard(
                  cart: _cart,
                  paymentMethod: _paymentMethod,
                  commission: _commission,
                  exchangeRate: _exchangeRate,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _processSale(databaseService),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _paymentMethod == PaymentMethod.credit
                        ? AppColors.turquoise
                        : _paymentMethod == PaymentMethod.ownExpense
                        ? AppColors.warning
                        : AppColors.emerald,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    _paymentMethod == PaymentMethod.credit
                        ? Icons.handshake_outlined
                        : _paymentMethod == PaymentMethod.ownExpense
                        ? Icons.person_outline
                        : Icons.check_circle_outline,
                  ),
                  label: Text(
                    _paymentMethod == PaymentMethod.credit
                        ? 'REGISTRAR FIADO'
                        : _paymentMethod == PaymentMethod.ownExpense
                        ? 'REGISTRAR GASTO PROPIO'
                        : 'CONFIRMAR VENTA',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _processSale(DatabaseService db) async {
    if (_cart.isEmpty) {
      _showSnack('Agrega al menos un producto al carrito');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();

    if (_paymentMethod == PaymentMethod.credit) {
      final customer = _customerController.text.trim();
      final note = _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim();
      for (final item in _cart) {
        await db.registerCreditSale(
          item.product,
          item.quantity,
          customer,
          note: note,
        );
      }
      if (!mounted) return;
      _showSnack(
        'Fiado registrado por $customer (${_cart.length} producto${_cart.length == 1 ? '' : 's'})',
      );
      _resetForm();
      return;
    }

    final totalSubtotal = _cart.fold(
      0.0,
      (s, i) => s + i.product.sellPrice * i.quantity,
    );

    for (final item in _cart) {
      final subtotal = item.product.sellPrice * item.quantity;
      final sale = Sale(
        productName: item.product.name,
        unitBuyPrice: item.product.buyPrice,
        unitSellPrice: item.product.sellPrice,
        quantity: item.quantity,
        date: now,
        paymentMethod: _paymentMethod,
        commissionAmount: _commission > 0 && totalSubtotal > 0
            ? _commission * (subtotal / totalSubtotal)
            : null,
        exchangeRate: _exchangeRate,
      );

      item.product.stock -= item.quantity;
      await item.product.save();
      await db.addSale(sale);
    }

    if (!mounted) return;
    final parts = <String>[PaymentMethod.label(_paymentMethod)];
    if (_paymentMethod == PaymentMethod.transfer &&
        _selectedAccountKey != null) {
      final acc = db.transferAccountsBox.get(_selectedAccountKey);
      if (acc != null) {
        parts.add('a ${acc.alias}');
      }
    }
    if (_paymentMethod == PaymentMethod.transfer && _commission > 0) {
      parts.add('comisión ${formatMoney(_commission)}');
    }
    if (_paymentMethod == PaymentMethod.dollar && _exchangeRate != null) {
      parts.add('cambio ${formatMoney(_exchangeRate!)}');
    }
    if (_paymentMethod == PaymentMethod.ownExpense) {
      parts.add('descontado ${formatMoney(_cartTotal)} de la inversión');
    }
    _showSnack(
      '${_cart.length} venta${_cart.length == 1 ? '' : 's'} registrada${_cart.length == 1 ? '' : 's'} (${parts.join(', ')})',
    );
    _resetForm();
  }

  void _resetForm() {
    _customerController.clear();
    _commissionController.clear();
    _exchangeRateController.clear();
    _noteController.clear();
    setState(() {
      _cart.clear();
      _paymentMethod = PaymentMethod.cash;
      _applyCommission = false;
      _selectedAccountKey = null;
    });
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final int inCart;
  final VoidCallback onTap;

  const _ProductTile({
    required this.product,
    required this.inCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final soldOut = product.stock <= 0;
    final hasImage =
        product.imagePath != null && File(product.imagePath!).existsSync();

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: soldOut ? null : onTap,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: soldOut
                      ? AppColors.border
                      : inCart > 0
                      ? AppColors.emerald
                      : AppColors.border,
                  width: inCart > 0 ? 1.6 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: soldOut
                            ? AppColors.border.withOpacity(0.3)
                            : AppColors.navySoft,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasImage
                          ? Image.file(
                              File(product.imagePath!),
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Text(
                                product.name.isEmpty
                                    ? '?'
                                    : String.fromCharCodes(
                                        product.name.runes.take(1),
                                      ).toUpperCase(),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: soldOut
                                      ? AppColors.textSecondary
                                      : AppColors.navy,
                                ),
                              ),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: soldOut
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatMoney(product.sellPrice),
                          style: TextStyle(
                            color: soldOut
                                ? AppColors.textSecondary
                                : AppColors.navy,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          soldOut ? 'Agotado' : 'Stock: ${product.stock}',
                          style: TextStyle(
                            color: soldOut
                                ? AppColors.danger
                                : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: soldOut ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.add_circle,
                          size: 22,
                          color: soldOut
                              ? AppColors.border
                              : inCart > 0
                              ? AppColors.emerald
                              : AppColors.navy,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (inCart > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emerald,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    'x$inCart',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartLine extends StatelessWidget {
  final _CartItem item;
  final bool isOwnExpense;
  final ValueChanged<int> onChange;
  final VoidCallback onRemove;

  const _CartLine({
    required this.item,
    required this.isOwnExpense,
    required this.onChange,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final unitPrice = isOwnExpense
        ? item.product.buyPrice
        : item.product.sellPrice;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
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
                      '${formatMoney(unitPrice)} ${isOwnExpense ? '(costo)' : ''}',
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
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                onPressed: () => onChange(-1),
                icon: Icon(Icons.remove_circle_outline, color: AppColors.navy),
              ),
              Expanded(
                child: Text(
                  '${item.quantity} u',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => onChange(1),
                icon: Icon(Icons.add_circle_outline, color: AppColors.navy),
              ),
              const SizedBox(width: 8),
              Text(
                formatMoney(unitPrice * item.quantity),
                style: TextStyle(
                  color: AppColors.textPrimary,
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

class _MethodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _MethodSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Forma de pago',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MethodChip(
              value: PaymentMethod.cash,
              icon: Icons.payments_outlined,
              label: 'Efectivo',
              selected: selected,
              onTap: onChanged,
            ),
            _MethodChip(
              value: PaymentMethod.transfer,
              icon: Icons.account_balance_outlined,
              label: 'Transferencia',
              selected: selected,
              onTap: onChanged,
            ),
            _MethodChip(
              value: PaymentMethod.dollar,
              icon: Icons.attach_money_outlined,
              label: 'Dólar',
              selected: selected,
              onTap: onChanged,
            ),
            _MethodChip(
              value: PaymentMethod.credit,
              icon: Icons.handshake_outlined,
              label: 'Fiado',
              selected: selected,
              onTap: onChanged,
            ),
            _MethodChip(
              value: PaymentMethod.ownExpense,
              icon: Icons.person_outline,
              label: 'Gasto propio',
              selected: selected,
              onTap: onChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String value;
  final IconData icon;
  final String label;
  final String selected;
  final ValueChanged<String> onTap;

  const _MethodChip({
    required this.value,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == value;
    return Material(
      color: isSelected ? AppColors.navy : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => onTap(value),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.navy : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.navy,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaleSummaryCard extends StatelessWidget {
  final List<_CartItem> cart;
  final String paymentMethod;
  final double commission;
  final double? exchangeRate;

  const _SaleSummaryCard({
    required this.cart,
    required this.paymentMethod,
    required this.commission,
    this.exchangeRate,
  });

  @override
  Widget build(BuildContext context) {
    final isOwnExpense = paymentMethod == PaymentMethod.ownExpense;
    final total = cart.fold(
      0.0,
      (s, i) =>
          s +
          i.quantity *
              (isOwnExpense ? i.product.buyPrice : i.product.sellPrice),
    );
    final profit = cart.fold(
      0.0,
      (s, i) => s + i.quantity * (i.product.sellPrice - i.product.buyPrice),
    );
    final count = cart.fold(0, (s, i) => s + i.quantity);
    final net = total - commission;
    final isCredit = paymentMethod == PaymentMethod.credit;
    final isDollar =
        paymentMethod == PaymentMethod.dollar &&
        exchangeRate != null &&
        exchangeRate! > 0;
    final usdTotal = isDollar ? total / exchangeRate! : 0.0;

    if (cart.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.textSecondary,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'El carrito está vacío. Agrega productos.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isCredit
              ? [AppColors.turquoiseSoft, AppColors.navySoft]
              : isOwnExpense
              ? [AppColors.warningSoft, AppColors.navySoft]
              : [AppColors.navySoft, AppColors.emeraldSoft],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.navy.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Productos en carrito',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              Text(
                '$count',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOwnExpense
                    ? 'Costo unitario promedio'
                    : 'Precio unitario promedio',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                formatMoney(count > 0 ? total / count : 0),
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isOwnExpense
                    ? 'Total gasto propio'
                    : isCredit
                    ? 'Total a deber'
                    : 'Total a Pagar',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                formatMoney(total),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          if (isOwnExpense) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Se descuenta de tu inversión',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '-${formatMoney(total)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
          if (isDollar) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Equivalente en USD',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '\$${usdTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ],
          if (commission > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comisión',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '-${formatMoney(commission)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Neto recibido',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  formatMoney(net),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          if (isOwnExpense)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'No genera ganancia',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'Gasto propio',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.warning,
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ganancia estimada',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '+${formatMoney(profit)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TransferAccountPicker extends StatelessWidget {
  final List<TransferAccount> accounts;
  final dynamic selectedKey;
  final ValueChanged<dynamic> onSelected;
  final VoidCallback onCreate;

  const _TransferAccountPicker({
    required this.accounts,
    required this.selectedKey,
    required this.onSelected,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.warning, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No tienes cuentas de transferencia guardadas.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onCreate,
              style: TextButton.styleFrom(foregroundColor: AppColors.navy),
              child: const Text('Agregar'),
            ),
          ],
        ),
      );
    }

    final selected = selectedKey == null
        ? null
        : accounts.firstWhere(
            (a) => a.key == selectedKey,
            orElse: () => accounts.first,
          );
    final effective = selected ?? accounts.first;
    final hasQr =
        effective.qrImagePath.isNotEmpty &&
        File(effective.qrImagePath).existsSync();

    return Container(
      padding: const EdgeInsets.all(14),
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
              Icon(
                Icons.account_balance_outlined,
                color: AppColors.navy,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cuenta para recibir el pago',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAccountSelector(context),
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('Cambiar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.navySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasQr
                    ? Image.file(File(effective.qrImagePath), fit: BoxFit.cover)
                    : Center(
                        child: Icon(
                          Icons.qr_code_2,
                          color: AppColors.navy,
                          size: 40,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      effective.alias,
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
                      effective.bankName,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      effective.cardNumber,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontFamily: 'monospace',
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showQrFull(context, effective),
                      icon: const Icon(Icons.fullscreen, size: 16),
                      label: const Text('Ver QR'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAccountSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Selecciona una cuenta',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: accounts.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: AppColors.border),
                  itemBuilder: (context, index) {
                    final acc = accounts[index];
                    return ListTile(
                      leading: Icon(
                        Icons.account_balance_outlined,
                        color: AppColors.navy,
                      ),
                      title: Text(
                        acc.alias,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '${acc.bankName} · ${acc.cardNumber}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: acc.isDefault
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.navy,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Principal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          : null,
                      onTap: () {
                        onSelected(acc.key);
                        Navigator.of(sheetContext).pop();
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    onCreate();
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Administrar cuentas'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQrFull(BuildContext context, TransferAccount account) {
    final hasQr =
        account.qrImagePath.isNotEmpty &&
        File(account.qrImagePath).existsSync();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                account.alias,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${account.bankName} · ${account.cardNumber}',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: AppColors.navySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasQr
                    ? Image.file(File(account.qrImagePath), fit: BoxFit.contain)
                    : Center(
                        child: Icon(
                          Icons.qr_code_2,
                          size: 96,
                          color: AppColors.navy,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
