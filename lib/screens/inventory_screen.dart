import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/product.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/product_card.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar producto...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<Box<Product>>(
                valueListenable: databaseService.productsListenable,
                builder: (context, box, _) {
                  var products = box.values.toList().cast<Product>();

                  if (_searchQuery.isNotEmpty) {
                    products = products
                        .where((p) => p.name.toLowerCase().contains(_searchQuery))
                        .toList();
                  }

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: AppColors.navySoft,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              size: 44,
                              color: AppColors.navy,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No se encontraron productos'
                                : 'Tu inventario está vacío',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Intenta con otro término'
                                : 'Usa el botón + para agregar uno nuevo',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        onEdit: () => _showProductDialog(context, databaseService, product: product),
                        onDelete: () => _confirmDelete(context, databaseService, product),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductDialog(context, databaseService),
        label: const Text('Nuevo Producto'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, DatabaseService db, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de que quieres eliminar "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await product.delete();
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(BuildContext context, DatabaseService db, {Product? product}) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final buyPriceController = TextEditingController(text: product?.buyPrice.toString() ?? '');
    final sellPriceController = TextEditingController(text: product?.sellPrice.toString() ?? '');
    final stockController = TextEditingController(text: product?.stock.toString() ?? '0');
    String? currentImagePath = product?.imagePath;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(product == null ? 'Nuevo Producto' : 'Editar Producto'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setState(() {
                          currentImagePath = image.path;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.navySoft,
                      backgroundImage: currentImagePath != null && File(currentImagePath!).existsSync()
                          ? FileImage(File(currentImagePath!))
                          : null,
                      child: currentImagePath == null
                          ? const Icon(Icons.add_a_photo, size: 30, color: AppColors.navy)
                          : null,
                    ),
                  ),
                  if (currentImagePath != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          currentImagePath = null;
                        });
                      },
                      child: const Text('Eliminar Imagen', style: TextStyle(color: AppColors.danger)),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre del Producto'),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: buyPriceController,
                    decoration: const InputDecoration(labelText: 'Precio de Compra'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: sellPriceController,
                    decoration: const InputDecoration(labelText: 'Precio de Venta'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: stockController,
                    decoration: const InputDecoration(labelText: 'Stock Inicial'),
                    keyboardType: TextInputType.number,
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
                onPressed: () {
                  final name = nameController.text.trim();
                  final buyPrice = double.tryParse(buyPriceController.text) ?? 0.0;
                  final sellPrice = double.tryParse(sellPriceController.text) ?? 0.0;
                  final stock = int.tryParse(stockController.text) ?? 0;

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('El nombre es obligatorio')),
                    );
                    return;
                  }

                  if (product == null) {
                    final newProduct = Product(
                      name: name,
                      buyPrice: buyPrice,
                      sellPrice: sellPrice,
                      stock: stock,
                      imagePath: currentImagePath,
                    );
                    db.addProduct(newProduct);
                  } else {
                    product.name = name;
                    product.buyPrice = buyPrice;
                    product.sellPrice = sellPrice;
                    product.stock = stock;
                    product.imagePath = currentImagePath;
                    product.save();
                  }
                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );
  }
}
