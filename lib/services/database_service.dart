import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/cashbox.dart';
import '../models/debt.dart';
import '../models/payment.dart';

class DatabaseService {
  late Box<Product> _productsBox;
  late Box<Sale> _salesBox;
  late Box<CashCount> _cashboxBox;
  late Box<Debt> _debtsBox;

  Box<Product> get productsBox => _productsBox;
  Box<Sale> get salesBox => _salesBox;
  Box<CashCount> get cashboxBox => _cashboxBox;
  Box<Debt> get debtsBox => _debtsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(SaleAdapter());
    Hive.registerAdapter(CashCountAdapter());
    Hive.registerAdapter(DebtAdapter());
    Hive.registerAdapter(PaymentAdapter());

    _productsBox = await Hive.openBox<Product>('products');
    _salesBox = await Hive.openBox<Sale>('sales');
    _cashboxBox = await Hive.openBox<CashCount>('cashbox');
    _debtsBox = await Hive.openBox<Debt>('debts');
  }

  // ValueListenable for UI updates
  ValueListenable<Box<Product>> get productsListenable => _productsBox.listenable();
  ValueListenable<Box<Sale>> get salesListenable => _salesBox.listenable();
  ValueListenable<Box<CashCount>> get cashboxListenable => _cashboxBox.listenable();
  ValueListenable<Box<Debt>> get debtsListenable => _debtsBox.listenable();

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

  // ---- Totales financieros ----

  // Dinero invertido en el inventario actual (costo x stock)
  double getInvestedCapital() {
    double total = 0;
    for (var product in _productsBox.values) {
      total += product.buyPrice * product.stock;
    }
    return total;
  }

  // Valor del inventario a precio de venta
  double getInventoryValue() {
    double total = 0;
    for (var product in _productsBox.values) {
      total += product.sellPrice * product.stock;
    }
    return total;
  }

  // Inversión histórica total (todo lo comprado hasta ahora)
  double getTotalInvestment() {
    double total = getInvestedCapital();
    for (var sale in _salesBox.values) {
      total += sale.unitBuyPrice * sale.quantity;
    }
    return total;
  }

  // Productos con stock bajo (para alertas)
  List<Product> getLowStockProducts({int threshold = 5}) {
    return _productsBox.values.where((p) => p.stock <= threshold).toList();
  }

  int getLowStockCount({int threshold = 5}) => getLowStockProducts(threshold: threshold).length;

  // ---- Caja contable ----

  Future<void> addCashCount(CashCount count) async {
    await _cashboxBox.add(count);
  }

  Future<void> deleteCashCount(dynamic key) async {
    await _cashboxBox.delete(key);
  }

  List<CashCount> getCashCounts() {
    return _cashboxBox.values.toList().cast<CashCount>();
  }

  // ---- Cuentas por cobrar (fiados) ----

  Future<void> registerCreditSale(
    Product product,
    int quantity,
    String customerName, {
    String? note,
  }) async {
    product.stock -= quantity;
    await product.save();

    final debt = Debt(
      customerName: customerName,
      productName: product.name,
      unitPrice: product.sellPrice,
      quantity: quantity,
      unitCost: product.buyPrice,
      date: DateTime.now(),
      note: note,
    );
    await _debtsBox.add(debt);
  }

  Future<void> addDebtPayment(
    dynamic debtKey,
    double amount,
    String method, {
    double? commissionAmount,
  }) async {
    final debt = _debtsBox.get(debtKey);
    if (debt == null) return;
    debt.payments.add(Payment(
      amount: amount,
      date: DateTime.now(),
      method: method,
      commissionAmount: commissionAmount,
    ));
    await debt.save();
  }

  Future<void> deleteDebt(dynamic key) async {
    final debt = _debtsBox.get(key);
    if (debt != null) {
      // Restaurar stock del producto fiado
      for (var product in _productsBox.values) {
        if (product.name == debt.productName) {
          product.stock += debt.quantity;
          await product.save();
          break;
        }
      }
    }
    await _debtsBox.delete(key);
  }

  List<Debt> getDebts() {
    return _debtsBox.values.toList().cast<Debt>();
  }

  double getTotalOutstanding() {
    double total = 0;
    for (var debt in _debtsBox.values) {
      total += debt.balance;
    }
    return total;
  }

  double getTotalCreditSold() {
    double total = 0;
    for (var debt in _debtsBox.values) {
      total += debt.total;
    }
    return total;
  }

  double getTotalCreditCollected() {
    double total = 0;
    for (var debt in _debtsBox.values) {
      total += debt.paid;
    }
    return total;
  }

  List<Debt> getActiveDebts() {
    return _debtsBox.values.where((d) => !d.isPaid).toList();
  }

  List<Debt> getPaidDebts() {
    return _debtsBox.values.where((d) => d.isPaid).toList();
  }

  // Backup logic
  Future<void> exportData() async {
    final Map<String, dynamic> backup = {
      'products': _productsBox.values.map((p) => p.toJson()).toList(),
      'sales': _salesBox.values.map((s) => s.toJson()).toList(),
      'cashbox': _cashboxBox.values.map((c) => c.toJson()).toList(),
      'debts': _debtsBox.values.map((d) => d.toJson()).toList(),
      'date': DateTime.now().toIso8601String(),
    };

    final jsonString = jsonEncode(backup);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/backup_ganancias_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)], text: 'Copia de seguridad - Cuentas Claras');
  }

  Future<void> importData() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> backup = jsonDecode(jsonString);

      if (backup['products'] != null &&
          backup['sales'] != null &&
          backup['cashbox'] != null &&
          backup['debts'] != null) {
        // Clear all boxes for a clean restore and avoid duplicates
        await _productsBox.clear();
        await _salesBox.clear();
        await _cashboxBox.clear();
        await _debtsBox.clear();

        final products = (backup['products'] as List)
            .map((i) => Product.fromJson(i))
            .toList();
        final sales = (backup['sales'] as List)
            .map((i) => Sale.fromJson(i))
            .toList();
        final counts = (backup['cashbox'] as List)
            .map((i) => CashCount.fromJson(i))
            .toList();
        final debts = (backup['debts'] as List)
            .map((i) => Debt.fromJson(i))
            .toList();

        await _productsBox.addAll(products);
        await _salesBox.addAll(sales);
        await _cashboxBox.addAll(counts);
        await _debtsBox.addAll(debts);
      } else {
        throw const FormatException('El archivo no es una copia de Cuentas Claras válida');
      }
    }
  }
}

