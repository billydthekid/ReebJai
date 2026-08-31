import 'product_model.dart';

class CartItemModel {
  final String cartItemId;
  final ProductModel product;
  int quantity;

  CartItemModel({
    required this.cartItemId,
    required this.product,
    this.quantity = 1,
  });

  double get subtotal => product.price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'cartItemId': cartItemId,
      'productId': product.productId,
      'productName': product.name,
      'productPrice': product.price,
      'productImageUrl': product.imageUrl,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }
}
