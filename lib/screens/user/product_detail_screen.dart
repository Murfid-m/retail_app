import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/image_carousel.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/review_widgets.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Defer loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReviews();
    });
  }

  Future<void> _loadReviews() async {
    final reviewProvider = Provider.of<ReviewProvider>(context, listen: false);
    await reviewProvider.loadProductReviews(widget.product.id);
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Produk')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product images carousel
            ImageCarousel(
              images: widget.product.allImages,
              height: 300,
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip and rating
                  Row(
                    children: [
                      Chip(
                        label: Text(widget.product.category),
                        labelStyle: const TextStyle(
                          color: Color(0xFFFFC20E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // Rating display
                      Consumer<ReviewProvider>(
                        builder: (context, reviewProvider, _) {
                          final summary = reviewProvider.ratingSummary;
                          if (summary.totalReviews > 0) {
                            return Row(
                              children: [
                                StarRating(
                                  rating: summary.averageRating,
                                  size: 18,
                                  showValue: true,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(${summary.totalReviews})',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Product name
                  Text(
                    widget.product.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Price
                  Text(
                    'Rp ${_formatPrice(widget.product.price)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0080C6),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stock info
                  Row(
                    children: [
                      Icon(
                        widget.product.stock > 0
                            ? Icons.check_circle_outline
                            : Icons.cancel_outlined,
                        color: widget.product.stock > 0 ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.product.stock > 0
                            ? 'Stok tersedia (${widget.product.stock})'
                            : 'Stok habis',
                        style: TextStyle(
                          color: widget.product.stock > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description.isNotEmpty
                        ? widget.product.description
                        : 'Tidak ada deskripsi',
                    style: TextStyle(color: Colors.grey[600], height: 1.5),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Reviews Section
                  _buildReviewsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildReviewsSection() {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        final reviews = reviewProvider.reviews;
        final summary = reviewProvider.ratingSummary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            const Text(
              'Ulasan Produk',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Rating Summary
            if (summary.totalReviews > 0) ...[
              RatingSummaryCard(
                averageRating: summary.averageRating,
                totalReviews: summary.totalReviews,
                distribution: summary.ratingDistribution,
              ),
              const SizedBox(height: 16),
            ],

            // Review list (read-only, no edit/delete)
            if (reviewProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (reviews.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada ulasan',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Beli produk ini dan berikan ulasan setelah pesanan selesai',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ReviewList(
                reviews: reviews,
                currentUserId: null, // No edit/delete in product detail
                onEdit: null,
                onDelete: null,
              ),
          ],
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Consumer<CartProvider>(
        builder: (context, cart, child) {
          final isInCart = cart.isInCart(widget.product.id);
          final quantity = cart.getQuantity(widget.product.id);

          if (isInCart) {
            return Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            cart.decrementQuantity(widget.product.id);
                          },
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: widget.product.stock > quantity
                              ? () {
                                  cart.incrementQuantity(widget.product.id);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Lihat Keranjang'),
                  ),
                ),
              ],
            );
          }

          return ElevatedButton(
            onPressed: widget.product.stock > 0
                ? () {
                    cart.addToCart(widget.product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ditambahkan ke keranjang'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_cart_outlined),
                const SizedBox(width: 8),
                Text(
                  widget.product.stock > 0 ? 'Tambah ke Keranjang' : 'Stok Habis',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
