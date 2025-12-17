import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../config/supabase_config.dart';

class EmailService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Send verification code email when user registers
  Future<bool> sendVerificationCode({
    required String email,
    required String name,
    required String verificationCode,
  }) async {
    try {
      // Use direct HTTP call to avoid CORS issues on Windows
      final url = Uri.parse(
        '${SupabaseConfig.supabaseUrl}/functions/v1/send-verification-code'
      );
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConfig.supabaseAnonKey}',
        },
        body: jsonEncode({
          'email': email,
          'name': name,
          'verificationCode': verificationCode,
        }),
      );

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
