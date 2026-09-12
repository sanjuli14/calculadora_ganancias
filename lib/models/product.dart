import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double buyPrice;

  @HiveField(2)
  double sellPrice;

  @HiveField(3)
  int stock;

  @HiveField(4)
  String? imagePath;

  @HiveField(5)
  String category;

  @HiveField(6)
  String? productId;

  Product({
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    this.stock = 0,
    this.imagePath,
    this.category = '',
    this.productId,
  });

  /// Garantiza que el producto tenga un ID estable (sobrevive renombres).
  /// Asigna uno nuevo si aún no lo tiene; solo persiste si se llama a save().
  String ensureId() {
    productId ??= 'p_${DateTime.now().microsecondsSinceEpoch}';
    return productId!;
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'stock': stock,
      'category': category,
      'productId': productId,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'],
      buyPrice: json['buyPrice'],
      sellPrice: json['sellPrice'],
      stock: json['stock'],
      category: json['category'] ?? '',
      productId: json['productId'] as String?,
    );
  }
}
