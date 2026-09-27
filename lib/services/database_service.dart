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
import '../models/purchase.dart';
import '../models/shrinkage.dart';
import '../theme/app_palettes.dart';

class DatabaseService {
  // Versión del esquema de la base de datos.
  // Aumenta este número cuando agregues/cambies campos de un modelo y deja
  // la lógica de migración en _migrate(). Así las actualizaciones nunca
  // pierden los datos del usuario.
  static const int _schemaVersion = 5;

  late Box<Product> _productsBox;
  late Box<Sale> _salesBox;
  late Box<CashCount> _cashboxBox;
  late Box<Debt> _debtsBox;
  late Box<TransferAccount> _transferAccountsBox;
  late Box<String> _categoriesBox;
  late Box<Expense> _expensesBox;
  late Box<Purchase> _purchasesBox;
  late Box<Shrinkage> _shrinkagesBox;
  late Box _metaBox;

  Box<Product> get productsBox => _productsBox;
  Box<Sale> get salesBox => _salesBox;
  Box<CashCount> get cashboxBox => _cashboxBox;
  Box<Debt> get debtsBox => _debtsBox;
  Box<TransferAccount> get transferAccountsBox => _transferAccountsBox;
  Box<String> get categoriesBox => _categoriesBox;
  Box<Expense> get expensesBox => _expensesBox;
  Box<Purchase> get purchasesBox => _purchasesBox;
  Box<Shrinkage> get shrinkagesBox => _shrinkagesBox;

  bool get onboardingSeen =>
      _metaBox.get('onboarding_seen', defaultValue: false) as bool;

  Future<void> markOnboardingSeen() async {
    await _metaBox.put('onboarding_seen', true);
  }

  // ValorListenable de la box de metadatos para refrescar la UI cuando
  // cambian campos como la inversión total.
  ValueListenable<Box> get metaListenable => _metaBox.listenable();

  // ---- Apariencia (tema, paleta, moneda) ----
  static const String _appearanceModeKey = 'appearance_mode';
  static const String _appearancePaletteKey = 'appearance_palette';
  static const String _appearanceCurrencyKey = 'appearance_currency';

  AppThemeMode get appearanceMode {
    final value = _metaBox.get(_appearanceModeKey, defaultValue: 'light');
    switch (value) {
      case 'dark':
        return AppThemeMode.dark;
      case 'highContrast':
        return AppThemeMode.highContrast;
      case 'light':
      default:
        return AppThemeMode.light;
    }
  }

  AppPalette get appearancePalette {
    return paletteById(
      _metaBox.get(_appearancePaletteKey, defaultValue: 'ocean') as String,
    );
  }

  String get appearanceCurrency =>
      _metaBox.get(_appearanceCurrencyKey, defaultValue: 'CUP') as String;

  Future<void> setAppearance({
    AppThemeMode? mode,
    String? paletteId,
    String? currency,
  }) async {
    if (mode != null) {
      await _metaBox.put(_appearanceModeKey, mode.name);
    }
    if (paletteId != null) {
      await _metaBox.put(_appearancePaletteKey, paletteId);
    }
    if (currency != null) {
      await _metaBox.put(_appearanceCurrencyKey, currency);
    }
  }

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

  // ---- Configuración de la publicación para compartir ----
  // Se guarda en la box de metadatos. Todos los campos tienen valores por
  // defecto razonables para que la publicación salga bien sin configurar nada.
  static const String _pubBusinessNameKey = 'pub_business_name';
  static const String _pubHeaderKey = 'pub_header';
  static const String _pubFooterKey = 'pub_footer';
  static const String _pubPhonesKey = 'pub_phones';
  static const String _pubTagKey = 'pub_price_tag';

  String get publicationBusinessName =>
      (_metaBox.get(_pubBusinessNameKey, defaultValue: 'Mi Negocio') as String);

  String get publicationHeader =>
      (_metaBox.get(
            _pubHeaderKey,
            defaultValue:
                '💢 *LOS MEJORES PRECIOS AQUI* ✅\n'
                '💢 *TODOS LOS PRODUCTOS EN EFECTIVO*💢 \n\n'
                '💯 *Disponible*:\n',
          )
          as String);

