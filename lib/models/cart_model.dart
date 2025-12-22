import 'product_model.dart';

class CartItem {
  final String id;
  final ProductModel product;
  int quantity;
  final String? selectedSize; // Selected size variant

  CartItem({
    required this.id,
    required this.product,
    this.quantity = 1,
    this.selectedSize,
  });

  double get totalPrice => product.price * quantity;
  
  // Generate unique key for cart item (product_id + size)
  String get uniqueKey => selectedSize != null ? '${product.id}_$selectedSize' : product.id;

  factory CartItem.fromJson(Map<String, dynamic> json, ProductModel product) {
    return CartItem(
      id: json['id'] ?? '',
      product: product,
      quantity: json['quantity'] ?? 1,
      selectedSize: json['selected_size'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': product.id,
      'quantity': quantity,
      'selected_size': selectedSize,
    };
  }
  
  CartItem copyWith({
    String? id,
    ProductModel? product,
    int? quantity,
    String? selectedSize,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedSize: selectedSize ?? this.selectedSize,
    );
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
