import 'product_model.dart';

class CartItem {
  final String id;
  final ProductModel product;
  int quantity;

  CartItem({required this.id, required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json, ProductModel product) {
    return CartItem(
      id: json['id'] ?? '',
      product: product,
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'product_id': product.id, 'quantity': quantity};
  }
}

class CartModel {
  final String id;
  final String oderId;
  final List<CartItem> items;

  CartModel({required this.id, required this.oderId, required this.items});

  double get totalPrice => items.fold(0, (sum, item) => sum + item.totalPrice);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
}
