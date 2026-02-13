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

  Product({
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    this.stock = 0,
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'stock': stock,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['name'],
      buyPrice: json['buyPrice'],
      sellPrice: json['sellPrice'],
      stock: json['stock'],
    );
  }
}
