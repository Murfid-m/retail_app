import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/order_provider.dart';
import 'order_management_screen.dart';

class StatisticsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToOrders;
  
  const StatisticsScreen({super.key, this.onNavigateToOrders});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<OrderProvider>(context, listen: false).loadStatistics();
    });
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _navigateToOrdersWithFilter(String period) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    switch (period) {
      case 'Hari Ini':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Minggu Ini':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        endDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Bulan Ini':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month, now.day);
        break;
      case 'Total':
        // Clear all filters for total view
        orderProvider.clearFilters();
        break;
    }

    // Apply filter only if not Total
    if (period != 'Total') {
      if (startDate != null && endDate != null) {
        orderProvider.filterByDateRange(startDate, endDate);
      } else {
        orderProvider.filterByDateRange(null, null);
      }
    }

    // Show feedback message
    String message = 'Menampilkan pesanan ';
    switch (period) {
      case 'Hari Ini':
        message += 'hari ini (${DateFormat('dd MMM yyyy').format(DateTime.now())})';
        break;
      case 'Minggu Ini':
        message += 'minggu ini';
        break;
      case 'Bulan Ini':
        message += 'bulan ini (${DateFormat('MMMM yyyy').format(DateTime.now())})';
        break;
      case 'Total':
        message += 'keseluruhan';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 2),
      ),
    );

    // Switch to Order Management tab
    if (widget.onNavigateToOrders != null) {
      // Delay navigation to allow snackbar to show
      Future.delayed(const Duration(milliseconds: 1500), () {
        widget.onNavigateToOrders!();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = orderProvider.statistics;
        if (stats == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Gagal memuat statistik'),
                ElevatedButton(
                  onPressed: () => orderProvider.loadStatistics(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => orderProvider.loadStatistics(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date range filter
                _buildDateRangeFilter(orderProvider),
                const SizedBox(height: 16),
                
                // Statistics cards
                _buildStatisticsCards(stats),
                const SizedBox(height: 24),

                // Sales chart
                _buildSalesChart(orderProvider.chartData),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsCards(Map<String, dynamic> stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Hari Ini',
                'Rp ${_formatPrice(stats['daily']['sales'])}',
                '${stats['daily']['count']} pesanan',
                Colors.blue,
                Icons.today,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Minggu Ini',
                'Rp ${_formatPrice(stats['weekly']['sales'])}',
                '${stats['weekly']['count']} pesanan',
                Colors.green,
                Icons.date_range,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Bulan Ini',
                'Rp ${_formatPrice(stats['monthly']['sales'])}',
                '${stats['monthly']['count']} pesanan',
                Colors.orange,
                Icons.calendar_month,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total',
                'Rp ${_formatPrice(stats['total']['sales'])}',
                '${stats['total']['count']} pesanan',
                Colors.purple,
                Icons.all_inclusive,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToOrdersWithFilter(title),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
              ),
              const SizedBox(height: 12),
              Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              ),
              const SizedBox(height: 4),
              Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              ),
              const SizedBox(height: 8),
              Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Colors.grey[400],
                ),
              ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesChart(List<Map<String, dynamic>> chartData) {
    if (chartData.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('Tidak ada data untuk ditampilkan'),
          ),
        ),
      );
    }

    final maxSales = chartData
        .map((e) => (e['sales'] as double))
        .reduce((a, b) => a > b ? a : b);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Penjualan 7 Hari Terakhir',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxSales > 0 ? maxSales * 1.2 : 100,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          'Rp ${_formatPrice(rod.toY)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < chartData.length) {
                            final dateStr = chartData[index]['date'] as String;
                            final date = DateTime.parse(dateStr);
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                DateFormat('dd/MM').format(date),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatCompactPrice(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxSales > 0 ? maxSales / 5 : 20,
                  ),
                  barGroups: chartData.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value['sales'] as double,
                          color: const Color(0xFFFFC20E),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCompactPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}K';
    }
    return price.toStringAsFixed(0);
  }

  Widget _buildDateRangeFilter(OrderProvider provider) {
    final hasDateRange = provider.statsStartDate != null && provider.statsEndDate != null;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.date_range, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Filter Tanggal',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (hasDateRange)
                  TextButton.icon(
                    onPressed: () => provider.clearStatsDateRange(),
                    icon: const Icon(Icons.clear, size: 18),
                    label: const Text('Reset'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasDateRange)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC20E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFC20E)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Color(0xFFFFC20E)),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(provider.statsStartDate!)} - ${DateFormat('dd MMM yyyy').format(provider.statsEndDate!)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              )
            else
              const Text(
                'Menampilkan data keseluruhan',
                style: TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showDateRangePicker(context, provider),
                icon: const Icon(Icons.calendar_month),
                label: const Text('Pilih Rentang Tanggal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC20E),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context, OrderProvider provider) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: provider.statsStartDate != null && provider.statsEndDate != null
          ? DateTimeRange(
              start: provider.statsStartDate!,
              end: provider.statsEndDate!,
            )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFFC20E),
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.setStatsDateRange(picked.start, picked.end);
    }
  }
}
