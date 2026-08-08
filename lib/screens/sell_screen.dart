import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../utils/payment_methods.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  Product? _selectedProduct;
  final _quantityController = TextEditingController(text: '1');
  final _customerController = TextEditingController();
  final _commissionController = TextEditingController();
  final _exchangeRateController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _paymentMethod = PaymentMethod.cash;
  bool _applyCommission = false;

  @override
  void dispose() {
    _quantityController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Registrar Venta',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Selecciona producto, cantidad y forma de pago',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
                        child: const Column(
                          children: [
                            Icon(Icons.shopping_bag_outlined, color: AppColors.textSecondary, size: 40),
                            SizedBox(height: 8),
                            Text(
                              'No hay productos disponibles',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Agrega inventario primero',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }

                    return DropdownButtonFormField<Product>(
                      value: _selectedProduct,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar Producto',
                        prefixIcon: Icon(Icons.shopping_bag_outlined),
                      ),
                      items: products.map((product) {
                        return DropdownMenuItem(
                          value: product,
                          child: Text('${product.name} (Stock: ${product.stock})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProduct = value;
                          _quantityController.text = '1';
                        });
                      },
                      validator: (value) => value == null ? 'Seleccione un producto' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingrese cantidad';
                    final qty = int.tryParse(value);
                    if (qty == null || qty <= 0) return 'Cantidad inválida';
                    if (_selectedProduct != null && qty > _selectedProduct!.stock) {
                      return 'Stock insuficiente (Max: ${_selectedProduct!.stock})';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _MethodSelector(
                  selected: _paymentMethod,
                  onChanged: (m) => setState(() => _paymentMethod = m),
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
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.navySoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.percent, color: AppColors.navy, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
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
                          onChanged: (v) => setState(() => _applyCommission = v),
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
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final v = double.tryParse(value ?? '');
                        if (value == null || value.isEmpty || v == null || v < 0) {
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final v = double.tryParse(value ?? '');
                      if (value == null || value.isEmpty || v == null || v <= 0) {
                        return 'Ingresa el tipo de cambio';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 20),
                if (_selectedProduct != null) ...[
                  _SaleSummaryCard(
                    product: _selectedProduct!,
                    quantityController: _quantityController,
                    paymentMethod: _paymentMethod,
                    commission: _commission,
                    exchangeRate: _exchangeRate,
                  ),
                  const SizedBox(height: 20),
                ],
                ElevatedButton.icon(
                  onPressed: () => _processSale(databaseService),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _paymentMethod == PaymentMethod.credit ? AppColors.turquoise : AppColors.emerald,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(_paymentMethod == PaymentMethod.credit ? Icons.handshake_outlined : Icons.check_circle_outline),
                  label: Text(
                    _paymentMethod == PaymentMethod.credit ? 'REGISTRAR FIADO' : 'CONFIRMAR VENTA',
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
    if (!_formKey.currentState!.validate() || _selectedProduct == null) return;
    final quantity = int.parse(_quantityController.text);
    final product = _selectedProduct!;

    if (_paymentMethod == PaymentMethod.credit) {
      final customer = _customerController.text.trim();
      await db.registerCreditSale(
        product,
        quantity,
        customer,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Venta a crédito registrada (fiado)')),
      );
      _resetForm();
      return;
    }

    final sale = Sale(
      productName: product.name,
      unitBuyPrice: product.buyPrice,
      unitSellPrice: product.sellPrice,
      quantity: quantity,
      date: DateTime.now(),
      paymentMethod: _paymentMethod,
      commissionAmount: _commission > 0 ? _commission : null,
      exchangeRate: _exchangeRate,
    );

    product.stock -= quantity;
    await product.save();
    await db.addSale(sale);

    if (!mounted) return;
    final parts = <String>[PaymentMethod.label(_paymentMethod)];
    if (_paymentMethod == PaymentMethod.transfer && _commission > 0) {
      parts.add('comisión ${formatMoney(_commission)}');
    }
    if (_paymentMethod == PaymentMethod.dollar && _exchangeRate != null) {
      parts.add('cambio ${formatMoney(_exchangeRate!)}');
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Venta registrada (${parts.join(', ')})')),
    );
    _resetForm();
  }

  void _resetForm() {
    _quantityController.text = '1';
    _customerController.clear();
    _commissionController.clear();
    _exchangeRateController.clear();
    _noteController.clear();
    setState(() {
      _selectedProduct = null;
      _paymentMethod = PaymentMethod.cash;
      _applyCommission = false;
    });
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
        const Text(
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
              Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.navy),
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
  final Product product;
  final TextEditingController quantityController;
  final String paymentMethod;
  final double commission;
  final double? exchangeRate;

  const _SaleSummaryCard({
    required this.product,
    required this.quantityController,
    required this.paymentMethod,
    required this.commission,
    this.exchangeRate,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: quantityController,
      builder: (context, value, _) {
        final qty = int.tryParse(quantityController.text) ?? 0;
        final total = qty * product.sellPrice;
        final profit = qty * (product.sellPrice - product.buyPrice);
        final net = total - commission;
        final isCredit = paymentMethod == PaymentMethod.credit;
        final isDollar = paymentMethod == PaymentMethod.dollar && exchangeRate != null && exchangeRate! > 0;
        final usdTotal = isDollar ? total / exchangeRate! : 0.0;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isCredit
                  ? [AppColors.turquoiseSoft, AppColors.navySoft]
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
                  const Text('Precio unitario', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text(
                    formatMoney(product.sellPrice),
                    style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isCredit ? 'Total a deber' : 'Total a Pagar',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  Text(
                    formatMoney(total),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy),
                  ),
                ],
              ),
              if (isDollar) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Equivalente en USD', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(
                      '\$${usdTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.navy),
                    ),
                  ],
                ),
              ],
              if (commission > 0) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Comisión', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(
                      '-${formatMoney(commission)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.danger),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Neto recibido', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(
                      formatMoney(net),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.emerald),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ganancia estimada',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  Text(
                    '+${formatMoney(profit)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.emerald),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
