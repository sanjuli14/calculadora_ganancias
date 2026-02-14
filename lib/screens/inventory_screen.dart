import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/product.dart';
import '../services/database_service.dart';
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
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Buscar producto...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.white),
            filled: false,
          ),
          cursorColor: Colors.white,
        ),
      ),
      body: ValueListenableBuilder<Box<Product>>(
        valueListenable: databaseService.productsListenable,
        builder: (context, box, _) {
          var products = box.values.toList().cast<Product>();

          if (_searchQuery.isNotEmpty) {
            products = products.where((p) => p.name.toLowerCase().contains(_searchQuery)).toList();
          }

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
                   const SizedBox(height: 16),
                   Text(
                    _searchQuery.isNotEmpty 
                        ? 'No se encontraron productos'
                        : 'Tu inventario está vacío',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Usa el botón + para agregar uno nuevo',
                     style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Space for FAB
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
        content: Text('¿Estás seguro de que quieres eliminar "CUP ${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              // We need to find the key to delete
              await product.delete(); 
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
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
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: currentImagePath != null && File(currentImagePath!).existsSync()
                          ? FileImage(File(currentImagePath!))
                          : null,
                      child: currentImagePath == null
                          ? const Icon(Icons.add_a_photo, size: 30, color: Colors.grey)
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
                      child: const Text('Eliminar Imagen', style: TextStyle(color: Colors.red)),
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
                    // Add new
                    final newProduct = Product(
                      name: name,
                      buyPrice: buyPrice,
                      sellPrice: sellPrice,
                      stock: stock,
                      imagePath: currentImagePath,
                    );
                    db.addProduct(newProduct);
                  } else {
                    // Edit existing
                    product.name = name;
                    product.buyPrice = buyPrice;
                    product.sellPrice = sellPrice;
                    product.stock = stock;
                    product.imagePath = currentImagePath;
                    product.save(); // HiveObject method
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
