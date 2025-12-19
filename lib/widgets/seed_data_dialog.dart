import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SeedDataDialog extends StatefulWidget {
  const SeedDataDialog({super.key});

  @override
  State<SeedDataDialog> createState() => _SeedDataDialogState();
}

class _SeedDataDialogState extends State<SeedDataDialog> {
  bool _isSeeding = false;
  String _status = '';
  int _progress = 0;
  int _total = 0;

  Future<void> _seedData() async {
    setState(() {
      _isSeeding = true;
      _status = 'Memulai seeding...';
      _progress = 0;
    });

    try {
      final supabase = Supabase.instance.client;

      // Get admin user
      setState(() => _status = 'Mengambil data admin...');
      final adminResponse = await supabase
          .from('users')
          .select()
          .eq('is_admin', true)
          .limit(1)
          .single();

      final userId = adminResponse['id'];

      // Read dashboard_summary.json
      setState(() => _status = 'Membaca data...');
      final jsonString = await rootBundle.loadString('data/dashboard_summary.json');
      final jsonData = jsonDecode(jsonString);
      final monthlyData = jsonData['monthly_sales_trend'] as List;

      _total = monthlyData.length + 25; // all months + current month + today

      // Process ALL historical data from JSON (2015-2018)
      setState(() => _status = 'Membuat data historis...');
      
      for (var monthData in monthlyData) {
        final month = monthData['month'] as String;
        final sales = (monthData['sales'] as num).toDouble();

        setState(() {
          _status = 'Processing $month...';
          _progress++;
        });

        // Generate 3-5 orders per month
        final orderCount = 4;
        final avgOrderValue = sales / orderCount;

        for (int i = 0; i < orderCount; i++) {
          final orderValue = avgOrderValue * (0.8 + (i * 0.2));
          final randomDay = (i * 28 / orderCount).round() + 1;

          await supabase.from('orders').insert({
            'user_id': userId,
            'user_name': 'Sample Customer ${_progress}-${i + 1}',
            'user_phone': '0812345678${(_progress * 10 + i) % 100}'.padRight(12, '0'),
            'user_email': 'customer${_progress}${i + 1}@example.com',
            'shipping_address': 'Jakarta, Indonesia',
            'total_amount': orderValue,
            'status': 'completed',
            'created_at': '$month-${randomDay.toString().padLeft(2, '0')}T${10 + i}:00:00Z',
          });
        }
      }

      // Add current month data
      setState(() => _status = 'Menambah data bulan ini...');
      final now = DateTime.now();
      for (int i = 0; i < 20; i++) {
        final daysAgo = i;
        final date = now.subtract(Duration(days: daysAgo));
        final amount = 50000.0 + (i * 10000);

        await supabase.from('orders').insert({
          'user_id': userId,
          'user_name': 'Customer Bulan Ini ${i + 1}',
          'user_phone': '0812345678${i % 100}'.padRight(12, '0'),
          'user_email': 'recent${i + 1}@example.com',
          'shipping_address': 'Jakarta, Indonesia',
          'total_amount': amount,
          'status': 'completed',
          'created_at': date.toIso8601String(),
        });

        setState(() => _progress++);
      }

      // Add today's data
      setState(() => _status = 'Menambah data hari ini...');
      for (int i = 0; i < 5; i++) {
        final amount = 75000.0 + (i * 25000);

        await supabase.from('orders').insert({
          'user_id': userId,
          'user_name': 'Customer Hari Ini ${i + 1}',
          'user_phone': '0812345678${i % 100}'.padRight(12, '0'),
          'user_email': 'today${i + 1}@example.com',
          'shipping_address': 'Jakarta, Indonesia',
          'total_amount': amount,
          'status': 'completed',
          'created_at': DateTime.now().subtract(Duration(hours: i)).toIso8601String(),
        });

        setState(() => _progress++);
      }

      setState(() {
        _status = '✅ Seeding selesai!';
        _isSeeding = false;
      });

      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isSeeding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Seed Data Statistik'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ini akan membuat data order dummy untuk testing statistik.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          if (_isSeeding) ...[
            LinearProgressIndicator(
              value: _total > 0 ? _progress / _total : null,
            ),
            const SizedBox(height: 12),
            Text(
              _status,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (_total > 0)
              Text(
                '$_progress / $_total',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
          ] else if (_status.startsWith('✅')) ...[
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(child: Text(_status)),
              ],
            ),
          ] else if (_status.startsWith('❌')) ...[
            Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _status,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        if (!_isSeeding)
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
        if (!_isSeeding && !_status.startsWith('✅'))
          ElevatedButton(
            onPressed: _seedData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC20E),
              foregroundColor: Colors.black,
            ),
            child: const Text('Mulai Seed'),
          ),
      ],
    );
  }
}
