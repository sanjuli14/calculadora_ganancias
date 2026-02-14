import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../services/database_service.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  Product? _selectedProduct;
  final _quantityController = TextEditingController(text: '1');
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Registrar Venta',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ValueListenableBuilder<Box<Product>>(
                  valueListenable: databaseService.productsListenable,
                  builder: (context, box, _) {
                    final products = box.values.toList().cast<Product>();
                    
                    if (products.isEmpty) {
                       return const Center(child: Text('No hay productos disponibles. Agrega inventario primero.'));
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
                        });
                      },
                      validator: (value) => value == null ? 'Seleccione un producto' : null,
                    );
                  },
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 32),
                if (_selectedProduct != null) ...[
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column( 
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Precio Unitario'),
                              Text('CUP ${_selectedProduct!.sellPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(),
                           ValueListenableBuilder(
                             valueListenable: _quantityController, 
                             builder: (context, value, _) {
                               final qty = int.tryParse(_quantityController.text) ?? 0;
                               final total = qty * _selectedProduct!.sellPrice;
                               final profit = qty * (_selectedProduct!.sellPrice - _selectedProduct!.buyPrice);
                               return Column(
                                 children: [
                                   Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       const Text('Total a Pagar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                       Text(
                                         'CUP ${total.toStringAsFixed(2)}',
                                         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                                       ),
                                     ],
                                   ),
                                   const SizedBox(height: 8),
                                    Row(
                                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                     children: [
                                       const Text('Ganancia estimada', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                       Text(
                                         '+CUP ${profit.toStringAsFixed(2)}',
                                         style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                                       ),
                                     ],
                                   ),
                                 ],
                               );
                             }
                           )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                ElevatedButton.icon(
                  onPressed: () => _processSale(databaseService),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('CONFIRMAR VENTA'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _processSale(DatabaseService db) async {
    if (_formKey.currentState!.validate() && _selectedProduct != null) {
      final quantity = int.parse(_quantityController.text);
      final product = _selectedProduct!;

      final sale = Sale(
        productName: product.name,
        unitBuyPrice: product.buyPrice,
        unitSellPrice: product.sellPrice,
        quantity: quantity,
        date: DateTime.now(),
      );

      // Decrement stock
      product.stock -= quantity;
      await product.save();

      // Save sale
      await db.addSale(sale);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta registrada con éxito')),
        );
        // Reset form
        _quantityController.text = '1';
        setState(() {
          _selectedProduct = null;
        });
      }
    }
  }
}
