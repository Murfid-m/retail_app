import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Script to seed orders data from dashboard_data.json (daily sales data)
/// Run with: dart run lib/scripts/seed_orders.dart
Future<void> main() async {
  print('🌱 Starting order data seeding from dashboard_data.json...\n');

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

    // Read dashboard_data.json
    final jsonFile = File('data/dashboard_data.json');
    final jsonData = jsonDecode(await jsonFile.readAsString());
    final dailySales = jsonData['daily_sales'] as List;

    print('📊 Found ${dailySales.length} days of data\n');

    int totalOrders = 0;
    double totalSales = 0;
    int batchCount = 0;

    // Process each day from daily_sales
    for (var dayData in dailySales) {
      final date = dayData['date'] as String;
      final sales = (dayData['sales'] as num).toDouble();

      // Update progress setiap 100 entries
      if (batchCount % 100 == 0) {
        print('Processing $date... ($batchCount/${dailySales.length})');
      }
      batchCount++;

      // Generate 1-3 orders per day based on sales amount
      int orderCount = 1;
      if (sales > 5000) orderCount = 2;
      if (sales > 15000) orderCount = 3;

      final avgOrderValue = sales / orderCount;

      for (int i = 0; i < orderCount; i++) {
        final orderValue = avgOrderValue * (0.9 + (i * 0.1));
        final hour = 9 + (i * 3); // Orders at 9am, 12pm, 3pm

        await supabase.from('orders').insert({
          'user_id': userId,
          'user_name': 'Customer $date-${i + 1}',
          'user_phone': '0812345678${(batchCount * 10 + i) % 100}'.padRight(12, '0'),
          'user_email': 'customer_${date.replaceAll('-', '')}_${i + 1}@example.com',
          'shipping_address': 'Jakarta, Indonesia',
          'total_amount': orderValue,
          'status': 'completed',
          'created_at': '${date}T${hour.toString().padLeft(2, '0')}:00:00Z',
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
