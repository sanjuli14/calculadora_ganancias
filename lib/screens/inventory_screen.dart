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
                        .where(
                          (p) => p.name.toLowerCase().contains(_searchQuery),
                        )
                        .toList();
                  }

                  return _buildGroupedList(products, databaseService);
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

  // Agrupa los productos por categoría y los muestra en secciones.
  Widget _buildGroupedList(
    List<Product> products,
    DatabaseService databaseService,
  ) {
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
              child: Icon(
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
              style: TextStyle(
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
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Agrupar por categoría (orden alfabético). Los que no tienen categoría
    // van en una sección aparte al final.
    final Map<String, List<Product>> groups = {};
    for (final p in products) {
      final cat = p.category.trim();
      groups.putIfAbsent(cat, () => []).add(p);
    }
    final categoryNames = groups.keys.where((c) => c.isNotEmpty).toList()
      ..sort();
    final noCategory = groups[''] ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: [
        for (final cat in categoryNames) ...[
          _CategoryHeader(name: cat, count: groups[cat]!.length),
          for (final product in groups[cat]!)
            _buildProductCard(product, databaseService),
        ],
        if (noCategory.isNotEmpty) ...[
          const _CategoryHeader(name: 'Sin categoría', count: null),
          for (final product in noCategory)
            _buildProductCard(product, databaseService),
        ],
      ],
    );
  }

  Widget _buildProductCard(Product product, DatabaseService databaseService) {
    return ProductCard(
      product: product,
      onEdit: () =>
          _showProductDialog(context, databaseService, product: product),
      onDelete: () => _confirmDelete(context, databaseService, product),
    );
  }

  void _confirmDelete(
    BuildContext context,
    DatabaseService db,
    Product product,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${product.name}"?',
        ),
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
            child: Text('Eliminar', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showProductDialog(
    BuildContext context,
    DatabaseService db, {
    Product? product,
  }) {
    final nameController = TextEditingController(text: product?.name ?? '');
    final buyPriceController = TextEditingController(
      text: product?.buyPrice.toString() ?? '',
    );
    final sellPriceController = TextEditingController(
      text: product?.sellPrice.toString() ?? '',
    );
    final stockController = TextEditingController(
      text: product?.stock.toString() ?? '0',
    );
    final categories = db.getCategories();
    final currentCategory = product?.category ?? '';
    String selectedCategory = categories.contains(currentCategory)
        ? currentCategory
        : '';
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
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        setState(() {
                          currentImagePath = image.path;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.navySoft,
                      backgroundImage:
                          currentImagePath != null &&
                              File(currentImagePath!).existsSync()
                          ? FileImage(File(currentImagePath!))
                          : null,
                      child: currentImagePath == null
                          ? Icon(
                              Icons.add_a_photo,
                              size: 30,
                              color: AppColors.navy,
                            )
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
                      child: Text(
                        'Eliminar Imagen',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Producto',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: buyPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio de Compra',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: sellPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Precio de Venta',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: stockController,
                    decoration: const InputDecoration(
                      labelText: 'Stock Inicial',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
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
                          onChanged: (value) {
                            setState(() => selectedCategory = value ?? '');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: IconButton.filled(
                          onPressed: () async {
                            final controller = TextEditingController();
                            final newCategory = await showDialog<String>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Nueva categoría'),
                                content: TextField(
                                  controller: controller,
                                  autofocus: true,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre',
                                    hintText: 'Ej: Refrescos, Abarrotes...',
                                  ),
                                  onSubmitted: (value) =>
                                      Navigator.pop(dialogContext, value),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(
                                      dialogContext,
                                      controller.text,
                                    ),
                                    child: const Text('Crear'),
                                  ),
                                ],
                              ),
                            );
                            final name = newCategory?.trim();
                            if (name != null && name.isNotEmpty) {
                              await db.addCategory(name);
                              setState(() => selectedCategory = name);
                            }
                          },
                          icon: const Icon(Icons.add, size: 20),
                          tooltip: 'Crear categoría',
                        ),
                      ),
                    ],
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
                  final buyPrice =
                      double.tryParse(buyPriceController.text) ?? 0.0;
                  final sellPrice =
                      double.tryParse(sellPriceController.text) ?? 0.0;
                  final stock = int.tryParse(stockController.text) ?? 0;
                  final category = selectedCategory.trim();

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
                      category: category,
                    );
                    db.addProduct(newProduct);
                  } else {
                    product.name = name;
                    product.buyPrice = buyPrice;
                    product.sellPrice = sellPrice;
                    product.stock = stock;
                    product.imagePath = currentImagePath;
                    product.category = category;
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

class _CategoryHeader extends StatelessWidget {
  final String name;
  final int? count;

  const _CategoryHeader({required this.name, this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.navySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.category_outlined,
              size: 18,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
