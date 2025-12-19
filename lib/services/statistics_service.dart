import 'package:supabase_flutter/supabase_flutter.dart';

class StatisticsService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> loadStatistics({DateTime? startDate, DateTime? endDate}) async {
    try {
      print('📊 StatisticsService: Loading statistics...');
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);
      final last7Days = today.subtract(const Duration(days: 6));

      print('📅 Today: $today');
      print('📅 Week start: $startOfWeek');
      print('📅 Month start: $startOfMonth');

      // Get all orders (not just completed)
      var query = _supabase
          .from('orders')
          .select('created_at, total_amount, status');
      
      // Apply date range if provided
      if (startDate != null && endDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
        query = query.gte('created_at', start.toIso8601String()).lte('created_at', end.toIso8601String());
        print('📅 Custom range: $start to $end');
      }
      
      final ordersResponse = await query.order('created_at', ascending: false);

      final orders = ordersResponse as List;
      
      print('📦 Total orders fetched: ${orders.length}');
      if (orders.isNotEmpty) {
        print('📦 Sample order: ${orders[0]}');
        // Show all unique statuses
        final statuses = orders.map((o) => o['status']).toSet();
        print('📦 Unique statuses in database: $statuses');
      }

      // Calculate statistics (exclude cancelled orders)
      double dailySales = 0;
      int dailyCount = 0;
      double weeklySales = 0;
      int weeklyCount = 0;
      double monthlySales = 0;
      int monthlyCount = 0;
      double totalSales = 0;
      int totalCount = 0;

      // Map for last 7 days data
      Map<String, double> last7DaysData = {};
      for (int i = 0; i < 7; i++) {
        final date = today.subtract(Duration(days: 6 - i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        last7DaysData[dateKey] = 0.0;
      }

      for (var order in orders) {
        // Skip cancelled orders
        final status = order['status']?.toString().toLowerCase() ?? '';
        if (status == 'cancelled' || status == 'canceled') {
          continue;
        }

        final createdAt = DateTime.parse(order['created_at']);
        final amount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
        
        totalSales += amount;
        totalCount++;

        // Daily
        if (createdAt.year == today.year && 
            createdAt.month == today.month && 
            createdAt.day == today.day) {
          dailySales += amount;
          dailyCount++;
        }

        // Weekly
        if (createdAt.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))) {
          weeklySales += amount;
          weeklyCount++;
        }

        // Monthly
        if (createdAt.isAfter(startOfMonth.subtract(const Duration(seconds: 1)))) {
          monthlySales += amount;
          monthlyCount++;
        }

        // Last 7 days chart data
        if (createdAt.isAfter(last7Days.subtract(const Duration(seconds: 1)))) {
          final dateKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
          if (last7DaysData.containsKey(dateKey)) {
            last7DaysData[dateKey] = last7DaysData[dateKey]! + amount;
          }
        }
      }

      print('💰 Statistics calculated:');
      print('   Daily: Rp $dailySales ($dailyCount orders)');
      print('   Weekly: Rp $weeklySales ($weeklyCount orders)');
      print('   Monthly: Rp $monthlySales ($monthlyCount orders)');
      print('   Total: Rp $totalSales ($totalCount orders)');

      // Convert last 7 days data to chart format
      final chartData = last7DaysData.entries.map((e) => {
        'date': e.key,
        'sales': e.value,
      }).toList();

      return {
        'daily': {
          'sales': dailySales,
          'count': dailyCount,
        },
        'weekly': {
          'sales': weeklySales,
          'count': weeklyCount,
        },
        'monthly': {
          'sales': monthlySales,
          'count': monthlyCount,
        },
        'total': {
          'sales': totalSales,
          'count': totalCount,
        },
        'last_7_days': chartData,
      };
    } catch (e) {
      print('❌ Error loading statistics: $e');
      // Return safe defaults if query fails
      return {
        'daily': {'sales': 0.0, 'count': 0},
        'weekly': {'sales': 0.0, 'count': 0},
        'monthly': {'sales': 0.0, 'count': 0},
        'total': {'sales': 0.0, 'count': 0},
        'last_7_days': [],
      };
    }
  }
}
