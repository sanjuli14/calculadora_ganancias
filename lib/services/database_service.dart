import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../models/product.dart';
import '../models/sale.dart';

class DatabaseService {
  late Box<Product> _productsBox;
  late Box<Sale> _salesBox;

  Box<Product> get productsBox => _productsBox;
  Box<Sale> get salesBox => _salesBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(SaleAdapter());

    _productsBox = await Hive.openBox<Product>('products');
    _salesBox = await Hive.openBox<Sale>('sales');
  }

  // ValueListenable for UI updates
  ValueListenable<Box<Product>> get productsListenable => _productsBox.listenable();
  ValueListenable<Box<Sale>> get salesListenable => _salesBox.listenable();

  // Product CRUD
  Future<void> addProduct(Product product) async {
    await _productsBox.add(product);
  }

  Future<void> updateProduct(int index, Product product) async {
    await _productsBox.putAt(index, product);
  }

  Future<void> deleteProduct(int index) async {
    await _productsBox.deleteAt(index);
  }

  // Sale CRUD
  Future<void> addSale(Sale sale) async {
    await _salesBox.add(sale);
  }

  Future<void> deleteSale(dynamic key) async {
    final sale = _salesBox.get(key);
    if (sale != null) {
      // Find the product and restore stock
      for (var product in _productsBox.values) {
        if (product.name == sale.productName) {
          product.stock += sale.quantity;
          await product.save();
          break;
        }
      }
    }
    await _salesBox.delete(key);
  }

  // Get sales between dates
  List<Sale> getSalesBetween(DateTime start, DateTime end) {
    return _salesBox.values.where((sale) {
      return sale.date.isAfter(start.subtract(const Duration(days: 1))) &&
             sale.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // Get weekly sales (from previous inventory day to current inventory day)
  List<Sale> getWeeklySalesCustom(int inventoryDay) {
    final now = DateTime.now();
    // Find the most recent inventory day
    int daysSinceInventory = (now.weekday - inventoryDay) % 7;
    if (daysSinceInventory < 0) daysSinceInventory += 7;
    final currentInventory = now.subtract(Duration(days: daysSinceInventory));
    final previousInventory = currentInventory.subtract(const Duration(days: 7));
    return getSalesBetween(previousInventory, currentInventory);
  }

  // Get monthly sales (current month)
  List<Sale> getMonthlySales() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return getSalesBetween(startOfMonth, endOfMonth);
  }

  // Calculate summary from sales list
  Map<String, double> calculateSummary(List<Sale> sales) {
    double totalSales = 0;
    double totalProfit = 0;
    for (var sale in sales) {
      totalSales += sale.total;
      totalProfit += sale.profit;
    }
    return {
      'totalSales': totalSales,
      'totalProfit': totalProfit,
    };
  }

  // Backup logic
  Future<void> exportData() async {
    final Map<String, dynamic> backup = {
      'products': _productsBox.values.map((p) => p.toJson()).toList(),
      'sales': _salesBox.values.map((s) => s.toJson()).toList(),
      'date': DateTime.now().toIso8601String(),
    };

    final jsonString = jsonEncode(backup);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/backup_ganancias_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)], text: 'Copia de seguridad - Calculadora de Ganancias');
  }

  Future<void> importData() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> backup = jsonDecode(jsonString);

      // Clear existing data? Or append? User probably expects restore to overwrite or fill.
      // Let's clear for a clean restore to avoid duplicates if IDs aren't managed.
      // But HiveObjects don't have stable IDs unless we set them.
      // Safest is to clear and re-populate.
      
      await _productsBox.clear();
      await _salesBox.clear();

      if (backup['products'] != null) {
        final products = (backup['products'] as List).map((i) => Product.fromJson(i)).toList();
        await _productsBox.addAll(products);
      }

      if (backup['sales'] != null) {
        final sales = (backup['sales'] as List).map((i) => Sale.fromJson(i)).toList();
        await _salesBox.addAll(sales);
      }
    }
  }
}

