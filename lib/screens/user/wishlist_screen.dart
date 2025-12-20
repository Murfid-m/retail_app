import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/wishlist_model.dart';
import '../../widgets/skeleton_loading.dart';
import 'product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  void initState() {
    super.initState();
    // Defer loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWishlist();
    });
  }

  Future<void> _loadWishlist() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      await wishlistProvider.loadWishlist(authProvider.user!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: [
          Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, child) {
              if (wishlistProvider.wishlist.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Hapus semua',
                onPressed: () => _showClearConfirmation(context),
              );
            },
          ),
        ],
      ),
      body: Consumer2<WishlistProvider, AuthProvider>(
        builder: (context, wishlistProvider, authProvider, child) {
          if (authProvider.user == null) {
            return const Center(
              child: Text('Silakan login untuk melihat wishlist'),
            );
          }

          if (wishlistProvider.isLoading) {
            return _buildSkeletonLoading();
          }

          if (wishlistProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(wishlistProvider.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadWishlist,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final wishlist = wishlistProvider.wishlist;

          if (wishlist.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadWishlist,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                return _buildWishlistItem(wishlist[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SkeletonLoading(
                    width: 80,
                    height: 80,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLoading(width: double.infinity, height: 16),
                        const SizedBox(height: 8),
                        SkeletonLoading(width: 100, height: 14),
                        const SizedBox(height: 8),
                        SkeletonLoading(width: 80, height: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Wishlist Kosong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan produk favorit Anda ke wishlist',
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Mulai Belanja'),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistItem(WishlistItem item) {
    final product = item.product;
    
    if (product == null) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _removeFromWishlist(item),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(product: product),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              );
                            },
                          )
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.category,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${_formatPrice(product.price)}',
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      // Rating if available
                      if (product.totalReviews > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              '${product.averageRating.toStringAsFixed(1)} (${product.totalReviews})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Action buttons
                Column(
                  children: [
                    // Add to cart button
                    Consumer<CartProvider>(
                      builder: (context, cartProvider, child) {
                        return IconButton(
                          icon: const Icon(Icons.add_shopping_cart),
                          color: kPrimaryColor,
                          onPressed: product.stock > 0
                              ? () {
                                  cartProvider.addToCart(product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Ditambahkan ke keranjang'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }
                              : null,
                          tooltip: product.stock > 0 
                              ? 'Tambah ke keranjang' 
                              : 'Stok habis',
                        );
                      },
                    ),
                    // Remove from wishlist button
                    IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () => _removeFromWishlist(item),
                      tooltip: 'Hapus dari wishlist',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _removeFromWishlist(WishlistItem item) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      wishlistProvider.removeFromWishlist(authProvider.user!.id, item.productId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.product?.name ?? 'Produk'} dihapus dari wishlist'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              if (item.product != null) {
                wishlistProvider.toggleWishlist(authProvider.user!.id, item.product!);
              }
            },
          ),
        ),
      );
    }
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Wishlist'),
        content: const Text('Apakah Anda yakin ingin menghapus semua item dari wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _clearAllWishlist();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  void _clearAllWishlist() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      final wishlist = List<WishlistItem>.from(wishlistProvider.wishlist);
      for (final item in wishlist) {
        wishlistProvider.removeFromWishlist(authProvider.user!.id, item.productId);
      }
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
}
