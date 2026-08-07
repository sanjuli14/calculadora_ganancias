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
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _paymentMethod = PaymentMethod.cash;
  bool _applyCommission = false;

  @override
  void dispose() {
    _quantityController.dispose();
    _customerController.dispose();
    _commissionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _commission {
    if (_paymentMethod != PaymentMethod.transfer || !_applyCommission) return 0;
    return double.tryParse(_commissionController.text) ?? 0;
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
                ],
                const SizedBox(height: 20),
                if (_selectedProduct != null) ...[
                  _SaleSummaryCard(
                    product: _selectedProduct!,
                    quantityController: _quantityController,
                    paymentMethod: _paymentMethod,
                    commission: _commission,
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
    );

    product.stock -= quantity;
    await product.save();
    await db.addSale(sale);

    if (!mounted) return;
    final msg = _paymentMethod == PaymentMethod.transfer && _commission > 0
        ? 'Venta registrada (${PaymentMethod.label(_paymentMethod)}, comisión ${formatMoney(_commission)})'
        : 'Venta registrada (${PaymentMethod.label(_paymentMethod)})';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    _resetForm();
  }

  void _resetForm() {
    _quantityController.text = '1';
    _customerController.clear();
    _commissionController.clear();
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
        const SizedBox(height: 8),
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
            ButtonSegment(
              value: PaymentMethod.credit,
              icon: Icon(Icons.handshake_outlined),
              label: Text('Fiado'),
            ),
          ],
          selected: {selected},
          showSelectedIcon: false,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.navy
                  : AppColors.surface,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : AppColors.textSecondary,
            ),
            side: WidgetStateProperty.all(const BorderSide(color: AppColors.border)),
          ),
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ],
    );
  }
}

class _SaleSummaryCard extends StatelessWidget {
  final Product product;
  final TextEditingController quantityController;
  final String paymentMethod;
  final double commission;

  const _SaleSummaryCard({
    required this.product,
    required this.quantityController,
    required this.paymentMethod,
    required this.commission,
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
