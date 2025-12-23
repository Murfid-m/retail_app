import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../widgets/skeleton_loading.dart';

// Conditional imports for platform-specific file saving
import 'export_helper_stub.dart'
    if (dart.library.html) 'export_helper_web.dart'
    if (dart.library.io) 'export_helper_io.dart' as export_helper;

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _statusOptions = [
    'Semua Status',
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<OrderProvider>(context, listen: false).loadAllOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }
  
  void _applyDateFilterPreservingStatus(OrderProvider orderProvider, DateTime startDate, DateTime endDate) {
    // Apply date filter without resetting status filter
    orderProvider.filterByDateRange(startDate, endDate);
    
    // Show confirmation with combined filter info
    String message = 'Filter diterapkan: ${DateFormat('dd MMM yyyy').format(startDate)}';
    if (startDate != endDate) {
      message = 'Filter diterapkan: ${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}';
    }
    
    if (orderProvider.selectedStatuses.isNotEmpty) {
      final statusLabels = orderProvider.selectedStatuses
          .map((status) => _getStatusLabel(status))
          .toList();
      message += ' + Status: ${statusLabels.join(', ')}';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green[600],
      ),
    );
  }
  
  void _exportOrders(OrderProvider orderProvider) {
    final orders = orderProvider.orders;
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data pesanan untuk di-export')),
      );
      return;
    }
    
    // Show export options dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.file_download, color: Color(0xFFFFC20E)),
            SizedBox(width: 8),
            Text('Export Data Pesanan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${orders.length} pesanan akan di-export.',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih format export:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            // CSV to Clipboard Option
            _buildExportOption(
              icon: Icons.content_copy,
              title: 'Copy ke Clipboard',
              subtitle: 'Salin data CSV ke clipboard untuk paste di Excel/Spreadsheet',
              onTap: () {
                Navigator.pop(context);
                _exportToClipboard(orders);
              },
            ),
            const SizedBox(height: 12),
            // Download CSV File Option
            _buildExportOption(
              icon: Icons.download,
              title: 'Download File CSV',
              subtitle: 'Simpan sebagai file .csv yang bisa dibuka di Excel',
              onTap: () {
                Navigator.pop(context);
                _exportToFile(orders);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC20E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFFFFC20E)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
  
  String _generateCsvContent(List<OrderModel> orders) {
    // BOM for Excel UTF-8 compatibility
    const bom = '\uFEFF';
    
    // CSV Header
    StringBuffer csv = StringBuffer();
    csv.write(bom);
    csv.writeln('Order ID,Nama Customer,Email,Telepon,Alamat,Status,Total (Rp),Tanggal Order');
    
    // CSV Data
    for (var order in orders) {
      final escapedName = order.userName.replaceAll('"', '""');
      final escapedEmail = order.userEmail.replaceAll('"', '""');
      final escapedAddress = order.shippingAddress.replaceAll('"', '""');
      
      csv.writeln(
        '"${order.id}",'
        '"$escapedName",'
        '"$escapedEmail",'
        '"${order.userPhone}",'
        '"$escapedAddress",'
        '"${_getStatusLabel(order.status)}",'
        '"${order.totalAmount.toStringAsFixed(0)}",'
        '"${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}"'
      );
    }
    
    return csv.toString();
  }
  
  void _exportToClipboard(List<OrderModel> orders) {
    final csvContent = _generateCsvContent(orders);
    Clipboard.setData(ClipboardData(text: csvContent));
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${orders.length} pesanan berhasil di-copy!\nPaste di Excel/Google Sheets.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  Future<void> _exportToFile(List<OrderModel> orders) async {
    try {
      final csvContent = _generateCsvContent(orders);
      final now = DateTime.now();
      final fileName = 'pesanan_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv';
      
      // Use platform-specific export helper
      final result = await export_helper.saveFile(fileName, csvContent);
      
      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('File berhasil disimpan!'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result['path'] ?? (kIsWeb ? 'File di-download ke folder Downloads' : ''),
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              backgroundColor: Colors.green[600],
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          throw Exception(result['error'] ?? 'Unknown error');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSearchAndFilter(OrderProvider orderProvider) {
    return Column(
      children: [
        // Header with Export Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Manajemen Pesanan',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _exportOrders(orderProvider),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
        
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Cari pesanan...',
            leading: const Icon(Icons.search),
            trailing: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    orderProvider.searchOrders('');
                  },
                ),
            ],
            onChanged: (value) {
              orderProvider.searchOrders(value);
            },
          ),
        ),

        // Status Filter
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ..._statusOptions.map((status) {
                return _buildStatusChip(status, orderProvider);
              }).toList(),
              const SizedBox(width: 8),
              // Quick date filters
              _buildQuickFilterChip('Hari ini', () {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                _applyDateFilterPreservingStatus(orderProvider, today, today);
              }, orderProvider),
              const SizedBox(width: 8),
              _buildQuickFilterChip('Minggu ini', () {
                final now = DateTime.now();
                final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
                final end = DateTime(now.year, now.month, now.day);
                _applyDateFilterPreservingStatus(orderProvider, start, end);
              }, orderProvider),
              const SizedBox(width: 8),
              _buildQuickFilterChip('Bulan ini', () {
                final now = DateTime.now();
                final start = DateTime(now.year, now.month, 1);
                final end = DateTime(now.year, now.month, now.day);
                _applyDateFilterPreservingStatus(orderProvider, start, end);
              }, orderProvider),
              const SizedBox(width: 8),
              // Date range filter
              _buildDateRangeChip(orderProvider),
              const SizedBox(width: 8),
              // Clear all filters button at the end
              _buildClearAllFiltersChip(orderProvider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, OrderProvider orderProvider) {
    final isSelected = (status == 'Semua Status' && orderProvider.selectedStatuses.isEmpty) ||
        orderProvider.selectedStatuses.contains(status.toLowerCase());

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(_getStatusLabel(status)),
        selected: isSelected,
        selectedColor: Theme.of(context).primaryColor,
        checkmarkColor: Colors.white,
        onSelected: (selected) {
          if (status == 'Semua Status') {
            orderProvider.filterByStatus(null); // Clear all status filters
          } else {
            orderProvider.toggleStatusFilter(status.toLowerCase());
          }
        },
      ),
    );
  }

  Widget _buildDateRangeChip(OrderProvider orderProvider) {
    final hasDateFilter = orderProvider.startDate != null || orderProvider.endDate != null;
    
    String label = 'Filter Tanggal';
    if (hasDateFilter) {
      final startDate = orderProvider.startDate!;
      final endDate = orderProvider.endDate!;
      if (startDate.year == endDate.year && 
          startDate.month == endDate.month && 
          startDate.day == endDate.day) {
        label = DateFormat('dd MMM yyyy').format(startDate);
      } else {
        label = '${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}';
      }
    }
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.date_range, size: 16, color: hasDateFilter ? Colors.white : null),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: hasDateFilter ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
      selected: hasDateFilter,
      selectedColor: Theme.of(context).primaryColor,
      onSelected: (selected) {
        if (selected) {
          _showDateFilterOptions(orderProvider);
        } else {
          orderProvider.filterByDateRange(null, null);
        }
      },
    );
  }

  Widget _buildClearAllFiltersChip(OrderProvider orderProvider) {
    final hasActiveFilters = orderProvider.startDate != null || 
                           orderProvider.endDate != null || 
                           orderProvider.selectedStatuses.isNotEmpty || 
                           orderProvider.searchQuery.isNotEmpty;
    
    return ActionChip(
      label: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.clear_all, size: 14),
          SizedBox(width: 4),
          Text('Dibatalkan', style: TextStyle(fontSize: 12)),
        ],
      ),
      onPressed: hasActiveFilters ? () {
        orderProvider.clearFilters();
        _searchController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua filter telah dibatalkan'),
            duration: Duration(seconds: 1),
          ),
        );
      } : null,
      backgroundColor: hasActiveFilters ? Colors.red[50] : Colors.grey[100],
      side: BorderSide(color: hasActiveFilters ? Colors.red[200]! : Colors.grey[300]!),
      labelStyle: TextStyle(
        color: hasActiveFilters ? Colors.red[700] : Colors.grey[500],
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, VoidCallback onPressed, OrderProvider orderProvider) {
    bool isActive = _isQuickFilterActive(label, orderProvider);
    
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          color: isActive ? Colors.white : null,
        ),
      ),
      onPressed: onPressed,
      backgroundColor: isActive ? Theme.of(context).primaryColor : Colors.grey[100],
      side: BorderSide(
        color: isActive ? Theme.of(context).primaryColor : Colors.grey[300]!,
      ),
    );
  }
  
  bool _isQuickFilterActive(String label, OrderProvider orderProvider) {
    if (orderProvider.startDate == null || orderProvider.endDate == null) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (label) {
      case 'Hari ini':
        return orderProvider.startDate!.isAtSameMomentAs(today) && 
               orderProvider.endDate!.isAtSameMomentAs(today);
      case 'Minggu ini':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return orderProvider.startDate!.isAtSameMomentAs(start) && 
               orderProvider.endDate!.isAtSameMomentAs(today);
      case 'Bulan ini':
        final start = DateTime(now.year, now.month, 1);
        return orderProvider.startDate!.isAtSameMomentAs(start) && 
               orderProvider.endDate!.isAtSameMomentAs(today);
      default:
        return false;
    }
  }



  String _getStatusLabel(String status) {
    switch (status) {
      case 'Semua Status':
        return 'Semua Status';
      case 'pending':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      case 'shipped':
        return 'Dikirim';
      case 'delivered':
        return 'Terkirim';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Widget _buildOrdersSummary(OrderProvider orderProvider) {
    final orders = orderProvider.orders;
    if (orders.isEmpty) return const SizedBox.shrink();
    
    final totalRevenue = orders.fold<double>(0, (sum, order) => sum + order.totalAmount);
    final pendingCount = orders.where((o) => o.status == 'pending').length;
    final processingCount = orders.where((o) => o.status == 'processing').length;
    final completedCount = orders.where((o) => o.status == 'delivered').length;
    
    List<String> activeFilters = [];
    
    // Add status filter info
    if (orderProvider.selectedStatuses.isNotEmpty) {
      final statusLabels = orderProvider.selectedStatuses
          .map((status) => _getStatusLabel(status))
          .toList();
      if (statusLabels.length == 1) {
        activeFilters.add('Status: ${statusLabels.first}');
      } else {
        activeFilters.add('Status: ${statusLabels.join(', ')}');
      }
    }
    
    // Add date filter info
    if (orderProvider.startDate != null && orderProvider.endDate != null) {
      final startDate = orderProvider.startDate!;
      final endDate = orderProvider.endDate!;
      if (startDate.year == endDate.year && 
          startDate.month == endDate.month && 
          startDate.day == endDate.day) {
        activeFilters.add('Tanggal: ${DateFormat('dd MMM yyyy').format(startDate)}');
      } else {
        activeFilters.add('Periode: ${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}');
      }
    }
    
    // Add search filter info
    if (orderProvider.searchQuery.isNotEmpty) {
      activeFilters.add('Pencarian: \"${orderProvider.searchQuery}\"');
    }
    
    String summaryText = '${orders.length} pesanan';
    if (activeFilters.isNotEmpty) {
      summaryText += ' dengan filter: ${activeFilters.join(', ')}';
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summaryText,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Total Revenue', 
                  'Rp ${_formatPrice(totalRevenue)}', 
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Menunggu', 
                  '$pendingCount', 
                  Icons.pending,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Diproses', 
                  '$processingCount', 
                  Icons.autorenew,
                  Colors.blue,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Selesai', 
                  '$completedCount', 
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
 
  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        // Icon(icon, color: color, size: 20), // Ikon dihilangkan
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Future<void> _showDateFilterOptions(OrderProvider orderProvider) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Filter Tanggal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.today),
              title: const Text('Pilih Satu Tanggal'),
              subtitle: const Text('Filter pesanan untuk hari tertentu'),
              onTap: () {
                Navigator.pop(context);
                _showSingleDatePicker(orderProvider);
              },
            ),
            ListTile(
              leading: const Icon(Icons.date_range),
              title: const Text('Pilih Rentang Tanggal'),
              subtitle: const Text('Filter pesanan dari tanggal A ke tanggal B'),
              onTap: () {
                Navigator.pop(context);
                _showDateRangePicker(orderProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSingleDatePicker(OrderProvider orderProvider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: orderProvider.startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      helpText: 'PILIH TANGGAL',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Set same date for start and end to filter single day
      orderProvider.filterByDateRange(picked, picked);
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Filter diterapkan untuk: ${DateFormat('dd MMM yyyy').format(picked)}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _showDateRangePicker(OrderProvider orderProvider) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: orderProvider.startDate != null && orderProvider.endDate != null
          ? DateTimeRange(start: orderProvider.startDate!, end: orderProvider.endDate!)
          : null,
      helpText: 'PILIH RENTANG TANGGAL',
      cancelText: 'BATAL',
      confirmText: 'SIMPAN',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      orderProvider.filterByDateRange(picked.start, picked.end);
      
      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Filter diterapkan: ${DateFormat('dd MMM').format(picked.start)} - ${DateFormat('dd MMM yyyy').format(picked.end)}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        // Show loading state
        if (orderProvider.isLoading) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                automaticallyImplyLeading: false,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                toolbarHeight: 320,
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    bottom: false,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSearchAndFilter(orderProvider),
                          _buildOrdersSummary(orderProvider),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: OrderCardSkeleton(),
                    ),
                    childCount: 5,
                  ),
                ),
              ),
            ],
          );
        }
        
        // Show empty state
        if (orderProvider.orders.isEmpty) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                automaticallyImplyLeading: false,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                toolbarHeight: 320,
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    bottom: false,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSearchAndFilter(orderProvider),
                          _buildOrdersSummary(orderProvider),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 100,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        orderProvider.searchQuery.isNotEmpty ||
                                orderProvider.selectedStatuses.isNotEmpty ||
                                orderProvider.startDate != null ||
                                orderProvider.endDate != null
                            ? 'Tidak ada pesanan ditemukan'
                            : 'Belum ada pesanan',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        
        // Show orders list
        return RefreshIndicator(
          onRefresh: () => orderProvider.loadAllOrders(),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                automaticallyImplyLeading: false,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                toolbarHeight: 320,
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    bottom: false,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSearchAndFilter(orderProvider),
                          _buildOrdersSummary(orderProvider),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildOrderCard(orderProvider.orders[index], orderProvider);
                    },
                    childCount: orderProvider.orders.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, OrderProvider orderProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${order.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    order.userName,
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFFFC20E)
                          : Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildOrderStatusChip(order.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(order.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                'Rp ${_formatPrice(order.totalAmount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFFFC20E)
                      : Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer info
                _buildInfoSection('Informasi Pemesan', [
                  _buildInfoRow('Nama', order.userName),
                  _buildInfoRow('No. HP', order.userPhone),
                  _buildInfoRow('Email', order.userEmail),
                ]),
                const SizedBox(height: 16),

                // Shipping address
                _buildInfoSection('Alamat Pengiriman', [
                  Text(order.shippingAddress),
                ]),
                const SizedBox(height: 16),

                // Order items
                _buildInfoSection(
                  'Produk',
                  order.items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: item.imageUrl.isNotEmpty
                                      ? Image.network(
                                          item.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.image_not_supported,
                                                  size: 20,
                                                  color: Colors.grey,
                                                );
                                              },
                                        )
                                      : const Icon(Icons.image, size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.productName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${item.quantity}x Rp ${_formatPrice(item.price)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Rp ${_formatPrice(item.totalPrice)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Update status
                const Text(
                  'Update Status',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: OrderStatus.all.map((status) {
                    return ChoiceChip(
                      label: Text(_getStatusText(status)),
                      selected: order.status == status,
                      selectedColor: _getStatusColor(status),
                      onSelected: (selected) {
                        if (selected && order.status != status) {
                          _updateOrderStatus(orderProvider, order.id, order.status, status);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          const Text(': '),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildOrderStatusChip(String status) {
    Color color;
    String text = _getStatusText(status);

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.processing:
        color = Colors.blue;
        break;
      case OrderStatus.shipped:
        color = Colors.purple;
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Menunggu';
      case OrderStatus.processing:
        return 'Diproses';
      case OrderStatus.shipped:
        return 'Dikirim';
      case OrderStatus.delivered:
        return 'Selesai';
      case OrderStatus.cancelled:
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange[100]!;
      case OrderStatus.processing:
        return Colors.blue[100]!;
      case OrderStatus.shipped:
        return Colors.purple[100]!;
      case OrderStatus.delivered:
        return Colors.green[100]!;
      case OrderStatus.cancelled:
        return Colors.red[100]!;
      default:
        return Colors.grey[100]!;
    }
  }

  Future<void> _updateOrderStatus(OrderProvider orderProvider, String orderId, String currentStatus, String newStatus) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Perubahan Status'),
        content: Text(
          'Apakah Anda yakin ingin mengubah status pesanan dari "${_getStatusText(currentStatus)}" ke "${_getStatusText(newStatus)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Ubah'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await orderProvider.updateOrderStatus(orderId, newStatus);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Status pesanan berhasil diubah ke "${_getStatusText(newStatus)}"',
              ),
              backgroundColor: Colors.green[600],
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
          
          // Reapply current filters to refresh the view
          orderProvider.loadAllOrders();
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mengubah status pesanan: $e'),
              backgroundColor: Colors.red[600],
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
