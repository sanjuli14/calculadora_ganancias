import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/cashbox.dart';
import '../models/debt.dart';
import '../models/payment.dart';

class DatabaseService {
  // Versión del esquema de la base de datos.
  // Aumenta este número cuando agregues/cambies campos de un modelo y deja
  // la lógica de migración en _migrate(). Así las actualizaciones nunca
  // pierden los datos del usuario.
  static const int _schemaVersion = 1;

  late Box<Product> _productsBox;
  late Box<Sale> _salesBox;
  late Box<CashCount> _cashboxBox;
  late Box<Debt> _debtsBox;
  late Box _metaBox;
  Timer? _backupDebounce;

  Box<Product> get productsBox => _productsBox;
  Box<Sale> get salesBox => _salesBox;
  Box<CashCount> get cashboxBox => _cashboxBox;
  Box<Debt> get debtsBox => _debtsBox;

  bool get onboardingSeen => _metaBox.get('onboarding_seen', defaultValue: false) as bool;

  Future<void> markOnboardingSeen() async {
    await _metaBox.put('onboarding_seen', true);
  }

  Future<void> init() async {    await Hive.initFlutter();
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(SaleAdapter());
    Hive.registerAdapter(CashCountAdapter());
    Hive.registerAdapter(DebtAdapter());
    Hive.registerAdapter(PaymentAdapter());

    // Abre la box de metadatos (versión de esquema) de forma segura.
    try {
      _metaBox = await Hive.openBox('meta');
    } catch (_) {
      await Hive.deleteBoxFromDisk('meta');
      _metaBox = await Hive.openBox('meta');
    }

    // Apertura defensiva: si una box se corrompe (cierre forzoso, cambio
    // radical), se borra y se vuelve a crear en lugar de crashear la app.
    _productsBox = await _openBoxSafely<Product>('products');
    _salesBox = await _openBoxSafely<Sale>('sales');
    _cashboxBox = await _openBoxSafely<CashCount>('cashbox');
    _debtsBox = await _openBoxSafely<Debt>('debts');

    await _migrate();
  }

  Future<Box<T>> _openBoxSafely<T>(String boxName) async {
    try {
      return await Hive.openBox<T>(boxName);
    } catch (e) {
      // Box corrupta: la recreamos para que la app siga funcionando.
      // El usuario puede recuperar sus datos con la copia de seguridad.
      await Hive.deleteBoxFromDisk(boxName);
      return await Hive.openBox<T>(boxName);
    }
  }

  Future<void> _migrate() async {
    final current = _metaBox.get('db_version', defaultValue: 1) as int;
    if (current >= _schemaVersion) return;

    // === Migraciones por versión ===
    // Ejemplo de migración (descomenta y adapta cuando agregues campos):
    //
    // if (current < 2) {
    //   for (var product in _productsBox.values) {
    //     product.imagePath = product.imagePath; // asigna el valor por defecto
    //     await product.save();
    //   }
    // }
    //
    // if (current < 3) {
    //   // nueva lógica aquí
    // }

    await _metaBox.put('db_version', _schemaVersion);
  }

  // ValueListenable for UI updates
  ValueListenable<Box<Product>> get productsListenable => _productsBox.listenable();
  ValueListenable<Box<Sale>> get salesListenable => _salesBox.listenable();
  ValueListenable<Box<CashCount>> get cashboxListenable => _cashboxBox.listenable();
  ValueListenable<Box<Debt>> get debtsListenable => _debtsBox.listenable();

  // Product CRUD
  Future<void> addProduct(Product product) async {
    await _productsBox.add(product);
    _scheduleAutoBackup();
  }

  Future<void> updateProduct(int index, Product product) async {
    await _productsBox.putAt(index, product);
    _scheduleAutoBackup();
  }

  Future<void> deleteProduct(int index) async {
    await _productsBox.deleteAt(index);
    _scheduleAutoBackup();
  }

  // Sale CRUD
  Future<void> addSale(Sale sale) async {
    await _salesBox.add(sale);
    _scheduleAutoBackup();
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
    _scheduleAutoBackup();
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
    _scheduleAutoBackup();
  }

  Future<void> deleteCashCount(dynamic key) async {
    await _cashboxBox.delete(key);
    _scheduleAutoBackup();
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
    _scheduleAutoBackup();
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
    _scheduleAutoBackup();
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
    _scheduleAutoBackup();
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

  // Programa un auto-backup en la carpeta Descargas.
  // Se agrupan los cambios rápidos en un solo archivo (debounce de 1.5s).
  void _scheduleAutoBackup() {
    _backupDebounce?.cancel();
    _backupDebounce = Timer(const Duration(milliseconds: 1500), _saveAutoBackup);
  }

  // Genera el JSON de respaldo y lo guarda en la carpeta Descargas con nombre y fecha.
  Future<void> _saveAutoBackup() async {
    try {
      final Map<String, dynamic> backup = {
        'products': _productsBox.values.map((p) => p.toJson()).toList(),
        'sales': _salesBox.values.map((s) => s.toJson()).toList(),
        'cashbox': _cashboxBox.values.map((c) => c.toJson()).toList(),
        'debts': _debtsBox.values.map((d) => d.toJson()).toList(),
        'date': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(backup);
      final directory = await getTemporaryDirectory();
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final fileName = 'cuentas_claras_${now.year}-${two(now.month)}-${two(now.day)}_${two(now.hour)}-${two(now.minute)}.json';

      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      await MediaStore().saveFile(
        tempFilePath: file.path,
        dirType: DirType.download,
        dirName: DirName.download,
      );
    } catch (e) {
      debugPrint('Auto-backup falló: $e');
    }
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
        _scheduleAutoBackup();
      } else {
        throw const FormatException('El archivo no es una copia de Cuentas Claras válida');
      }
    }
  }
}

