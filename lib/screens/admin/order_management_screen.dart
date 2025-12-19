import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

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
    'cancelled'
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
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  Widget _buildSearchAndFilter(OrderProvider orderProvider) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari pesanan...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        orderProvider.searchOrders('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
            ),
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
              _buildDateRangeChip(orderProvider),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status, OrderProvider orderProvider) {
    final isSelected = (status == 'Semua Status' && orderProvider.selectedStatus == null) ||
        orderProvider.selectedStatus == status;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(_getStatusLabel(status)),
        selected: isSelected,
        onSelected: (selected) {
          if (status == 'Semua Status') {
            orderProvider.filterByStatus(null);
          } else {
            orderProvider.filterByStatus(status);
          }
        },
      ),
    );
  }

  Widget _buildDateRangeChip(OrderProvider orderProvider) {
    final hasDateFilter = orderProvider.startDate != null || orderProvider.endDate != null;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.date_range, size: 16),
          const SizedBox(width: 4),
          Text(hasDateFilter ? 'Tanggal Dipilih' : 'Filter Tanggal'),
        ],
      ),
      selected: hasDateFilter,
      onSelected: (selected) {
        if (selected) {
          _showDateRangePicker(orderProvider);
        } else {
          orderProvider.filterByDateRange(null, null);
        }
      },
    );
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



  Future<void> _showDateRangePicker(OrderProvider orderProvider) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDateRange: orderProvider.startDate != null && orderProvider.endDate != null
          ? DateTimeRange(start: orderProvider.startDate!, end: orderProvider.endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
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

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = orderProvider.orders;

        return Column(
          children: [
            _buildSearchAndFilter(orderProvider),
            Expanded(
              child: orders.isEmpty
                  ? Center(
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
                            orderProvider.searchQuery.isNotEmpty || orderProvider.selectedStatus != null || 
                            orderProvider.startDate != null || orderProvider.endDate != null
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
                    )
                  : RefreshIndicator(
                      onRefresh: () => orderProvider.loadAllOrders(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          return _buildOrderCard(orders[index], orderProvider);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order, OrderProvider orderProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${order.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
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
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
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
                _buildInfoSection(
                  'Informasi Pemesan',
                  [
                    _buildInfoRow('Nama', order.userName),
                    _buildInfoRow('No. HP', order.userPhone),
                    _buildInfoRow('Email', order.userEmail),
                  ],
                ),
                const SizedBox(height: 16),

                // Shipping address
                _buildInfoSection(
                  'Alamat Pengiriman',
                  [Text(order.shippingAddress)],
                ),
                const SizedBox(height: 16),

                // Order items
                _buildInfoSection(
                  'Produk',
                  order.items.map((item) => Padding(
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
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.image_not_supported, size: 20, color: Colors.grey);
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
                  )).toList(),
                ),
                const SizedBox(height: 16),

                // Update status
                const Text(
                  'Update Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: OrderStatus.all.map((status) {
                    return ChoiceChip(
                      label: Text(_getStatusText(status)),
                      selected: order.status == status,
                      onSelected: (selected) {
                        if (selected && order.status != status) {
                          orderProvider.updateOrderStatus(order.id, status);
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
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
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
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(value),
          ),
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
}
