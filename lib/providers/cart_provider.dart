import 'package:flutter/foundation.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  int get itemCount => _items.length;
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);

  void addToCart(ProductModel product, {String? selectedSize}) {
    // Use unique key (product_id + size) for finding existing item
    final uniqueKey = selectedSize != null ? '${product.id}_$selectedSize' : product.id;
    
    final existingIndex = _items.indexWhere(
      (item) => item.uniqueKey == uniqueKey,
    );

    if (existingIndex != -1) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(
        CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          product: product,
          quantity: 1,
          selectedSize: selectedSize,
        ),
      );
    }
    notifyListeners();
  }

  void removeFromCart(String productId, {String? selectedSize}) {
    final uniqueKey = selectedSize != null ? '${productId}_$selectedSize' : productId;
    _items.removeWhere((item) => item.uniqueKey == uniqueKey);
    notifyListeners();
  }
  
  void removeCartItem(String cartItemId) {
    _items.removeWhere((item) => item.id == cartItemId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity, {String? selectedSize}) {
    final uniqueKey = selectedSize != null ? '${productId}_$selectedSize' : productId;
    final index = _items.indexWhere((item) => item.uniqueKey == uniqueKey);
    if (index != -1) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
    }
  }

  void incrementQuantity(String productId, {String? selectedSize}) {
    final uniqueKey = selectedSize != null ? '${productId}_$selectedSize' : productId;
    final index = _items.indexWhere((item) => item.uniqueKey == uniqueKey);
    if (index != -1) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(String productId, {String? selectedSize}) {
    final uniqueKey = selectedSize != null ? '${productId}_$selectedSize' : productId;
    final index = _items.indexWhere((item) => item.uniqueKey == uniqueKey);
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

  bool isInCart(String productId, {String? selectedSize}) {
    final uniqueKey = selectedSize != null ? '${productId}_$selectedSize' : productId;
    return _items.any((item) => item.uniqueKey == uniqueKey);
  }
  
  // Check if any variant of product is in cart
  bool isProductInCart(String productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int getQuantity(String productId, {String? selectedSize}) {
    final uniqueKey = selectedSize != null ? '${productId}_$selectedSize' : productId;
    final item = _items.firstWhere(
      (item) => item.uniqueKey == uniqueKey,
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
  
  // Get total quantity for a product (all sizes)
  int getTotalQuantityForProduct(String productId) {
    return _items
        .where((item) => item.product.id == productId)
        .fold(0, (sum, item) => sum + item.quantity);
  }
}
