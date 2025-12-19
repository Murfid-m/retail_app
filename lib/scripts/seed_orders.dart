import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Script to seed orders data from dashboard_summary.json
/// Run with: dart run lib/scripts/seed_orders.dart
Future<void> main() async {
  print('🌱 Starting order data seeding...\n');

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://rynlfumkxecgngslxdwr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ5bmxmdW1reGVjZ25nc2x4ZHdyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzMzOTYyNjMsImV4cCI6MjA0ODk3MjI2M30.Cd5LyiPdL33aYn81Xr9Sg30EsHFDrj5b2VIXx2YFwRQ',
  );

  final supabase = Supabase.instance.client;

  try {
    // Get admin user
    final adminResponse = await supabase
        .from('users')
        .select()
        .eq('is_admin', true)
        .limit(1)
        .single();

    final userId = adminResponse['id'];
    print('✅ Found admin user: ${adminResponse['email']}\n');

    // Read dashboard_summary.json
    final jsonFile = File('data/dashboard_summary.json');
    final jsonData = jsonDecode(await jsonFile.readAsString());
    final monthlyData = jsonData['monthly_sales_trend'] as List;

    print('📊 Found ${monthlyData.length} months of data\n');

    int totalOrders = 0;
    double totalSales = 0;

    // Process each month
    for (var monthData in monthlyData) {
      final month = monthData['month'] as String;
      final sales = (monthData['sales'] as num).toDouble();

      // Generate 3-10 orders per month
      final orderCount = (3 + (sales / 10000)).round().clamp(3, 10);
      final avgOrderValue = sales / orderCount;

      print('Processing $month: $orderCount orders, avg Rp ${avgOrderValue.toStringAsFixed(0)}');

      for (int i = 0; i < orderCount; i++) {
        final orderValue = avgOrderValue * (0.7 + (i * 0.1)); // Variation
        final randomDay = (i * 28 / orderCount).round() + 1;

        await supabase.from('orders').insert({
          'user_id': userId,
          'user_name': 'Sample Customer ${i + 1}',
          'user_phone': '0812345678${i % 10}${(i ~/ 10) % 10}',
          'user_email': 'customer${i + 1}@example.com',
          'shipping_address': 'Jakarta, Indonesia',
          'total_amount': orderValue,
          'status': 'completed',
          'created_at': '$month-${randomDay.toString().padLeft(2, '0')}T${10 + i}:00:00Z',
        });

        totalOrders++;
        totalSales += orderValue;
      }
    }

    print('\n📅 Seeding current month data (December 2024)...');
    // Add recent data for current month
    final now = DateTime.now();
    for (int i = 0; i < 20; i++) {
      final daysAgo = i;
      final date = now.subtract(Duration(days: daysAgo));
      final amount = 50000 + (i * 10000);

      await supabase.from('orders').insert({
        'user_id': userId,
        'user_name': 'Recent Customer ${i + 1}',
        'user_phone': '0812345678${i % 10}${(i ~/ 10) % 10}',
        'user_email': 'recent${i + 1}@example.com',
        'shipping_address': 'Jakarta, Indonesia',
        'total_amount': amount,
        'status': 'completed',
        'created_at': date.toIso8601String(),
      });

      totalOrders++;
      totalSales += amount;
    }

    print('\n📅 Seeding today\'s data...');
    // Add today's orders
    for (int i = 0; i < 5; i++) {
      final amount = 75000 + (i * 25000);

      await supabase.from('orders').insert({
        'user_id': userId,
        'user_name': 'Today Customer ${i + 1}',
        'user_phone': '0812345678${i % 10}${(i ~/ 10) % 10}',
        'user_email': 'today${i + 1}@example.com',
        'shipping_address': 'Jakarta, Indonesia',
        'total_amount': amount,
        'status': 'completed',
        'created_at': DateTime.now().toIso8601String(),
      });

      totalOrders++;
      totalSales += amount;
    }

    print('\n✅ Seeding completed!');
    print('📊 Total orders created: $totalOrders');
    print('💰 Total sales: Rp ${totalSales.toStringAsFixed(0)}');
    print('\n🎉 You can now view the statistics in the admin dashboard!');

  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }

  exit(0);
}
