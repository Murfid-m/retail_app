import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../models/user_model.dart';
import 'email_service.dart';
import 'product_service.dart';

class OrderService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EmailService _emailService = EmailService();
  final ProductService _productService = ProductService();

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
          'selected_size': item.selectedSize,
        });

        // Update product stock
        await _supabase.rpc('decrement_stock', params: {
          'product_id': item.product.id,
          'quantity': item.quantity,
        });
      }

      // Get complete order with items
      final order = await getOrderById(orderId);

      // Collect product IDs for stock check
      final productIds = cartItems.map((item) => item.product.id).toList();

      // Send email notifications (async, don't wait)
      _sendOrderNotifications(user, order, productIds);

      return order;
    } catch (e) {
      rethrow;
    }
  }

  /// Send order notifications to user and admin
  Future<void> _sendOrderNotifications(UserModel user, OrderModel order, List<String> productIds) async {
    try {
      // Send order confirmation to user
      await _emailService.sendOrderConfirmation(user: user, order: order);
      
      // Notify admin about new order
      await _emailService.notifyAdminNewOrder(order: order);
      
      // Check if any ordered products now have low stock and notify admin
      await _productService.checkOrderedProductsStock(productIds);
    } catch (e) {
      print('Error sending order notifications: $e');
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

      // Get updated order and send status update email
      final order = await getOrderById(orderId);
      _sendStatusUpdateNotification(order);
    } catch (e) {
      rethrow;
    }
  }

  /// Send status update notification to user
  Future<void> _sendStatusUpdateNotification(OrderModel order) async {
    try {
      await _emailService.sendOrderStatusUpdate(
        email: order.userEmail,
        name: order.userName,
        order: order,
      );
    } catch (e) {
      print('Error sending status update notification: $e');
    }
  }

  // Statistics for Admin
  Future<Map<String, dynamic>> getSalesStatistics({DateTime? startDate, DateTime? endDate}) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // Custom date range if provided
      DateTime? customStart = startDate != null ? DateTime(startDate.year, startDate.month, startDate.day) : null;
      DateTime? customEnd = endDate != null ? DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59) : null;

      print('📊 Loading statistics...');
      print('Today: $today');
      print('Week start: $weekStart');
      print('Month start: $monthStart');
      if (customStart != null) print('Custom range: $customStart to $customEnd');

      // Daily sales
      var dailyQuery = _supabase.from('orders').select('total_amount, status, created_at');
      if (customStart != null && customEnd != null) {
        dailyQuery = dailyQuery.gte('created_at', customStart.toIso8601String()).lte('created_at', customEnd.toIso8601String());
      } else {
        dailyQuery = dailyQuery.gte('created_at', today.toIso8601String());
      }
      final dailyResponse = await dailyQuery;
      
      print('Daily response count: ${(dailyResponse as List).length}');
      if ((dailyResponse as List).isNotEmpty) {
        print('Sample daily order: ${dailyResponse[0]}');
      }

      final dailySales = (dailyResponse as List)
          .where((order) => order['status'] != 'cancelled')
          .fold(0.0, (sum, order) => sum + (order['total_amount'] ?? 0).toDouble());
      final dailyCount = (dailyResponse as List).where((order) => order['status'] != 'cancelled').length;

      // Weekly sales
      final weeklyResponse = await _supabase
          .from('orders')
          .select('total_amount, status')
          .gte('created_at', weekStart.toIso8601String());

      final weeklySales = (weeklyResponse as List)
          .where((order) => order['status'] != 'cancelled')
          .fold(0.0, (sum, order) => sum + (order['total_amount'] ?? 0).toDouble());
      final weeklyCount = (weeklyResponse as List).where((order) => order['status'] != 'cancelled').length;

      // Monthly sales
      final monthlyResponse = await _supabase
          .from('orders')
          .select('total_amount, status')
          .gte('created_at', monthStart.toIso8601String());

      final monthlySales = (monthlyResponse as List)
          .where((order) => order['status'] != 'cancelled')
          .fold(0.0, (sum, order) => sum + (order['total_amount'] ?? 0).toDouble());
      final monthlyCount = (monthlyResponse as List).where((order) => order['status'] != 'cancelled').length;

      // Total sales
      final totalResponse = await _supabase
          .from('orders')
          .select('total_amount, status');

      print('Total orders in database: ${(totalResponse as List).length}');

      final totalSales = (totalResponse as List)
          .where((order) => order['status'] != 'cancelled')
          .fold(0.0, (sum, order) => sum + (order['total_amount'] ?? 0).toDouble());
      final totalCount = (totalResponse as List).where((order) => order['status'] != 'cancelled').length;

      print('Statistics: Daily=$dailySales/$dailyCount, Weekly=$weeklySales/$weeklyCount, Monthly=$monthlySales/$monthlyCount, Total=$totalSales/$totalCount');

      return {
        'daily': {'sales': dailySales, 'count': dailyCount},
        'weekly': {'sales': weeklySales, 'count': weeklyCount},
        'monthly': {'sales': monthlySales, 'count': monthlyCount},
        'total': {'sales': totalSales, 'count': totalCount},
      };
    } catch (e) {
      print('Error loading statistics: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDailySalesForChart(int days, {DateTime? startDate, DateTime? endDate}) async {
    try {
      final List<Map<String, dynamic>> salesData = [];
      final now = DateTime.now();
      
      // If custom date range provided, use it
      final start = startDate ?? DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
      final end = endDate ?? DateTime(now.year, now.month, now.day);
      final daysDiff = end.difference(start).inDays + 1;

      for (int i = 0; i < daysDiff; i++) {
        final date = DateTime(start.year, start.month, start.day).add(Duration(days: i));
        final nextDate = date.add(const Duration(days: 1));

        final response = await _supabase
            .from('orders')
            .select('total_amount, status')
            .gte('created_at', date.toIso8601String())
            .lt('created_at', nextDate.toIso8601String());

        final sales = (response as List)
            .where((order) => order['status'] != 'cancelled')
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
