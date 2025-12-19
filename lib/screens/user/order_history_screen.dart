import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/review_provider.dart';
import '../../models/order_model.dart';
import '../../models/review_model.dart';
import '../../services/review_service.dart';
import '../../widgets/skeleton_loading.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/review_widgets.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final ReviewService _reviewService = ReviewService();
  // Cache untuk status review per item
  final Map<String, bool> _reviewedItems = {};
  final Map<String, ReviewModel?> _existingReviews = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        Provider.of<OrderProvider>(
          context,
          listen: false,
        ).loadUserOrders(user.id);
      }
    });
  }

  // Check if item has been reviewed
  Future<void> _checkItemReviewed(String productId, String userId) async {
    if (_reviewedItems.containsKey(productId)) return;
    
    final review = await _reviewService.getUserReview(productId, userId);
    if (mounted) {
      setState(() {
        _reviewedItems[productId] = review != null;
        _existingReviews[productId] = review;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.isLoading) {
          return ListSkeleton(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (context, index) => const OrderCardSkeleton(),
            separator: const SizedBox(height: 16),
          );
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
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yuk, mulai belanja!',
                  style: TextStyle(color: Colors.grey[400]),
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
    final isDelivered = order.status == OrderStatus.delivered;
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    
    // Check review status for each item if order is delivered
    if (isDelivered && user != null) {
      for (var item in order.items) {
        _checkItemReviewed(item.productId, user.id);
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(order.createdAt),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const Divider(height: 24),
            
            // Show all items with review button for delivered orders
            ...order.items.map((item) => _buildOrderItem(item, isDelivered, user?.id)),
            
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Pembayaran',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text(
                  'Rp ${_formatPrice(order.totalAmount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
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

  Widget _buildOrderItem(OrderItem item, bool isDelivered, String? userId) {
    final isReviewed = _reviewedItems[item.productId] ?? false;
    final existingReview = _existingReviews[item.productId];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
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
                        return const Icon(
                          Icons.image_not_supported,
                          size: 24,
                          color: Colors.grey,
                        );
                      },
                    )
                  : const Icon(Icons.image, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity}x Rp ${_formatPrice(item.price)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                // Show existing rating or review button for delivered orders
                if (isDelivered && userId != null) ...[
                  const SizedBox(height: 8),
                  if (isReviewed && existingReview != null)
                    // Show existing rating
                    Row(
                      children: [
                        StarRating(
                          rating: existingReview.rating.toDouble(),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showReviewDialog(
                            productId: item.productId,
                            productName: item.productName,
                            userId: userId,
                            existingReview: existingReview,
                          ),
                          child: Text(
                            'Edit',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    // Show review button
                    OutlinedButton.icon(
                      onPressed: () => _showReviewDialog(
                        productId: item.productId,
                        productName: item.productName,
                        userId: userId,
                      ),
                      icon: const Icon(Icons.rate_review_outlined, size: 16),
                      label: const Text('Beri Ulasan'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        textStyle: const TextStyle(fontSize: 12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog({
    required String productId,
    required String productName,
    required String userId,
    ReviewModel? existingReview,
  }) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            existingReview != null ? 'Edit Ulasan' : 'Beri Ulasan',
            style: const TextStyle(fontSize: 18),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            productName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Review form (embedded mode)
                  ReviewFormDialog(
                    existingReview: existingReview,
                    isEmbedded: true,
                    onSubmit: (rating, comment) async {
                      final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(dialogContext);

                      final success = await reviewProvider.submitReview(
                        productId: productId,
                        userId: userId,
                        rating: rating,
                        comment: comment,
                      );

                      navigator.pop();

                      if (success) {
                        // Update cache
                        final newReview = await _reviewService.getUserReview(productId, userId);
                        if (mounted) {
                          setState(() {
                            _reviewedItems[productId] = true;
                            _existingReviews[productId] = newReview;
                          });
                        }
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Ulasan berhasil disimpan')),
                        );
                      } else {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('Gagal menyimpan ulasan')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
