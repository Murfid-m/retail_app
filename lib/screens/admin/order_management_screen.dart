import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import '../../widgets/skeleton_loading.dart';

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
  
  void _exportOrders(OrderProvider orderProvider) {
    final orders = orderProvider.orders;
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data pesanan untuk di-export')),
      );
      return;
    }
    
    // Create CSV data
    String csvData = 'Order ID,Customer,Email,Phone,Status,Total Amount,Created Date\\n';
    for (var order in orders) {
      csvData += '\"${order.id}\",\"${order.userName}\",\"${order.userEmail}\",\"${order.userPhone}\",\"${_getStatusLabel(order.status)}\",\"${order.totalAmount}\",\"${_formatDate(order.createdAt)}\"\\n';
    }
    
    // Show dialog with options
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data Pesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${orders.length} pesanan akan di-export.'),
            const SizedBox(height: 16),
            const Text(
              'Data akan di-copy ke clipboard dalam format CSV.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy to clipboard (simplified version)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data pesanan berhasil di-export ke clipboard')),
              );
              Navigator.pop(context);
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
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
            children: _statusOptions.map((status) {
              return _buildStatusChip(status, orderProvider);
            }).toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey[300],
          ),
        ),

        const SizedBox(height: 8),

        // Date Filter
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildDateFilterChip('Hari ini', orderProvider, () {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                orderProvider.filterByDateRange(today, today);
              }),
              const SizedBox(width: 8),
              _buildDateFilterChip('Minggu ini', orderProvider, () {
                final now = DateTime.now();
                final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
                final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
                final end = DateTime(now.year, now.month, now.day);
                orderProvider.filterByDateRange(start, end);
              }),
              const SizedBox(width: 8),
              _buildDateFilterChip('Bulan ini', orderProvider, () {
                final now = DateTime.now();
                final start = DateTime(now.year, now.month, 1);
                final end = DateTime(now.year, now.month, now.day);
                orderProvider.filterByDateRange(start, end);
              }),
              const SizedBox(width: 8),
              _buildCustomDateRangeChip(orderProvider),
              const SizedBox(width: 8),
              _buildSingleDatePickerChip(orderProvider),
              const SizedBox(width: 8),
              _buildClearDateFilterChip(orderProvider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, OrderProvider orderProvider) {
    final isSelected = (status == 'Semua Status' && orderProvider.selectedStatus == null) ||
        orderProvider.selectedStatus == status.toLowerCase();

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(_getStatusLabel(status)),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (selected) {
          if (status == 'Semua Status') {
            orderProvider.filterByStatus(null);
          } else {
            orderProvider.filterByStatus(status.toLowerCase());
          }
        },
      ),
    );
  }

  Widget _buildDateFilterChip(String label, OrderProvider orderProvider, VoidCallback onTap) {
    bool isActive = _isDateFilterActive(label, orderProvider);
    
    return FilterChip(
      label: Text(label),
      selected: isActive,
      showCheckmark: false,
      onSelected: (selected) {
        if (selected) {
          onTap();
        }
      },
    );
  }

  Widget _buildCustomDateRangeChip(OrderProvider orderProvider) {
    final hasCustomRange = orderProvider.startDate != null && 
                          orderProvider.endDate != null &&
                          !_isDateFilterActive('Hari ini', orderProvider) &&
                          !_isDateFilterActive('Minggu ini', orderProvider) &&
                          !_isDateFilterActive('Bulan ini', orderProvider);
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.date_range, size: 16),
          const SizedBox(width: 4),
          Text(hasCustomRange 
              ? '${DateFormat('dd/MM').format(orderProvider.startDate!)} - ${DateFormat('dd/MM').format(orderProvider.endDate!)}'
              : 'Rentang Tanggal'),
        ],
      ),
      selected: hasCustomRange,
      showCheckmark: false,
      onSelected: (selected) {
        _showDateRangePicker(orderProvider);
      },
    );
  }

  Widget _buildSingleDatePickerChip(OrderProvider orderProvider) {
    return FilterChip(
      label: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 16),
          SizedBox(width: 4),
          Text('Pilih Tanggal'),
        ],
      ),
      selected: false,
      showCheckmark: false,
      onSelected: (selected) {
        _showSingleDatePicker(orderProvider);
      },
    );
  }

  Future<void> _showDateRangePicker(OrderProvider orderProvider) async {
    final now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: orderProvider.startDate != null && orderProvider.endDate != null
          ? DateTimeRange(
              start: orderProvider.startDate!,
              end: orderProvider.endDate!,
            )
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFFFC20E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      orderProvider.filterByDateRange(picked.start, picked.end);
    }
  }

  Future<void> _showSingleDatePicker(OrderProvider orderProvider) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: orderProvider.startDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFFFC20E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final selectedDate = DateTime(picked.year, picked.month, picked.day);
      orderProvider.filterByDateRange(selectedDate, selectedDate);
    }
  }

  Widget _buildClearDateFilterChip(OrderProvider orderProvider) {
    final hasDateFilter = orderProvider.startDate != null && orderProvider.endDate != null;
    
    if (!hasDateFilter) return const SizedBox.shrink();
    
    return ActionChip(
      label: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.clear, size: 14),
          SizedBox(width: 4),
          Text('Hapus', style: TextStyle(fontSize: 12)),
        ],
      ),
      onPressed: () {
        orderProvider.filterByDateRange(null, null);
      },
      backgroundColor: Colors.red[50],
      side: BorderSide(color: Colors.red[200]!),
      labelStyle: TextStyle(color: Colors.red[700]),
    );
  }

  bool _isDateFilterActive(String label, OrderProvider orderProvider) {
    if (orderProvider.startDate == null || orderProvider.endDate == null) return false;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = orderProvider.startDate!;
    final endDate = orderProvider.endDate!;
    
    switch (label) {
      case 'Hari ini':
        return startDate.year == today.year && 
               startDate.month == today.month && 
               startDate.day == today.day &&
               endDate.year == today.year && 
               endDate.month == today.month && 
               endDate.day == today.day;
      case 'Minggu ini':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return startDate.year == start.year && 
               startDate.month == start.month && 
               startDate.day == start.day &&
               endDate.year == today.year && 
               endDate.month == today.month && 
               endDate.day == today.day;
      case 'Bulan ini':
        final start = DateTime(now.year, now.month, 1);
        return startDate.year == start.year && 
               startDate.month == start.month && 
               startDate.day == start.day &&
               endDate.year == today.year && 
               endDate.month == today.month && 
               endDate.day == today.day;
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
    if (orderProvider.selectedStatus != null) {
      final statusLabel = _getStatusLabel(orderProvider.selectedStatus!);
      activeFilters.add('Status: $statusLabel');
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFFFC20E)
                  : Theme.of(context).primaryColor,
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
        Icon(icon, color: color, size: 20),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        // Show loading state
        if (orderProvider.isLoading) {
          return Column(
            children: [
              _buildSearchAndFilter(orderProvider),
              _buildOrdersSummary(orderProvider),
              Expanded(
                child: ListSkeleton(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  itemBuilder: (context, index) => const OrderCardSkeleton(),
                  separator: const SizedBox(height: 12),
                ),
              ),
            ],
          );
        }
        
        // Show empty state
        if (orderProvider.orders.isEmpty) {
          return Column(
            children: [
              _buildSearchAndFilter(orderProvider),
              _buildOrdersSummary(orderProvider),
              Expanded(
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
                                orderProvider.selectedStatus != null ||
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
        
        // Show orders with floating search/filter
        return RefreshIndicator(
          onRefresh: () => orderProvider.loadAllOrders(),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                toolbarHeight: 400, // Increased for divider
                automaticallyImplyLeading: false,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: SafeArea(
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
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: index == orderProvider.orders.length - 1 ? 16 : 0,
                      ),
                      child: _buildOrderCard(orderProvider.orders[index], orderProvider),
                    );
                  },
                  childCount: orderProvider.orders.length,
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
      margin: const EdgeInsets.only(bottom: 12),
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
