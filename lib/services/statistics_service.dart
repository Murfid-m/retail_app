import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

class StatisticsService {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> loadStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      print('📊 StatisticsService: Loading statistics...');

      // First try to load local seeded JSON for admin dashboard if available
      try {
        final jsonString = await rootBundle.loadString(
          'data/admin_statistic_dashboard.json',
        );
        final Map<String, dynamic> jsonData =
            json.decode(jsonString) as Map<String, dynamic>;
        print('📁 Loaded local admin_statistic_dashboard.json');

        final summary = jsonData['summary_cards'] ?? {};
        final today = summary['today'] ?? {};
        final thisWeek = summary['this_week'] ?? {};
        final thisMonth = summary['this_month'] ?? {};
        final allTime = summary['all_time'] ?? {};

        final rawLast7 = jsonData['daily_sales_last_7_days'] as List<dynamic>?;
        final last7 = (rawLast7 ?? [])
            .map(
              (e) => {
                'date': e['date'],
                'sales': (e['sales'] is num)
                    ? (e['sales'] as num).toDouble()
                    : 0.0,
              },
            )
            .toList();

        return {
          'daily': {
            'sales': (today['total_sales'] as num?)?.toDouble() ?? 0.0,
            'count': (today['total_orders'] as int?) ?? 0,
          },
          'weekly': {
            'sales': (thisWeek['total_sales'] as num?)?.toDouble() ?? 0.0,
            'count': (thisWeek['total_orders'] as int?) ?? 0,
          },
          'monthly': {
            'sales': (thisMonth['total_sales'] as num?)?.toDouble() ?? 0.0,
            'count': (thisMonth['total_orders'] as int?) ?? 0,
          },
          'total': {
            'sales': (allTime['total_sales'] as num?)?.toDouble() ?? 0.0,
            'count': (allTime['total_orders'] as int?) ?? 0,
          },
          'last_7_days': last7,
        };
      } catch (e) {
        // If asset not present or fails to parse, continue to load from Supabase
        print('📁 No local admin JSON asset found or failed to parse: $e');
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      print('📅 Today: $today');
      print('📅 Week start: $startOfWeek');
      print('📅 Month start: $startOfMonth');

      // Get all orders (not just completed)
      var query = _supabase
          .from('orders')
          .select('created_at, total_amount, status');

      // Apply date range if provided
      DateTime? filterStart = startDate;
      DateTime? filterEnd = endDate;

      if (filterStart != null && filterEnd != null) {
        final start = DateTime(
          filterStart.year,
          filterStart.month,
          filterStart.day,
        );
        final end = DateTime(
          filterEnd.year,
          filterEnd.month,
          filterEnd.day,
          23,
          59,
          59,
        );
        query = query
            .gte('created_at', start.toIso8601String())
            .lte('created_at', end.toIso8601String());
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

      // Determine chart date range
      DateTime chartStartDate;
      DateTime chartEndDate;

      if (filterStart != null && filterEnd != null) {
        // Use custom date range for chart
        chartStartDate = filterStart;
        chartEndDate = filterEnd;
      } else {
        // Default: last 7 days
        chartStartDate = today.subtract(const Duration(days: 6));
        chartEndDate = today;
      }

      // Calculate number of days in range
      final daysDifference = chartEndDate.difference(chartStartDate).inDays + 1;

      // Map for chart data
      Map<String, double> chartDataMap = {};

      // Determine grouping based on range
      // < 31 days: daily
      // 31-90 days: weekly
      // > 90 days: monthly
      String groupingType = 'daily';
      if (daysDifference > 90) {
        groupingType = 'monthly';
      } else if (daysDifference > 31) {
        groupingType = 'weekly';
      }

      print('📊 Chart grouping: $groupingType for $daysDifference days');

      // Initialize chart data based on grouping
      if (groupingType == 'daily') {
        for (int i = 0; i < daysDifference && i < 31; i++) {
          final date = chartStartDate.add(Duration(days: i));
          final dateKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          chartDataMap[dateKey] = 0.0;
        }
      } else if (groupingType == 'weekly') {
        // Create weekly buckets
        DateTime weekStart = chartStartDate;
        while (weekStart.isBefore(chartEndDate) ||
            weekStart.isAtSameMomentAs(chartEndDate)) {
          final weekKey =
              '${weekStart.year}-W${_getWeekNumber(weekStart).toString().padLeft(2, '0')}';
          chartDataMap[weekKey] = 0.0;
          weekStart = weekStart.add(const Duration(days: 7));
        }
      } else {
        // Monthly buckets
        DateTime monthStart = DateTime(
          chartStartDate.year,
          chartStartDate.month,
          1,
        );
        final endMonth = DateTime(chartEndDate.year, chartEndDate.month, 1);
        while (monthStart.isBefore(endMonth) ||
            monthStart.isAtSameMomentAs(endMonth)) {
          final monthKey =
              '${monthStart.year}-${monthStart.month.toString().padLeft(2, '0')}';
          chartDataMap[monthKey] = 0.0;
          monthStart = DateTime(monthStart.year, monthStart.month + 1, 1);
        }
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

        // Daily (only if no custom filter)
        if (filterStart == null && filterEnd == null) {
          if (createdAt.year == today.year &&
              createdAt.month == today.month &&
              createdAt.day == today.day) {
            dailySales += amount;
            dailyCount++;
          }

          // Weekly
          if (createdAt.isAfter(
            startOfWeek.subtract(const Duration(seconds: 1)),
          )) {
            weeklySales += amount;
            weeklyCount++;
          }

          // Monthly
          if (createdAt.isAfter(
            startOfMonth.subtract(const Duration(seconds: 1)),
          )) {
            monthlySales += amount;
            monthlyCount++;
          }
        }

        // Add to chart data based on grouping
        if (groupingType == 'daily') {
          final dateKey =
              '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
          if (chartDataMap.containsKey(dateKey)) {
            chartDataMap[dateKey] = chartDataMap[dateKey]! + amount;
          }
        } else if (groupingType == 'weekly') {
          final weekKey =
              '${createdAt.year}-W${_getWeekNumber(createdAt).toString().padLeft(2, '0')}';
          if (chartDataMap.containsKey(weekKey)) {
            chartDataMap[weekKey] = chartDataMap[weekKey]! + amount;
          }
        } else {
          final monthKey =
              '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
          if (chartDataMap.containsKey(monthKey)) {
            chartDataMap[monthKey] = chartDataMap[monthKey]! + amount;
          }
        }
      }

      // If custom range, use total as daily/weekly/monthly
      if (filterStart != null && filterEnd != null) {
        dailySales = totalSales;
        dailyCount = totalCount;
        weeklySales = totalSales;
        weeklyCount = totalCount;
        monthlySales = totalSales;
        monthlyCount = totalCount;
      }

      print('💰 Statistics calculated:');
      print('   Daily: Rp $dailySales ($dailyCount orders)');
      print('   Weekly: Rp $weeklySales ($weeklyCount orders)');
      print('   Monthly: Rp $monthlySales ($monthlyCount orders)');
      print('   Total: Rp $totalSales ($totalCount orders)');

      // Convert chart data to list format
      final chartData = chartDataMap.entries
          .map((e) => {'date': e.key, 'sales': e.value})
          .toList();

      return {
        'daily': {'sales': dailySales, 'count': dailyCount},
        'weekly': {'sales': weeklySales, 'count': weeklyCount},
        'monthly': {'sales': monthlySales, 'count': monthlyCount},
        'total': {'sales': totalSales, 'count': totalCount},
        'last_7_days': chartData,
        'chart_grouping': groupingType,
        'date_range': filterStart != null
            ? {
                'start': filterStart.toIso8601String(),
                'end': filterEnd?.toIso8601String(),
              }
            : null,
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
        'chart_grouping': 'daily',
      };
    }
  }

