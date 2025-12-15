import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../models/user_model.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<OrderModel> createOrder({
    required UserModel user,
    required List<CartItem> cartItems,
    required String shippingAddress,
  }) async {
    try {
      // Calculate total amount
      final totalAmount = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

      // Create order
      final orderResponse = await _supabase
          .from('orders')
          .insert({
            'user_id': user.id,
            'user_name': user.name,
            'user_phone': user.phone,
            'user_email': user.email,
            'shipping_address': shippingAddress,
            'total_amount': totalAmount,
            'status': OrderStatus.pending,
          })
          .select()
          .single();

      final orderId = orderResponse['id'];

      // Create order items
      for (var item in cartItems) {
        await _supabase.from('order_items').insert({
          'order_id': orderId,
          'product_id': item.product.id,
          'product_name': item.product.name,
          'price': item.product.price,
          'quantity': item.quantity,
          'image_url': item.product.imageUrl,
        });

        // Update product stock
        await _supabase.rpc('decrement_stock', params: {
          'product_id': item.product.id,
          'quantity': item.quantity,
        });
      }

      // Get complete order with items
      return await getOrderById(orderId);
    } catch (e) {
      rethrow;
    }
  }

  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('id', orderId)
          .single();

      return OrderModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<OrderModel>> getUserOrders(String oderId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('user_id', oderId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((order) => OrderModel.fromJson(order))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<OrderModel>> getAllOrders() async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .order('created_at', ascending: false);

      return (response as List)
          .map((order) => OrderModel.fromJson(order))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _supabase
          .from('orders')
          .update({'status': status})
          .eq('id', orderId);
    } catch (e) {
      rethrow;
    }
  }

  // Statistics for Admin
  Future<Map<String, dynamic>> getSalesStatistics() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // Daily sales
      final dailyResponse = await _supabase
          .from('orders')
          .select('total_amount')
          .gte('created_at', today.toIso8601String())
          .neq('status', OrderStatus.cancelled);

      final dailySales = (dailyResponse as List)
          .fold(0.0, (sum, order) => sum + (order['total_amount'] ?? 0).toDouble());

      // Weekly sales
      final weeklyResponse = await _supabase
          .from('orders')
          .select('total_amount')
          .gte('created_at', weekStart.toIso8601String())
          .neq('status', OrderStatus.cancelled);

      final weeklySales = (weeklyResponse as List)
          .fold(0.0, (sum, order) => sum + (order['total_amount'] ?? 0).toDouble());

      // Monthly sales
      final monthlyResponse = await _supabase
          .from('orders')
          .select('total_amount')
          .gte('created_at', monthStart.toIso8601String())
          .neq('status', OrderStatus.cancelled);

      final monthlySales = (monthlyResponse as List)
          .fold(0.0, (sum, order) => sum + (order['total_amount'] ?? 0).toDouble());

      // Total sales
      final totalResponse = await _supabase
          .from('orders')
          .select('total_amount')
          .neq('status', OrderStatus.cancelled);

      final totalSales = (totalResponse as List)
          .fold(0.0, (sum, order) => sum + (order['total_amount'] ?? 0).toDouble());

      // Order counts
      final dailyCount = (dailyResponse as List).length;
      final weeklyCount = (weeklyResponse as List).length;
      final monthlyCount = (monthlyResponse as List).length;
      final totalCount = (totalResponse as List).length;

      return {
        'daily': {'sales': dailySales, 'count': dailyCount},
        'weekly': {'sales': weeklySales, 'count': weeklyCount},
        'monthly': {'sales': monthlySales, 'count': monthlyCount},
        'total': {'sales': totalSales, 'count': totalCount},
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDailySalesForChart(int days) async {
    try {
      final List<Map<String, dynamic>> salesData = [];
      final now = DateTime.now();

      for (int i = days - 1; i >= 0; i--) {
        final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final nextDate = date.add(const Duration(days: 1));

        final response = await _supabase
            .from('orders')
            .select('total_amount')
            .gte('created_at', date.toIso8601String())
            .lt('created_at', nextDate.toIso8601String())
            .neq('status', OrderStatus.cancelled);

        final sales = (response as List)
            .fold(0.0, (sum, order) => sum + (order['total_amount'] ?? 0).toDouble());

        salesData.add({
          'date': date,
          'sales': sales,
        });
      }

      return salesData;
    } catch (e) {
      rethrow;
    }
  }
}
