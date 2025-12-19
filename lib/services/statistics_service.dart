<<<<<<< HEAD
=======
import 'package:supabase_flutter/supabase_flutter.dart';

class StatisticsService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> loadStatistics() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);
      final last7Days = today.subtract(const Duration(days: 6));

      // Get all completed orders
      final ordersResponse = await _supabase
          .from('orders')
          .select('created_at, total_amount')
          .eq('status', 'completed')
          .order('created_at', ascending: false);

      final orders = ordersResponse as List;

      // Calculate statistics
      double dailySales = 0;
      int dailyCount = 0;
      double weeklySales = 0;
      int weeklyCount = 0;
      double monthlySales = 0;
      int monthlyCount = 0;
      double totalSales = 0;
      int totalCount = orders.length;

      // Map for last 7 days data
      Map<String, double> last7DaysData = {};
      for (int i = 0; i < 7; i++) {
        final date = today.subtract(Duration(days: 6 - i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        last7DaysData[dateKey] = 0.0;
      }

      for (var order in orders) {
        final createdAt = DateTime.parse(order['created_at']);
        final amount = (order['total_amount'] as num).toDouble();
        totalSales += amount;

        // Daily
        if (createdAt.isAfter(today) || createdAt.isAtSameMomentAs(today)) {
          dailySales += amount;
          dailyCount++;
        }

        // Weekly
        if (createdAt.isAfter(startOfWeek) || createdAt.isAtSameMomentAs(startOfWeek)) {
          weeklySales += amount;
          weeklyCount++;
        }

        // Monthly
        if (createdAt.isAfter(startOfMonth) || createdAt.isAtSameMomentAs(startOfMonth)) {
          monthlySales += amount;
          monthlyCount++;
        }

        // Last 7 days chart data
        if (createdAt.isAfter(last7Days) || createdAt.isAtSameMomentAs(last7Days)) {
          final dateKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
          if (last7DaysData.containsKey(dateKey)) {
            last7DaysData[dateKey] = last7DaysData[dateKey]! + amount;
          }
        }
      }

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
>>>>>>> 878bf85fb47f9b9651b9855eb86a538a5ca64b9b
