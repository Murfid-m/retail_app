import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/statistics_service.dart';

class SeedDataDialog extends StatefulWidget {
  const SeedDataDialog({super.key});

  @override
  State<SeedDataDialog> createState() => _SeedDataDialogState();
}

class _SeedDataDialogState extends State<SeedDataDialog> {
  bool _isSeeding = false;
  bool _isDeleting = false;
  String _status = '';
  int _progress = 0;
  int _total = 0;

  Future<void> _deleteSeededData() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data Seed?'),
        content: const Text(
          'Ini akan menghapus semua data order testing yang di-seed sebelumnya.\n\n'
          'Data yang akan dihapus:\n'
          '• Orders dengan nama "Customer..."\n'
          '• Orders dengan nama "Sample..."\n'
          '• Orders dengan email "@example.com"\n\n'
          'Data order asli tidak akan terpengaruh.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isDeleting = true;
      _status = 'Menghapus data seed...';
    });

    try {
      final statisticsService = StatisticsService();
      final success = await statisticsService.deleteSeededData();

      if (success) {
        setState(() {
          _status = '✅ Data seed berhasil dihapus!';
          _isDeleting = false;
        });

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _status = '❌ Gagal menghapus data';
          _isDeleting = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error: $e';
        _isDeleting = false;
      });
    }
  }

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

      // Read dashboard_data.json (dataset lebih lengkap dengan daily_sales)
      setState(() => _status = 'Membaca data...');
      final jsonString = await rootBundle.loadString('data/dashboard_data.json');
      final jsonData = jsonDecode(jsonString);
      
      // Gunakan daily_sales untuk data yang lebih akurat
      final dailySales = jsonData['daily_sales'] as List;
      
      _total = dailySales.length + 25; // all daily data + recent data

      // Process daily sales data dari JSON (2015-2018)
      setState(() => _status = 'Membuat data historis dari daily_sales...');
      
      int batchCount = 0;
      for (var dayData in dailySales) {
        final date = dayData['date'] as String;
        final sales = (dayData['sales'] as num).toDouble();

        // Update status setiap 100 entries
        if (batchCount % 100 == 0) {
          setState(() {
            _status = 'Processing $date... (${batchCount}/${dailySales.length})';
            _progress = (batchCount * 48 / dailySales.length).round();
          });
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
    final isProcessing = _isSeeding || _isDeleting;
    
    return AlertDialog(
      title: const Text('Data Seed Statistik'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kelola data order dummy untuk testing statistik.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          
          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Data seed menggunakan daily_sales dari dashboard_data.json (2015-2018)',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          if (isProcessing) ...[
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
        if (!isProcessing)
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tutup'),
          ),
        if (!isProcessing && !_status.startsWith('✅')) ...[
          // Delete button
          OutlinedButton.icon(
            onPressed: _deleteSeededData,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Hapus Seed'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
          // Seed button
          ElevatedButton.icon(
            onPressed: _seedData,
            icon: const Icon(Icons.add_chart, size: 18),
            label: const Text('Seed Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC20E),
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ],
    );
  }
}
