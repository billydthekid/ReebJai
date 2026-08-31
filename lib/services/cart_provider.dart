import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItemModel> _items = [];
  final _uuid = const Uuid();

  List<CartItemModel> get items => List.unmodifiable(_items);

  double get total => _items.fold(0, (sum, item) => sum + item.subtotal);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  void addProduct(ProductModel product) {
    final existing = _items.where((i) => i.product.productId == product.productId);
    if (existing.isNotEmpty) {
      existing.first.quantity++;
    } else {
      _items.add(CartItemModel(
        cartItemId: _uuid.v4(),
        product: product,
        quantity: 1,
      ));
    }
    notifyListeners();
  }

  void removeItem(String cartItemId) {
    _items.removeWhere((i) => i.cartItemId == cartItemId);
    notifyListeners();
  }

  void decreaseQuantity(String cartItemId) {
    final item = _items.firstWhere((i) => i.cartItemId == cartItemId);
    if (item.quantity > 1) {
      item.quantity--;
    } else {
      _items.remove(item);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> toMapList() =>
      _items.map((i) => i.toMap()).toList();
}
