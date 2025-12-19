import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../config/supabase_config.dart';

class EmailService {
  /// Helper method for HTTP POST to Edge Functions
  Future<http.Response> _postToEdgeFunction(String functionName, Map<String, dynamic> body) async {
    final url = Uri.parse(
      '${SupabaseConfig.supabaseUrl}/functions/v1/$functionName'
    );
    
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
      },
      body: jsonEncode(body),
    );
  }

  /// Send verification code email when user registers
  Future<bool> sendVerificationCode({
    required String email,
    required String name,
    required String verificationCode,
  }) async {
    try {
      final response = await _postToEdgeFunction('send-verification-code', {
        'email': email,
        'name': name,
        'verificationCode': verificationCode,
      });

      if (response.statusCode == 200) {
        print('Verification code email sent successfully');
        return true;
      } else {
        print('Failed to send verification code email: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending verification code email: $e');
      return false;
    }
  }

  /// Send order confirmation email after successful checkout (to user)
  Future<bool> sendOrderConfirmation({
    required UserModel user,
    required OrderModel order,
  }) async {
    try {
      final items = order.items.map((item) => {
        'productName': item.productName,
        'price': item.price,
        'quantity': item.quantity,
      }).toList();

      final response = await _postToEdgeFunction('send-order-confirmation', {
        'email': user.email,
        'name': user.name,
        'orderId': order.id,
        'items': items,
        'totalAmount': order.totalAmount,
        'shippingAddress': order.shippingAddress,
      });

      if (response.statusCode == 200) {
        print('Order confirmation email sent successfully');
        return true;
      } else {
        print('Failed to send order confirmation: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending order confirmation: $e');
      return false;
    }
  }

  /// Send order status update email (to user)
  Future<bool> sendOrderStatusUpdate({
    required String email,
    required String name,
    required OrderModel order,
  }) async {
    try {
      final items = order.items.map((item) => {
        'productName': item.productName,
        'price': item.price,
        'quantity': item.quantity,
      }).toList();

      final response = await _postToEdgeFunction('send-order-status-update', {
        'email': email,
        'name': name,
        'orderId': order.id,
        'status': order.status,
        'items': items,
        'totalAmount': order.totalAmount,
        'shippingAddress': order.shippingAddress,
      });

      if (response.statusCode == 200) {
        print('Order status update email sent successfully');
        return true;
      } else {
        print('Failed to send order status update: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending order status update: $e');
      return false;
    }
  }

  /// Notify admin about new order
  Future<bool> notifyAdminNewOrder({
    required OrderModel order,
  }) async {
    try {
      final items = order.items.map((item) => {
        'productName': item.productName,
        'price': item.price,
        'quantity': item.quantity,
      }).toList();

      print('Sending admin notification for order: ${order.id}');
      print('Customer: ${order.userName}, Email: ${order.userEmail}');
      print('Items count: ${items.length}, Total: ${order.totalAmount}');

      final response = await _postToEdgeFunction('notify-admin-new-order', {
        'orderId': order.id,
        'customerName': order.userName,
        'customerEmail': order.userEmail,
        'customerPhone': order.userPhone,
        'items': items,
        'totalAmount': order.totalAmount,
        'shippingAddress': order.shippingAddress,
      });

      print('Admin notification response status: ${response.statusCode}');
      print('Admin notification response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Admin notification email sent successfully');
        return true;
      } else {
        print('Failed to notify admin: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error notifying admin: $e');
      return false;
    }
  }

  /// Notify admin about low stock products
  Future<bool> notifyLowStock({
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      if (products.isEmpty) {
        print('No low stock products to notify');
        return true;
      }

      print('Sending low stock notification for ${products.length} products');

      final response = await _postToEdgeFunction('notify-low-stock', {
        'products': products,
      });

      print('Low stock notification response status: ${response.statusCode}');
      print('Low stock notification response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Low stock notification sent successfully');
        return true;
      } else {
        print('Failed to send low stock notification: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending low stock notification: $e');
      return false;
    }
  }
}
