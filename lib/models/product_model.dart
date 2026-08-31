class ProductModel {
  final String productId;
  final String barcode;
  final String name;
  final double price;
  final String category;
  final String imageUrl;
  final int stock;

  // Reserved for board/hardware integration
  final String? rfidTag;
  final double? weightGrams;

  ProductModel({
    required this.productId,
    required this.barcode,
    required this.name,
    required this.price,
    required this.category,
    this.imageUrl = '',
    this.stock = 100,
    this.rfidTag,
    this.weightGrams,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'barcode': barcode,
      'name': name,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
      'stock': stock,
      'rfidTag': rfidTag,
      'weightGrams': weightGrams,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      productId: map['productId'] ?? '',
      barcode: map['barcode'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      stock: map['stock'] ?? 0,
      rfidTag: map['rfidTag'],
      weightGrams: map['weightGrams']?.toDouble(),
    );
  }
}
