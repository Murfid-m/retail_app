import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/order_provider.dart';
import '../../widgets/seed_data_dialog.dart';
import '../../widgets/skeleton_loading.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

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
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  Future<void> _showSeedDataDialog() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SeedDataDialog(),
    );

    if (result == true && mounted) {
      // Reload statistics after seeding
      Provider.of<OrderProvider>(context, listen: false).loadStatistics();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data berhasil di-seed! Statistik telah diperbarui.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, child) {
        if (orderProvider.isLoading) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI Cards skeleton
                Row(
                  children: [
                    Expanded(child: StatCardSkeleton()),
                    const SizedBox(width: 8),
                    Expanded(child: StatCardSkeleton()),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: StatCardSkeleton()),
                    const SizedBox(width: 8),
                    Expanded(child: StatCardSkeleton()),
                  ],
                ),
                const SizedBox(height: 24),
                // Chart section skeleton
                SkeletonLoading(width: double.infinity, height: 300, borderRadius: BorderRadius.circular(12)),
                const SizedBox(height: 24),
                SkeletonLoading(width: double.infinity, height: 300, borderRadius: BorderRadius.circular(12)),
              ],
            ),
          );
        }

        final stats = orderProvider.statistics;
        if (stats == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Gagal memuat statistik'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => orderProvider.loadStatistics(),
                  child: const Text('Coba Lagi'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _showSeedDataDialog,
                  icon: const Icon(Icons.dataset),
                  label: const Text('Seed Data Testing'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFC20E),
                    side: const BorderSide(color: Color(0xFFFFC20E)),
                  ),
                ),
              ],
            ),
          );
        }

        // Check if all stats are 0 - with safe access
        final dailySales = (stats['daily'] as Map?)?['sales'] ?? 0;
        final weeklySales = (stats['weekly'] as Map?)?['sales'] ?? 0;
        final monthlySales = (stats['monthly'] as Map?)?['sales'] ?? 0;
        final totalSales = (stats['total'] as Map?)?['sales'] ?? 0;
        
        final isAllZero = dailySales == 0 && weeklySales == 0 && monthlySales == 0 && totalSales == 0;
        
        print('🔍 Stats check: daily=$dailySales, weekly=$weeklySales, monthly=$monthlySales, total=$totalSales, isAllZero=$isAllZero');

        return RefreshIndicator(
          onRefresh: () => orderProvider.loadStatistics(),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Custom AppBar with margin
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC20E),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Statistik',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.dataset, color: Colors.black),
                        tooltip: 'Seed Data Testing',
                        onPressed: _showSeedDataDialog,
                      ),
                    ],
                  ),
                ),
                
                // Content with horizontal padding
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Seed data button if stats are 0
                      if (isAllZero)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.info_outline, color: Colors.orange, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                'Belum ada data statistik',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Gunakan data testing untuk melihat contoh statistik',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _showSeedDataDialog,
                                icon: const Icon(Icons.dataset),
                                label: const Text('Seed Data Testing'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFC20E),
                                  foregroundColor: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Date range filter
                      _buildDateRangeFilter(orderProvider),
                      const SizedBox(height: 16),
                      
                      // Statistics cards
                      _buildStatisticsCards(stats),
                      const SizedBox(height: 24),

                      // Sales chart
                      _buildSalesChart(orderProvider.chartData, orderProvider.statistics),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart(List<Map<String, dynamic>> chartData, Map<String, dynamic>? stats) {
    if (chartData.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: Text('Tidak ada data untuk ditampilkan')),
        ),
      );
    }

    final maxSales = chartData
        .map((e) => (e['sales'] as double))
        .reduce((a, b) => a > b ? a : b);

    // Determine chart title based on grouping type
    final groupingType = stats?['chart_grouping'] ?? 'daily';
    final dateRange = stats?['date_range'];
    String chartTitle;
    
    if (dateRange != null) {
      final start = DateTime.parse(dateRange['start']);
      final end = DateTime.parse(dateRange['end']);
      if (groupingType == 'monthly') {
        chartTitle = 'Penjualan Bulanan (${DateFormat('MMM yyyy').format(start)} - ${DateFormat('MMM yyyy').format(end)})';
      } else if (groupingType == 'weekly') {
        chartTitle = 'Penjualan Mingguan (${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)})';
      } else {
        chartTitle = 'Penjualan Harian (${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)})';
      }
    } else {
      chartTitle = 'Penjualan 7 Hari Terakhir';
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    chartTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (groupingType != 'daily')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC20E).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      groupingType == 'monthly' ? 'Per Bulan' : 'Per Minggu',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ),
              ],
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
                        final label = chartData[group.x.toInt()]['date'] as String;
                        return BarTooltipItem(
                          '$label\nRp ${_formatPrice(rod.toY)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
                            String label;
                            
                            if (groupingType == 'monthly') {
                              // Format: 2018-01 -> Jan'18
                              final parts = dateStr.split('-');
                              final month = int.parse(parts[1]);
                              final year = parts[0].substring(2);
                              final monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
                              label = "${monthNames[month]}'$year";
                            } else if (groupingType == 'weekly') {
                              // Format: 2018-W01 -> W01
                              label = dateStr.split('-').last;
                            } else {
                              // Format: 2018-01-15 -> 15/01
                              final date = DateTime.parse(dateStr);
                              label = DateFormat('dd/MM').format(date);
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                label,
                                style: const TextStyle(
                                  fontSize: 9,
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
                          width: chartData.length > 20 ? 8 : (chartData.length > 10 ? 12 : 20),
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
            
            // Quick select buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickSelectChip('7 Hari', () {
                  final end = DateTime.now();
                  final start = end.subtract(const Duration(days: 6));
                  provider.setStatsDateRange(start, end);
                }),
                _buildQuickSelectChip('30 Hari', () {
                  final end = DateTime.now();
                  final start = end.subtract(const Duration(days: 29));
                  provider.setStatsDateRange(start, end);
                }),
                _buildQuickSelectChip('Bulan Ini', () {
                  final now = DateTime.now();
                  final start = DateTime(now.year, now.month, 1);
                  final end = now;
                  provider.setStatsDateRange(start, end);
                }),
                _buildQuickSelectChip('Bulan Lalu', () {
                  final now = DateTime.now();
                  final lastMonth = DateTime(now.year, now.month - 1, 1);
                  final lastMonthEnd = DateTime(now.year, now.month, 0);
                  provider.setStatsDateRange(lastMonth, lastMonthEnd);
                }),
                _buildQuickSelectChip('Tahun Ini', () {
                  final now = DateTime.now();
                  final start = DateTime(now.year, 1, 1);
                  final end = now;
                  provider.setStatsDateRange(start, end);
                }),
                _buildQuickSelectChip('2018', () {
                  provider.setStatsDateRange(DateTime(2018, 1, 1), DateTime(2018, 12, 31));
                }),
                _buildQuickSelectChip('2017', () {
                  provider.setStatsDateRange(DateTime(2017, 1, 1), DateTime(2017, 12, 31));
                }),
                _buildQuickSelectChip('2016', () {
                  provider.setStatsDateRange(DateTime(2016, 1, 1), DateTime(2016, 12, 31));
                }),
                _buildQuickSelectChip('2015', () {
                  provider.setStatsDateRange(DateTime(2015, 1, 1), DateTime(2015, 12, 31));
                }),
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
                label: const Text('Pilih Rentang Custom'),
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

  Widget _buildQuickSelectChip(String label, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker(BuildContext context, OrderProvider provider) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015, 1, 1), // Support data dari 2015
      lastDate: DateTime.now(),
      currentDate: DateTime.now(), // Untuk navigasi hari ini
      initialDateRange: provider.statsStartDate != null && provider.statsEndDate != null
          ? DateTimeRange(
              start: provider.statsStartDate!,
              end: provider.statsEndDate!,
            )
          : null,
      initialEntryMode: DatePickerEntryMode.calendarOnly, // Fokus ke kalender
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFFC20E),
              onPrimary: Colors.black,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFFC20E),
              ),
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
