class OrderItem {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String imageUrl;

  OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  double get totalPrice => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      productName: json['product_name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      quantity: json['quantity'] ?? 1,
      imageUrl: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'image_url': imageUrl,
    };
  }
}

class OrderModel {
  final String id;
  final String oderId;
  final String userName;
  final String userPhone;
  final String userEmail;
  final String shippingAddress;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.oderId,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    required this.shippingAddress,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? '',
      oderId: json['user_id'] ?? '',
      userName: json['user_name'] ?? '',
      userPhone: json['user_phone'] ?? '',
      userEmail: json['user_email'] ?? '',
      shippingAddress: json['shipping_address'] ?? '',
      items:
          (json['order_items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromJson(item))
              .toList() ??
          [],
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': oderId,
      'user_name': userName,
      'user_phone': userPhone,
      'user_email': userEmail,
      'shipping_address': shippingAddress,
      'total_amount': totalAmount,
      'status': status,
    };
  }
}

class OrderStatus {
  static const String pending = 'pending';
  static const String processing = 'processing';
  static const String shipped = 'shipped';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';

  static List<String> get all => [
    pending,
    processing,
    shipped,
    delivered,
    cancelled,
  ];
}