  String get publicationFooter =>
      (_metaBox.get(
            _pubFooterKey,
            defaultValue: '\n🚲 *DOMICILIO DISPONIBLE Y GRATIS* 🚲',
          )
          as String);

  String get publicationPhones =>
      (_metaBox.get(_pubPhonesKey, defaultValue: '') as String);

  String get publicationPriceTag =>
      (_metaBox.get(_pubTagKey, defaultValue: ' *EFECTIVO*') as String);

  Future<void> setPublicationConfig({
    String? businessName,
    String? header,
    String? footer,
    String? phones,
    String? priceTag,
  }) async {
    if (businessName != null) {
      await _metaBox.put(_pubBusinessNameKey, businessName);
    }
    if (header != null) {
      await _metaBox.put(_pubHeaderKey, header);
    }
    if (footer != null) {
      await _metaBox.put(_pubFooterKey, footer);
    }
    if (phones != null) {
      await _metaBox.put(_pubPhonesKey, phones);
    }
    if (priceTag != null) {
      await _metaBox.put(_pubTagKey, priceTag);
    }
  }

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
    final tempFile = File(
      '${dir.path}/backup_restore_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    final ok = await MediaStore().readFileUsingUri(
      uriString: uriString,
      tempFilePath: tempFile.path,
    );
    if (!ok || !await tempFile.exists()) {
      throw const FormatException('No se pudo leer la copia desde el teléfono');
    }
    return await tempFile.readAsString();
  }

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(SaleAdapter());
    Hive.registerAdapter(CashCountAdapter());
    Hive.registerAdapter(DebtAdapter());
    Hive.registerAdapter(PaymentAdapter());
    Hive.registerAdapter(TransferAccountAdapter());
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(PurchaseItemAdapter());
    Hive.registerAdapter(PurchaseAdapter());
    Hive.registerAdapter(ShrinkageAdapter());

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
    _transferAccountsBox = await _openBoxSafely<TransferAccount>(
      'transfer_accounts',
    );
    _categoriesBox = await _openBoxSafely<String>('categories');
    _expensesBox = await _openBoxSafely<Expense>('expenses');
    _purchasesBox = await _openBoxSafely<Purchase>('purchases');
    _shrinkagesBox = await _openBoxSafely<Shrinkage>('shrinkages');

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
    // v4: se agregaron las box de compras/lotes (purchases) y mermas
    // (shrinkages). Ambas se abren en init() sin datos previos que migrar;
    // solo se actualiza el número de esquema.
    //

    if (current < 5) {
      await _migrateToV5();
    }

    await _metaBox.put('db_version', _schemaVersion);
  }

  // v5: cada producto recibe un ID estable (productId). Este ID es el que
  // sobrevive a renombres y permite fusionar duplicados. Los registros del
  // libro mayor (ventas, compras, mermas, fiados) que quedaron sin ID se
  // vinculan al catálogo por nombre para que el historial no se pierda.
  Future<void> _migrateToV5() async {
    // 1) Asigna IDs estables a los productos que aún no tienen.
    for (final product in _productsBox.values.toList()) {
      if (product.productId == null || product.productId!.isEmpty) {
        product.ensureId();
        await product.save();
      }
    }

    // Mapa nombre -> ID actual del catálogo (la primera coincidencia gana).
    final idByName = <String, String>{};
    for (final product in _productsBox.values) {
      idByName.putIfAbsent(product.name, () => product.productId!);
    }

    // 2) Vincula ventas antiguas por nombre de producto.
    for (final sale in _salesBox.values.toList()) {
      if (sale.productId == null || sale.productId!.isEmpty) {
        final id = idByName[sale.productName];
        if (id != null) {
          sale.productId = id;
          await sale.save();
        }
      }
    }

    // 3) Vincula los artículos de compras antiguos por nombre. Los items
    // van anidados en el Purchase, así que se persiste el lote completo.
    for (final purchase in _purchasesBox.values.toList()) {
      var changed = false;
      for (final item in purchase.items) {
        if (item.productId == null || item.productId!.isEmpty) {
          final id = idByName[item.productName];
          if (id != null) {
            item.productId = id;
            changed = true;
          }
        }
      }
      if (changed) await purchase.save();
    }

    // 4) Vincula las mermas antiguas por nombre.
    for (final shrinkage in _shrinkagesBox.values.toList()) {
      if (shrinkage.productId == null || shrinkage.productId!.isEmpty) {
        final id = idByName[shrinkage.productName];
        if (id != null) {
          shrinkage.productId = id;
          await shrinkage.save();
        }
      }
    }

    // 5) Vincula los fiados antiguos por nombre.
    for (final debt in _debtsBox.values.toList()) {
      if (debt.productId == null || debt.productId!.isEmpty) {
        final id = idByName[debt.productName];
        if (id != null) {
          debt.productId = id;
          await debt.save();
        }
      }
    }
  }

  // ValueListenable for UI updates
  ValueListenable<Box<Product>> get productsListenable =>
      _productsBox.listenable();
  ValueListenable<Box<Sale>> get salesListenable => _salesBox.listenable();
  ValueListenable<Box<CashCount>> get cashboxListenable =>
      _cashboxBox.listenable();
  ValueListenable<Box<Debt>> get debtsListenable => _debtsBox.listenable();
  ValueListenable<Box<TransferAccount>> get transferAccountsListenable =>
      _transferAccountsBox.listenable();
  ValueListenable<Box<String>> get categoriesListenable =>
      _categoriesBox.listenable();
  ValueListenable<Box<Expense>> get expensesListenable =>
      _expensesBox.listenable();
  ValueListenable<Box<Purchase>> get purchasesListenable =>
      _purchasesBox.listenable();
  ValueListenable<Box<Shrinkage>> get shrinkagesListenable =>
      _shrinkagesBox.listenable();

  // Product CRUD
  Future<void> addProduct(Product product) async {
    product.ensureId();
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
    if (_categoriesBox.values.any(
      (c) => c.toLowerCase() == trimmed.toLowerCase(),
    )) {
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

  // Registra una venta y descuenta el stock en un solo paso. El producto se
  // vuelve a buscar en la box (por ID estable) para no escribir sobre una
  // copia vieja que haya quedado en memoria tras una fusión o restauración.
  Future<void> registerSale(Sale sale) async {
    final product = _productByIdOrName(sale.productId, sale.productName);
    if (product == null) {
      throw StateError('El producto ${sale.productName} ya no existe');
    }
    product.stock -= sale.quantity;
    await product.save();
    try {
      await addSale(sale);
    } catch (_) {
      // Sin venta registrada no debe quedar el stock descontado.
      product.stock += sale.quantity;
      await product.save();
      rethrow;
    }
  }

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
      // Restaura el stock del producto (por ID estable o por nombre).
      final product = _productByIdOrName(sale.productId, sale.productName);
      if (product != null) {
        product.stock += sale.quantity;
        await product.save();
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

  // ---- Historial de productos (desde el libro de ventas) ----

  // Productos que alguna vez se han vendido (excluye los gastos propios),
  // ordenados alfabéticamente. Incluye productos ya eliminados del catálogo.
  List<String> getSoldProductNames() {
    final names = <String>{};
    for (final sale in _salesBox.values) {
      if (sale.isOwnExpense) continue;
      names.add(sale.productName);
    }
    final list = names.toList()..sort();
    return list;
  }

  // Ventas de un producto (sin gastos propios), más recientes primero.
  List<Sale> getSalesForProduct(String productName) {
    final sales = _salesBox.values
        .where((s) => s.productName == productName && !s.isOwnExpense)
        .toList();
    sales.sort((a, b) => b.date.compareTo(a.date));
    return sales;
  }

  // Get weekly sales (from previous inventory day to current inventory day)
  List<Sale> getWeeklySalesCustom(int inventoryDay) {
    final now = DateTime.now();
    // Find the most recent inventory day
    int daysSinceInventory = (now.weekday - inventoryDay) % 7;
    if (daysSinceInventory < 0) daysSinceInventory += 7;
    final currentInventory = now.subtract(Duration(days: daysSinceInventory));
    final previousInventory = currentInventory.subtract(
      const Duration(days: 7),
    );
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
    return {'totalSales': totalSales, 'totalProfit': totalProfit};
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

  int getLowStockCount({int threshold = 5}) =>
      getLowStockProducts(threshold: threshold).length;

  // Busca un producto por nombre (o null si ya no existe).
  Product? productByName(String name) {
    for (final product in _productsBox.values) {
      if (product.name == name) return product;
    }
    return null;
  }

  // Busca un producto por su ID estable (o null si ya no existe).
  Product? productById(String id) {
    for (final product in _productsBox.values) {
      if (product.productId == id) return product;
    }
    return null;
  }

  // Versión actual en la box de un producto que se tenga en memoria.
  Product? findProduct(Product product) =>
      _productByIdOrName(product.productId, product.name);

  // Busca un producto por su ID estable, o por nombre si el ID falta o no
  // coincide (registros antiguos o productos renombrados).
  Product? _productByIdOrName(String? productId, String productName) {
    if (productId != null && productId.isNotEmpty) {
      for (final p in _productsBox.values) {
        if (p.productId == productId) return p;
      }
    }
    for (final p in _productsBox.values) {
      if (p.name == productName) return p;
    }
    return null;
  }

  // Clave de agrupación de los registros del libro de ventas: el ID del
  // producto si existe, o el nombre para los registros antiguos sin ID.
  static String saleGroupKey(Sale sale) {
    if (sale.productId != null && sale.productId!.isNotEmpty) {
      return sale.productId!;
    }
    return sale.productName;
  }

  // Ventas de un grupo de producto (por ID estable, o por nombre cuando el
  // grupo viene de registros antiguos sin ID), excluyendo gastos propios.
  List<Sale> getSalesForProductGroup(String groupKey) {
    final sales = _salesBox.values
        .where(
          (s) => !s.isOwnExpense && saleGroupKey(s) == groupKey,
        )
        .toList();
    sales.sort((a, b) => b.date.compareTo(a.date));
    return sales;
  }

  // Cuántos registros del libro mayor referencian a un producto (por ID o
  // por nombre). Sirve para mostrar un aviso antes de fusionar duplicados.
  Map<String, int> ledgerReferences(Product product) {
    final id = product.productId;
    final name = product.name;
    bool matches(String? refId, String refName) {
      if (id != null && id.isNotEmpty && refId == id) return true;
      return refName == name;
    }

    var sales = 0, purchaseItems = 0, shrinkages = 0, debts = 0;
    for (final s in _salesBox.values) {
      if (matches(s.productId, s.productName)) sales++;
    }
    for (final p in _purchasesBox.values) {
      for (final i in p.items) {
        if (matches(i.productId, i.productName)) purchaseItems++;
      }
    }
    for (final s in _shrinkagesBox.values) {
      if (matches(s.productId, s.productName)) shrinkages++;
    }
    for (final d in _debtsBox.values) {
      if (matches(d.productId, d.productName)) debts++;
    }
    return {
      'sales': sales,
      'purchases': purchaseItems,
      'shrinkages': shrinkages,
      'debts': debts,
    };
  }

  // Fusiona uno o más productos duplicados dentro del principal (keeper).
  // Suma su stock, unifica el historial (ventas, compras, mermas y fiados
  // que lo referencian) y elimina del catálogo los productos absorbidos.
  // El keeper conserva su ID estable y sus precios/categoría.
  Future<void> mergeProducts({
    required Product keeper,
    required List<Product> absorbed,
  }) async {
    if (absorbed.isEmpty) return;

    keeper.ensureId();
    final keeperId = keeper.productId!;
    final keeperName = keeper.name;

    final absorbedIds = <String>{};
    final absorbedNames = <String>{};
    for (final p in absorbed) {
      if (p.productId != null && p.productId!.isNotEmpty) {
        absorbedIds.add(p.productId!);
      }
      absorbedNames.add(p.name);
    }

    bool matches(String? id, String? name) {
      if (id != null && id.isNotEmpty && absorbedIds.contains(id)) {
        return true;
      }
      return name != null && absorbedNames.contains(name);
    }

    // Suma el stock de los absorbidos al producto principal.
    for (final p in absorbed) {
      keeper.stock += p.stock;
    }
    await keeper.save();

    // Ventas.
    for (final sale in _salesBox.values.toList()) {
      if (matches(sale.productId, sale.productName)) {
        sale.productId = keeperId;
        sale.productName = keeperName;
        await sale.save();
      }
    }

    // Compras: los items van anidados en el lote, se persiste cada lote.
    for (final purchase in _purchasesBox.values.toList()) {
      var changed = false;
      for (final item in purchase.items) {
        if (matches(item.productId, item.productName)) {
          item.productId = keeperId;
          item.productName = keeperName;
          changed = true;
        }
      }
      if (changed) await purchase.save();
    }

    // Mermas.
    for (final shrinkage in _shrinkagesBox.values.toList()) {
      if (matches(shrinkage.productId, shrinkage.productName)) {
        shrinkage.productId = keeperId;
        shrinkage.productName = keeperName;
        await shrinkage.save();
      }
    }

    // Fiados.
    for (final debt in _debtsBox.values.toList()) {
      if (matches(debt.productId, debt.productName)) {
        debt.productId = keeperId;
        debt.productName = keeperName;
        await debt.save();
      }
    }

    // Elimina del catálogo los productos absorbidos.
    for (final p in absorbed) {
      await p.delete();
    }
  }

  // Costo promedio ponderado del producto según las compras registradas
  // (suma(costo × cantidad) / suma(cantidad)). Null si no hay compras.
  double? getWeightedPurchaseCost(String productName) {
    return weightedAveragePurchaseCost(
      _purchasesBox.values.cast<Purchase>(),
      productName,
    );
  }

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

  // ---- Compras / Lotes (historial inmutable) ----

  // Registra una compra y sube el stock de cada producto del lote.
  // El histórico queda guardado sin importar el stock que haya después.
  Future<void> addPurchase(Purchase purchase) async {
    for (final item in purchase.items) {
      await _addStockByName(
        item.productName,
        item.quantity,
        productId: item.productId,
      );
    }
    await _purchasesBox.add(purchase);
  }

  // Elimina una compra y revierte el stock que subió (si el producto
  // aún existe). Útil solo para errores de captura.
  Future<void> deletePurchase(dynamic key) async {
    final purchase = _purchasesBox.get(key);
    if (purchase != null) {
      for (final item in purchase.items) {
        await _removeStockByName(
          item.productName,
          item.quantity,
          productId: item.productId,
        );
      }
    }
    await _purchasesBox.delete(key);
  }

  List<Purchase> getPurchases() {
    final list = _purchasesBox.values.toList().cast<Purchase>();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<Purchase> getPurchasesBetween(DateTime start, DateTime end) {
    return _purchasesBox.values.where((p) {
      return p.date.isAfter(start.subtract(const Duration(days: 1))) &&
          p.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  double getPurchasesTotal() {
    double total = 0;
    for (final p in _purchasesBox.values) {
      total += p.totalCost;
    }
    return total;
  }

  double getPurchasesTotalBetween(DateTime start, DateTime end) {
    double total = 0;
    for (final p in getPurchasesBetween(start, end)) {
      total += p.totalCost;
    }
    return total;
  }

  // ---- Mermas / Ajustes ----

  // Registra una merma y baja el stock del producto (sin dejar negativo).
  Future<void> addShrinkage(Shrinkage shrinkage) async {
    await _removeStockByName(
      shrinkage.productName,
      shrinkage.quantity,
      productId: shrinkage.productId,
    );
    await _shrinkagesBox.add(shrinkage);
  }

  // Elimina una merma y restaura el stock que se bajó.
  Future<void> deleteShrinkage(dynamic key) async {
    final shrinkage = _shrinkagesBox.get(key);
    if (shrinkage != null) {
      await _addStockByName(
        shrinkage.productName,
        shrinkage.quantity,
        productId: shrinkage.productId,
      );
    }
    await _shrinkagesBox.delete(key);
  }

  List<Shrinkage> getShrinkages() {
    final list = _shrinkagesBox.values.toList().cast<Shrinkage>();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<Shrinkage> getShrinkagesBetween(DateTime start, DateTime end) {
    return _shrinkagesBox.values.where((s) {
      return s.date.isAfter(start.subtract(const Duration(days: 1))) &&
          s.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  double getShrinkageCostBetween(DateTime start, DateTime end) {
    double total = 0;
    for (final s in getShrinkagesBetween(start, end)) {
      total += s.cost;
    }
    return total;
  }

  double getTotalShrinkageCost() {
    double total = 0;
    for (final s in _shrinkagesBox.values) {
      total += s.cost;
    }
    return total;
  }

  // ---- Indicadores financieros (libro mayor) ----

  // Costo de ventas real (COGS): costo histórico de lo vendido en el período.
  double getCOGSBetween(DateTime start, DateTime end) {
    double total = 0;
    for (final sale in getSalesBetween(start, end)) {
      if (sale.isOwnExpense) continue;
      total += sale.unitBuyPrice * sale.quantity;
    }
    return total;
  }

  // Ingresos por ventas del período (los gastos propios no generan ingresos).
  double getRevenueBetween(DateTime start, DateTime end) {
    double total = 0;
    for (final sale in getSalesBetween(start, end)) {
      if (sale.isOwnExpense) continue;
      total += sale.total;
    }
    return total;
  }

  // Ganancia bruta real: ingresos menos costo histórico de lo vendido.
  double getGrossProfitBetween(DateTime start, DateTime end) {
    return getRevenueBetween(start, end) - getCOGSBetween(start, end);
  }

  // Gastos operativos registrados en el período.
  double getExpensesBetween(DateTime start, DateTime end) {
    double total = 0;
    for (final e in _expensesBox.values) {
      if (!e.date.isBefore(start) &&
          !e.date.isAfter(end.add(const Duration(days: 1)))) {
        total += e.amount;
      }
    }
    return total;
  }

  // Utilidad neta del período: ganancia bruta - mermas - gastos operativos.
  double getNetProfitBetween(DateTime start, DateTime end) {
    return getGrossProfitBetween(start, end) -
        getShrinkageCostBetween(start, end) -
        getExpensesBetween(start, end);
  }

  // Capital inyectado histórico: lo declarado manualmente + todas las compras.
  double getHistoricalCapitalInjected() {
    return totalInvestment + getPurchasesTotal();
  }

  // Rotación del inventario: cuántas veces se renovó el stock en el período.
  double getInventoryTurnover(DateTime start, DateTime end) {
    final invested = getInvestedCapital();
    if (invested <= 0) return 0;
    return getCOGSBetween(start, end) / invested;
  }

  // Margen real ponderado sobre el período (ganancia bruta / ingresos).
  double getRealMargin(DateTime start, DateTime end) {
    final revenue = getRevenueBetween(start, end);
    if (revenue <= 0) return 0;
    return getGrossProfitBetween(start, end) / revenue;
  }

  // Sube el stock de un producto buscándolo por su ID estable o por nombre.
  Future<void> _addStockByName(
    String productName,
    int quantity, {
    String? productId,
  }) async {
    final product = _productByIdOrName(productId, productName);
    if (product != null) {
      product.stock += quantity;
      await product.save();
    }
  }

  // Baja el stock de un producto (por ID o nombre) sin dejarlo negativo.
  Future<void> _removeStockByName(
    String productName,
    int quantity, {
    String? productId,
  }) async {
    final product = _productByIdOrName(productId, productName);
    if (product != null) {
      product.stock = (product.stock - quantity) >= 0
          ? product.stock - quantity
          : 0;
      await product.save();
    }
  }

  // ---- Cuentas por cobrar (fiados) ----

  Future<void> registerCreditSale(
    Product product,
    int quantity,
    String customerName, {
    String? note,
  }) async {
    // Se usa la versión actual de la box, no la copia que llega de la UI.
    final current = findProduct(product);
    if (current == null) {
      throw StateError('El producto ${product.name} ya no existe');
    }
    current.stock -= quantity;
    await current.save();

    final debt = Debt(
      customerName: customerName,
      productName: current.name,
      productId: current.productId,
      unitPrice: current.sellPrice,
      quantity: quantity,
      unitCost: current.buyPrice,
      date: DateTime.now(),
      note: note,
    );
    try {
      await _debtsBox.add(debt);
    } catch (_) {
      // Sin fiado registrado no debe quedar el stock descontado.
      current.stock += quantity;
      await current.save();
      rethrow;
    }
  }

  Future<void> addDebtPayment(
    dynamic debtKey,
    double amount,
    String method, {
    double? commissionAmount,
  }) async {
    final debt = _debtsBox.get(debtKey);
    if (debt == null) return;
    debt.payments.add(
      Payment(
        amount: amount,
        date: DateTime.now(),
        method: method,
        commissionAmount: commissionAmount,
      ),
    );
    await debt.save();
  }

  // restoreStock solo debe ser true si la mercancía volvió a la tienda
  // (fiado registrado por error o devuelto). Un fiado cobrado ya salió.
  Future<void> deleteDebt(dynamic key, {bool restoreStock = true}) async {
    final debt = _debtsBox.get(key);
    if (debt != null && restoreStock) {
      // Restaurar stock del producto fiado (por ID estable o por nombre).
      final product = _productByIdOrName(debt.productId, debt.productName);
      if (product != null) {
        product.stock += debt.quantity;
        await product.save();
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
          .map(
            (a) => {
              'alias': a.alias,
              'bankName': a.bankName,
              'cardNumber': a.cardNumber,
              'qrImagePath': a.qrImagePath,
              'isDefault': a.isDefault,
            },
          )
          .toList(),
      'categories': _categoriesBox.values.toList().cast<String>(),
      'expenses': _expensesBox.values.map((e) => e.toJson()).toList(),
      'purchases': _purchasesBox.values.map((p) => p.toJson()).toList(),
      'shrinkages': _shrinkagesBox.values.map((s) => s.toJson()).toList(),
      'totalInvestment': totalInvestment,
      'date': DateTime.now().toIso8601String(),
    };

    final jsonString = jsonEncode(backup);
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/backup_ganancias_${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.writeAsString(jsonString);

    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Copia de seguridad - Cuentas Claras');
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
            .map(
              (a) => {
                'alias': a.alias,
                'bankName': a.bankName,
                'cardNumber': a.cardNumber,
                'qrImagePath': a.qrImagePath,
                'isDefault': a.isDefault,
              },
            )
            .toList(),
        'categories': _categoriesBox.values.toList().cast<String>(),
        'expenses': _expensesBox.values.map((e) => e.toJson()).toList(),
        'purchases': _purchasesBox.values.map((p) => p.toJson()).toList(),
        'shrinkages': _shrinkagesBox.values.map((s) => s.toJson()).toList(),
        'totalInvestment': totalInvestment,
        'date': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(backup);
      final directory = await getTemporaryDirectory();
      final now = DateTime.now();
      String two(int n) => n.toString().padLeft(2, '0');
      final fileName =
          'cuentas_claras_${now.year}-${two(now.month)}-${two(now.day)}_${two(now.hour)}-${two(now.minute)}.json';

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
      final f = File(
        '${external.path}/Download/${MediaStore.appFolder}/$fileName',
      );
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
      await _purchasesBox.clear();
      await _shrinkagesBox.clear();

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
            .map(
              (i) => TransferAccount(
                alias: (i['alias'] ?? '').toString(),
                bankName: (i['bankName'] ?? '').toString(),
                cardNumber: (i['cardNumber'] ?? '').toString(),
                qrImagePath: (i['qrImagePath'] ?? '').toString(),
                isDefault: i['isDefault'] == true,
              ),
            )
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

      // Compras / lotes (opcional: backups anteriores no la traen).
      if (backup['purchases'] is List) {
        final purchases = (backup['purchases'] as List)
            .whereType<Map>()
            .map((i) => Purchase.fromJson(Map<String, dynamic>.from(i)))
            .toList();
        if (purchases.isNotEmpty) {
          await _purchasesBox.addAll(purchases);
        }
      }

      // Mermas / ajustes (opcional: backups anteriores no la traen).
      if (backup['shrinkages'] is List) {
        final shrinkages = (backup['shrinkages'] as List)
            .whereType<Map>()
            .map((i) => Shrinkage.fromJson(Map<String, dynamic>.from(i)))
            .toList();
        if (shrinkages.isNotEmpty) {
          await _shrinkagesBox.addAll(shrinkages);
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
      throw const FormatException(
        'El archivo no es una copia de Cuentas Claras válida',
      );
    }
  }
}
