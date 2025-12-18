import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class EmailService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Send welcome email when user registers
  Future<bool> sendWelcomeEmail({
    required String email,
    required String name,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'send-welcome-email',
        body: {
          'email': email,
          'name': name,
        },
      );

      if (response.status == 200) {
        print('Welcome email sent successfully');
        return true;
      } else {
        print('Failed to send welcome email: ${response.data}');
        return false;
      }
    } catch (e) {
      print('Error sending welcome email: $e');
      return false;
    }
  }

  /// Send order confirmation email after successful checkout
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

      final response = await _supabase.functions.invoke(
        'send-order-confirmation',
        body: {
          'email': user.email,
          'name': user.name,
          'orderId': order.id,
          'items': items,
          'totalAmount': order.totalAmount,
          'shippingAddress': order.shippingAddress,
        },
      );

      if (response.status == 200) {
        print('Order confirmation email sent successfully');
        return true;
      } else {
        print('Failed to send order confirmation: ${response.data}');
        return false;
      }
    } catch (e) {
      print('Error sending order confirmation: $e');
      return false;
    }
  }
}
