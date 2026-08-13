import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'dart:convert';
import 'dart:io';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/cashbox.dart';
import '../models/debt.dart';
import '../models/payment.dart';
import '../models/transfer_account.dart';
import '../models/expense.dart';

class DatabaseService {
  // Versión del esquema de la base de datos.
  // Aumenta este número cuando agregues/cambies campos de un modelo y deja
  // la lógica de migración en _migrate(). Así las actualizaciones nunca
  // pierden los datos del usuario.
  static const int _schemaVersion = 3;

  late Box<Product> _productsBox;
  late Box<Sale> _salesBox;
  late Box<CashCount> _cashboxBox;
  late Box<Debt> _debtsBox;
  late Box<TransferAccount> _transferAccountsBox;
  late Box<String> _categoriesBox;
  late Box<Expense> _expensesBox;
  late Box _metaBox;

  Box<Product> get productsBox => _productsBox;
  Box<Sale> get salesBox => _salesBox;
  Box<CashCount> get cashboxBox => _cashboxBox;
  Box<Debt> get debtsBox => _debtsBox;
  Box<TransferAccount> get transferAccountsBox => _transferAccountsBox;
  Box<String> get categoriesBox => _categoriesBox;
  Box<Expense> get expensesBox => _expensesBox;

  bool get onboardingSeen => _metaBox.get('onboarding_seen', defaultValue: false) as bool;

  Future<void> markOnboardingSeen() async {
    await _metaBox.put('onboarding_seen', true);
  }

  // ValorListenable de la box de metadatos para refrescar la UI cuando
  // cambian campos como la inversión total.
  ValueListenable<Box> get metaListenable => _metaBox.listenable();

  // Total de la inversión que se hizo (campo manual, configurable por el usuario).
  double get totalInvestment =>
      (_metaBox.get('total_investment', defaultValue: 0.0) as num).toDouble();

  Future<void> setTotalInvestment(double value) async {
    await _metaBox.put('total_investment', value);
  }

  // Lista de copias automáticas guardadas en el teléfono (nombre + uri).
  // Se guardan las URIs para poder restaurar desde la app sin abrir el
  // selector de archivos (que reiniciaba la app y pedía login de nuevo).
  static const String _savedBackupsKey = 'saved_backups';

