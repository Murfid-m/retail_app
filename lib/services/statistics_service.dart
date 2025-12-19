import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class StatisticsService {
  /// Load statistics from the bundled JSON asset `data/dashboard_summary.json`.
  Future<Map<String, dynamic>> loadStatistics() async {
    try {
      final jsonStr = await rootBundle.loadString(
        'data/dashboard_summary.json',
      );
      final Map<String, dynamic> data =
          json.decode(jsonStr) as Map<String, dynamic>;

      // Normalize monthly trend
      final monthlyRaw = data['monthly_sales_trend'] as List<dynamic>? ?? [];
      final monthly = monthlyRaw
          .map<Map<String, dynamic>>(
            (e) => {
              'month': e['month'],
              'sales': (e['sales'] as num).toDouble(),
            },
          )
          .toList();

      // Build last 7 days data:
      // - If JSON already contains 'last_7_days', prefer and normalize it.
      // - Otherwise, approximate from the most recent monthly entry by
      //   evenly distributing that month's sales across its days and
      //   taking the last 7 calendar days of that month.
      List<Map<String, dynamic>> last7 = [];
      if (data.containsKey('last_7_days') && data['last_7_days'] is List) {
        final rawLast7 = data['last_7_days'] as List<dynamic>;
        for (var item in rawLast7) {
          try {
            final dateRaw = (item is Map && item['date'] != null) ? item['date'].toString() : item.toString();
            String isoDate;
            if (dateRaw.length == 10 && dateRaw[4] == '-' && dateRaw[7] == '-') {
              isoDate = dateRaw;
            } else if (dateRaw.length == 7 && dateRaw[4] == '-') {
              isoDate = '${dateRaw}-01';
            } else {
              isoDate = DateTime.now().toIso8601String().split('T').first;
            }

            final sales = (item is Map && item['sales'] != null) ? (item['sales'] as num).toDouble() : 0.0;
            last7.add({'date': isoDate, 'sales': sales});
          } catch (_) {
            // ignore malformed entries
          }
        }
      }

      if (last7.isEmpty) {
        // approximate using average per-day from the most recent monthly entry
        double avgPerDay = 0.0;
        if (monthly.isNotEmpty) {
          final lastMonth = monthly.last;
          final monthRaw = (lastMonth['month'] as String?) ?? '';
          int year = DateTime.now().year;
          int month = DateTime.now().month;
          try {
            final parts = monthRaw.split('-');
            if (parts.length >= 2) {
              year = int.parse(parts[0]);
              month = int.parse(parts[1]);
            }
          } catch (_) {}

          final daysInMonth = DateTime(year, month + 1, 1).subtract(const Duration(days: 1)).day;
          final monthSales = (lastMonth['sales'] as num).toDouble();
          avgPerDay = daysInMonth > 0 ? (monthSales / daysInMonth) : 0.0;
        }

        final today = DateTime.now();
        last7 = List.generate(7, (i) {
          final d = today.subtract(Duration(days: 6 - i));
          return {'date': d.toIso8601String().split('T').first, 'sales': avgPerDay};
        });
      }

      // Compute daily and weekly summaries from last7
      final todayStr = DateTime.now().toIso8601String().split('T').first;
      double dailySales = 0.0;
      double weeklySales = 0.0;
      int weeklyCount = 0;
      for (var item in last7) {
        final sales = (item['sales'] as num).toDouble();
        weeklySales += sales;
        if ((item['date'] as String) == todayStr) {
          dailySales = sales;
        }
      }
      weeklyCount = last7.length;

      // Try to infer monthly sales from monthly trend (if available)
      double monthlySales = 0.0;
      int monthlyCount = 0;
      final now = DateTime.now();
      final currentMonthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      for (var m in monthly) {
        if ((m['month'] as String).startsWith(currentMonthKey)) {
          monthlySales = (m['sales'] as num).toDouble();
          // count unknown in JSON; leave as 0
          monthlyCount = 0;
          break;
        }
      }

      return {
        'daily': {'sales': dailySales, 'count': 0},
        'weekly': {'sales': weeklySales, 'count': weeklyCount},
        'monthly': {'sales': monthlySales, 'count': monthlyCount},
        'total': {
          'sales': (data['total_sales'] as num?)?.toDouble() ?? 0.0,
          'count': 0,
        },
        'sales_by_category': data['sales_by_category'] ?? {},
        'top_products': data['top_products'] ?? [],
        'monthly_sales_trend': monthly,
        'last_7_days': last7,
      };
    } catch (e) {
      return {
        'total': {'sales': 0.0},
        'sales_by_category': {},
        'top_products': [],
        'monthly_sales_trend': [],
        'last_7_days': [],
      };
    }
  }
}
