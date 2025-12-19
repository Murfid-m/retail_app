import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        Provider.of<OrderProvider>(context, listen: false)
            .loadUserOrders(user.id);
      }
    });
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (orderProvider.userOrders.isEmpty) {
          return Center(
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
                  'Belum ada pesanan',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yuk, mulai belanja!',
                  style: TextStyle(
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            final user = Provider.of<AuthProvider>(context, listen: false).user;
            if (user != null) {
              await orderProvider.loadUserOrders(user.id);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orderProvider.userOrders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(orderProvider.userOrders[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(order.createdAt),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const Divider(height: 24),
            ...order.items.take(2).map((item) => Padding(
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                    ],
                  ),
                )),
            if (order.items.length > 2)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '+${order.items.length - 2} produk lainnya',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pembayaran',
                  style: TextStyle(
                    color: Colors.grey[600],
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
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        text = 'Menunggu';
        break;
      case OrderStatus.processing:
        color = Colors.blue;
        text = 'Diproses';
        break;
      case OrderStatus.shipped:
        color = Colors.purple;
        text = 'Dikirim';
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        text = 'Selesai';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = 'Dibatalkan';
        break;
      default:
        color = Colors.grey;
        text = status;
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
}