  List<Map<String, String>> get savedBackups {
    final raw = _metaBox.get(_savedBackupsKey);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw as String) as List)
          .map((e) => (e as Map).cast<String, String>())
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _recordSavedBackup(String name, String uri) async {
    final backups = List<Map<String, String>>.from(savedBackups);
    backups.insert(0, {'name': name, 'uri': uri});
    // Se conservan solo las 20 más recientes para no acumular.
    if (backups.length > 20) {
      backups.removeRange(20, backups.length);
    }
    await _metaBox.put(_savedBackupsKey, jsonEncode(backups));
  }

  // Lee el contenido de una copia guardada por su URI (sin salir de la app).
  Future<String> _readBackupByUri(String uriString) async {
    final dir = await getTemporaryDirectory();
    final tempFile = File('${dir.path}/backup_restore_${DateTime.now().millisecondsSinceEpoch}.json');
    final ok = await MediaStore()
        .readFileUsingUri(uriString: uriString, tempFilePath: tempFile.path);
    if (!ok || !await tempFile.exists()) {
      throw const FormatException('No se pudo leer la copia desde el teléfono');
    }
    return await tempFile.readAsString();
  }

  Future<void> init() async {    await Hive.initFlutter();
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(SaleAdapter());
    Hive.registerAdapter(CashCountAdapter());
    Hive.registerAdapter(DebtAdapter());
    Hive.registerAdapter(PaymentAdapter());
    Hive.registerAdapter(TransferAccountAdapter());
    Hive.registerAdapter(ExpenseAdapter());

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
    _transferAccountsBox = await _openBoxSafely<TransferAccount>('transfer_accounts');
    _categoriesBox = await _openBoxSafely<String>('categories');
    _expensesBox = await _openBoxSafely<Expense>('expenses');

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
    // v2: se agregó la box de cuentas para pago por transferencia.
    // La box se abre en init(), por lo que en esta versión no hay
    // datos existentes que migrar; solo se actualiza el número de esquema.
    //
    // v3: se agregó la box de gastos (expenses). Igual que en v2, la box
    // se abre en init() y no hay datos previos que migrar.
    //
    // if (current < 4) {
    //   // nueva lógica aquí
    // }

    await _metaBox.put('db_version', _schemaVersion);
  }

  // ValueListenable for UI updates
  ValueListenable<Box<Product>> get productsListenable => _productsBox.listenable();
  ValueListenable<Box<Sale>> get salesListenable => _salesBox.listenable();
  ValueListenable<Box<CashCount>> get cashboxListenable => _cashboxBox.listenable();
  ValueListenable<Box<Debt>> get debtsListenable => _debtsBox.listenable();
  ValueListenable<Box<TransferAccount>> get transferAccountsListenable =>
      _transferAccountsBox.listenable();
  ValueListenable<Box<String>> get categoriesListenable => _categoriesBox.listenable();
  ValueListenable<Box<Expense>> get expensesListenable => _expensesBox.listenable();

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

  // ---- Categorías de productos ----

  // Devuelve las categorías ordenadas alfabéticamente, sin vacías.
  List<String> getCategories() {
    final list = _categoriesBox.values.toList().cast<String>();
    list.sort();
    return list;
  }

  Future<void> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    if (_categoriesBox.values.any((c) => c.toLowerCase() == trimmed.toLowerCase())) {
      return;
    }
    await _categoriesBox.add(trimmed);
  }

  Future<void> deleteCategory(String name) async {
    final keys = _categoriesBox.keys.toList();
    for (final key in keys) {
      if (_categoriesBox.get(key) == name) {
        await _categoriesBox.delete(key);
      }
    }
    // Los productos que usaban la categoría quedan sin categoría.
    for (final product in _productsBox.values) {
      if (product.category == name) {
        product.category = '';
        await product.save();
      }
    }
  }

  // Sale CRUD
  Future<void> addSale(Sale sale) async {
    await _salesBox.add(sale);
    // Los gastos propios no se cobran: se descuentan automáticamente del
    // total invertido usando el precio de compra.
    if (sale.isOwnExpense) {
      await setTotalInvestment(totalInvestment - sale.ownExpenseCost);
    }
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
      // Al eliminar un gasto propio, se devuelve el importe a la inversión.
      if (sale.isOwnExpense) {
        await setTotalInvestment(totalInvestment + sale.ownExpenseCost);
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

  // Get today's sales only
  List<Sale> getTodaySales() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getSalesBetween(start, end);
  }

  // Get sales of a specific day (local midnight to 23:59).
  List<Sale> getSalesForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59);
    return getSalesBetween(start, end);
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

  // ---- Gastos (independientes de las ventas) ----

  Future<void> addExpense(Expense expense) async {
    await _expensesBox.add(expense);
  }

  Future<void> updateExpense(dynamic key, Expense expense) async {
    await _expensesBox.put(key, expense);
  }

  Future<void> deleteExpense(dynamic key) async {
    await _expensesBox.delete(key);
  }

  List<Expense> getExpenses() {
    return _expensesBox.values.toList().cast<Expense>();
  }

  double getTotalExpenses() {
    double total = 0;
    for (final e in _expensesBox.values) {
      total += e.amount;
    }
    return total;
  }

  double getMonthExpenses() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    double total = 0;
    for (final e in _expensesBox.values) {
      if (!e.date.isBefore(start)) total += e.amount;
    }
    return total;
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

  // ---- Cuentas para pago por transferencia ----

  List<TransferAccount> getTransferAccounts() {
    final list = _transferAccountsBox.values.toList().cast<TransferAccount>();
    list.sort((a, b) {
      if (a.isDefault == b.isDefault) return 0;
      return a.isDefault ? -1 : 1;
    });
    return list;
  }

  TransferAccount? getDefaultTransferAccount() {
    for (final acc in _transferAccountsBox.values) {
      if (acc.isDefault) return acc;
    }
    return null;
  }

  Future<void> addTransferAccount(TransferAccount account) async {
    if (account.isDefault) {
      await _clearDefaultTransferAccounts();
    }
    await _transferAccountsBox.add(account);
  }

  Future<void> updateTransferAccount(int index, TransferAccount account) async {
    if (account.isDefault) {
      await _clearDefaultTransferAccounts();
    }
    await _transferAccountsBox.putAt(index, account);
  }

  Future<void> deleteTransferAccount(dynamic key) async {
    await _transferAccountsBox.delete(key);
  }

  Future<void> _clearDefaultTransferAccounts() async {
    for (var i = 0; i < _transferAccountsBox.length; i++) {
      final acc = _transferAccountsBox.getAt(i);
      if (acc != null && acc.isDefault) {
        acc.isDefault = false;
        await acc.save();
      }
    }
  }

  // Backup logic
  Future<void> exportData() async {
    final Map<String, dynamic> backup = {
      'products': _productsBox.values.map((p) => p.toJson()).toList(),
      'sales': _salesBox.values.map((s) => s.toJson()).toList(),
      'cashbox': _cashboxBox.values.map((c) => c.toJson()).toList(),
      'debts': _debtsBox.values.map((d) => d.toJson()).toList(),
      'transferAccounts': _transferAccountsBox.values
          .map((a) => {
                'alias': a.alias,
                'bankName': a.bankName,
                'cardNumber': a.cardNumber,
                'qrImagePath': a.qrImagePath,
                'isDefault': a.isDefault,
              })
          .toList(),
      'categories': _categoriesBox.values.toList().cast<String>(),
      'expenses': _expensesBox.values.map((e) => e.toJson()).toList(),
      'totalInvestment': totalInvestment,
      'date': DateTime.now().toIso8601String(),
    };

    final jsonString = jsonEncode(backup);
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/backup_ganancias_${DateTime.now().millisecondsSinceEpoch}.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)], text: 'Copia de seguridad - Cuentas Claras');
  }

  // Genera el JSON de respaldo y lo guarda en la carpeta Descargas con nombre y fecha.
  // Es manual: se llama desde el botón "Hacer Backup" de la app.
  // Devuelve true si se guardó correctamente.
  Future<bool> makeBackup() async {
    try {
      final Map<String, dynamic> backup = {
        'products': _productsBox.values.map((p) => p.toJson()).toList(),
        'sales': _salesBox.values.map((s) => s.toJson()).toList(),
        'cashbox': _cashboxBox.values.map((c) => c.toJson()).toList(),
        'debts': _debtsBox.values.map((d) => d.toJson()).toList(),
      'transferAccounts': _transferAccountsBox.values
          .map((a) => {
                'alias': a.alias,
                'bankName': a.bankName,
                'cardNumber': a.cardNumber,
                'qrImagePath': a.qrImagePath,
                'isDefault': a.isDefault,
              })
          .toList(),
      'categories': _categoriesBox.values.toList().cast<String>(),
      'expenses': _expensesBox.values.map((e) => e.toJson()).toList(),
      'totalInvestment': totalInvestment,
      'date': DateTime.now().toIso8601String(),
    };

      final jsonString = jsonEncode(backup);
      final directory = await getTemporaryDirectory();
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final fileName = 'cuentas_claras_${now.year}-${two(now.month)}-${two(now.day)}_${two(now.hour)}-${two(now.minute)}.json';

      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      final saveInfo = await MediaStore().saveFile(
        tempFilePath: file.path,
        dirType: DirType.download,
        dirName: DirName.download,
      );

      // En algunos dispositivos (Android 10) el plugin copia el archivo a
      // Descargas pero no devuelve el SaveInfo. Verificamos que la copia
      // realmente exista antes de reportar el resultado.
      String? savedUri;
      if (saveInfo != null) {
        savedUri = saveInfo.uri.toString();
      } else {
        savedUri = await _findBackupUriInDownloads(fileName);
      }
      if (savedUri == null) return false;

      try {
        await _recordSavedBackup(saveInfo?.name ?? fileName, savedUri);
      } catch (e) {
        // Si no se pudo registrar la copia en la lista de la app, la copia
        // en Descargas sigue siendo válida: no se reporta como error.
        debugPrint('No se pudo registrar la copia: $e');
      }
      return true;
    } catch (e) {
      debugPrint('Backup falló: $e');
      return false;
    }
  }

  // Localiza la copia recién guardada en Descargas y devuelve su URI.
  // Sirve como respaldo cuando el plugin no devuelve el SaveInfo.
  Future<String?> _findBackupUriInDownloads(String fileName) async {
    // Intenta ubicarla por nombre vía MediaStore (Android 11+).
    try {
      final uri = await MediaStore().getFileUri(
        fileName: fileName,
        dirType: DirType.download,
        dirName: DirName.download,
      );
      if (uri != null) return uri.toString();
    } catch (_) {}

    // Fallback Android 10: ruta directa usada por el plugin al copiar.
    final external = await getExternalStorageDirectory();
    if (external != null) {
      final f = File('${external.path}/Download/${MediaStore.appFolder}/$fileName');
      if (await f.exists()) return f.uri.toString();
    }
    return null;
  }

  // Restaura los datos desde un backup guardado en el teléfono (por URI).
  // No abre el selector de archivos: funciona 100% dentro de la app.
  Future<void> restoreFromUri(String uri) async {
    final jsonString = await _readBackupByUri(uri);
    await _restoreFromJsonString(jsonString);
  }

  // Abre el selector de archivos del sistema para elegir una copia manual.
  // Se mantiene como opción por si la copia llegó por otra vía (WhatsApp, etc.).
  Future<void> importData() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final picked = result.files.single;
      String jsonString;
      if (picked.bytes != null) {
        // withData: lee el contenido en memoria, sin depender del path.
        jsonString = utf8.decode(picked.bytes!);
      } else if (picked.path != null) {
        final file = File(picked.path!);
        jsonString = await file.readAsString();
      } else {
        throw const FormatException('No se pudo leer el archivo seleccionado');
      }
      await _restoreFromJsonString(jsonString);
    }
  }

  Future<void> _restoreFromJsonString(String jsonString) async {
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
      await _transferAccountsBox.clear();
      await _categoriesBox.clear();
      await _expensesBox.clear();

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

      if (backup['transferAccounts'] is List) {
        final accounts = (backup['transferAccounts'] as List)
            .where((i) => i is Map)
            .map((i) => TransferAccount(
                  alias: (i['alias'] ?? '').toString(),
                  bankName: (i['bankName'] ?? '').toString(),
                  cardNumber: (i['cardNumber'] ?? '').toString(),
                  qrImagePath: (i['qrImagePath'] ?? '').toString(),
                  isDefault: i['isDefault'] == true,
                ))
            .toList();
        if (accounts.isNotEmpty) {
          await _transferAccountsBox.addAll(accounts);
        }
      }

      // Categorías (opcional: los backups viejos no las traen).
      if (backup['categories'] is List) {
        final categories = (backup['categories'] as List)
            .where((c) => c is String && c.toString().trim().isNotEmpty)
            .map((c) => c.toString())
            .toSet()
            .toList();
        if (categories.isNotEmpty) {
          await _categoriesBox.addAll(categories);
        }
      }

      // Gastos (opcional: los backups hechos con la app de producción
      // anterior no traen esta sección).
      if (backup['expenses'] is List) {
        final expenses = (backup['expenses'] as List)
            .whereType<Map>()
            .map((i) => Expense.fromJson(Map<String, dynamic>.from(i)))
            .toList();
        if (expenses.isNotEmpty) {
          await _expensesBox.addAll(expenses);
        }
      }

      // Inversión total (opcional: los backups viejos no la traen).
      if (backup['totalInvestment'] is num) {
        await _metaBox.put(
          'total_investment',
          (backup['totalInvestment'] as num).toDouble(),
        );
      }
    } else {
      throw const FormatException('El archivo no es una copia de Cuentas Claras válida');
    }
  }
}