  // Load top selling products
  Future<List<Map<String, dynamic>>> loadTopProducts({
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    try {
      print('📊 Loading top products...');

      // Get all orders with items
      var query = _supabase
          .from('orders')
          .select(
            'order_items(product_id, product_name, quantity, price), created_at, status',
          );

      // Apply date range if provided
      if (startDate != null && endDate != null) {
        final start = DateTime(startDate.year, startDate.month, startDate.day);
        final end = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          23,
          59,
          59,
        );
        query = query
            .gte('created_at', start.toIso8601String())
            .lte('created_at', end.toIso8601String());
      }

      final ordersResponse = await query;
      final orders = ordersResponse as List;

      // Aggregate product sales
      Map<String, Map<String, dynamic>> productSales = {};

      for (var order in orders) {
        // Skip cancelled orders
        final status = order['status']?.toString().toLowerCase() ?? '';
        if (status == 'cancelled' || status == 'canceled') {
          continue;
        }

        final items = order['order_items'] as List? ?? [];
        for (var item in items) {
          final productId = item['product_id'] as String? ?? 'unknown';
          final productName =
              item['product_name'] as String? ?? 'Unknown Product';
          final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
          final price = (item['price'] as num?)?.toDouble() ?? 0.0;

          if (productSales.containsKey(productId)) {
            productSales[productId]!['quantity'] += quantity;
            productSales[productId]!['revenue'] += price * quantity;
          } else {
            productSales[productId] = {
              'product_id': productId,
              'product_name': productName,
              'quantity': quantity,
              'revenue': price * quantity,
            };
          }
        }
      }

      // Sort by quantity sold and get top N
      final sortedProducts = productSales.values.toList()
        ..sort(
          (a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int),
        );

      return sortedProducts.take(limit).toList();
    } catch (e) {
      print('❌ Error loading top products: $e');
      return [];
    }
  }

  // Helper to get ISO week number
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDayOfYear).inDays;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  // Delete all seeded test data
  Future<bool> deleteSeededData() async {
    try {
      print('🗑️ Deleting seeded data...');

      // Delete orders that have [SEED] prefix in user_name (unique identifier for seeded data)
      await _supabase.from('orders').delete().like('user_name', '[SEED]%');

      print('✅ Seeded data deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting seeded data: $e');
      return false;
    }
  }
}
