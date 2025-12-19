import 'package:flutter/foundation.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get itemCount => _items.length;
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  void addToCart(ProductModel product) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex != -1) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(
        CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          product: product,
          quantity: 1,
        ),
      );
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void incrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  bool isInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int getQuantity(String productId) {
    final item = _items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => CartItem(
        id: '',
        product: ProductModel(
          id: '',
          name: '',
          description: '',
          price: 0,
          category: '',
          imageUrl: '',
          stock: 0,
          createdAt: DateTime.now(),
        ),
        quantity: 0,
      ),
    );
    return item.quantity;
  }
}
