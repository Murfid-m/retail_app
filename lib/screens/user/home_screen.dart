import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/search_history_provider.dart';
import '../../models/product_model.dart';
import '../../widgets/skeleton_loading.dart';
import '../../widgets/wishlist_button.dart';
import '../auth/login_screen.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';
import 'order_history_screen.dart';
import 'wishlist_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  int _currentIndex = 0;
  bool _showSearchHistory = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
      _loadWishlistAndHistory();
    });
    
    // Listen for focus changes
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() {
          _showSearchHistory = false;
        });
      }
    });
  }

  Future<void> _loadWishlistAndHistory() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wishlistProvider = Provider.of<WishlistProvider>(context, listen: false);
    final searchHistoryProvider = Provider.of<SearchHistoryProvider>(context, listen: false);
    
    if (authProvider.user != null) {
      wishlistProvider.loadWishlist(authProvider.user!.id);
    }
    searchHistoryProvider.loadHistory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showThemeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Tema'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemePreference>(
              title: const Text('Ikuti Perangkat'),
              subtitle: const Text('Otomatis sesuai pengaturan sistem'),
              value: ThemePreference.system,
              groupValue: themeProvider.themePreference,
              onChanged: (value) {
                themeProvider.setThemePreference(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemePreference>(
              title: const Text('Mode Terang'),
              subtitle: const Text('Selalu tampilan terang'),
              value: ThemePreference.light,
              groupValue: themeProvider.themePreference,
              onChanged: (value) {
                themeProvider.setThemePreference(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemePreference>(
              title: const Text('Mode Gelap'),
              subtitle: const Text('Selalu tampilan gelap'),
              value: ThemePreference.dark,
              groupValue: themeProvider.themePreference,
              onChanged: (value) {
                themeProvider.setThemePreference(value!);
                Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              child: Image.asset(
                'assets/images/logo_white.png',
                width: 30,
                height: 30,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.store,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'THRIFT STORE',
              style: TextStyle(                fontFamily: 'Rockwell',                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          // Wishlist button
          Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, child) {
              return WishlistBadge(
                count: wishlistProvider.wishlistCount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WishlistScreen(),
                    ),
                  );
                },
              );
            },
          ),
          // Cart button
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  if (cart.totalItems > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${cart.totalItems}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildProductList(),
          const OrderHistoryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Pesanan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            accountName: Text(user?.name ?? 'Guest'),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user.avatarUrl!,
                        fit: BoxFit.cover,
                        width: 72,
                        height: 72,
                        placeholder: (context, url) => const CircularProgressIndicator(),
                        errorWidget: (context, url, error) => Text(
                          (user.name ?? 'G').substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    )
                  : Text(
                      (user?.name ?? 'G').substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Beranda'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 0;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_cart_outlined),
            title: const Text('Keranjang'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
          Consumer<WishlistProvider>(
            builder: (context, wishlistProvider, child) {
              return ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: const Text('Wishlist'),
                trailing: wishlistProvider.wishlistCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${wishlistProvider.wishlistCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WishlistScreen()),
                  );
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: const Text('Riwayat Pesanan'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 1;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outlined),
            title: const Text('Profil'),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _currentIndex = 2;
              });
            },
          ),
          const Divider(),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    ),
                    title: const Text('Tema Aplikasi'),
                    subtitle: Text(
                      themeProvider.themePreference == ThemePreference.system
                          ? 'Ikuti Perangkat'
                          : themeProvider.themePreference == ThemePreference.dark
                              ? 'Mode Gelap'
                              : 'Mode Terang',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onTap: () => _showThemeDialog(context, themeProvider),
                  ),
                ],
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Keluar', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await authProvider.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Consumer<SearchHistoryProvider>(
      builder: (context, searchHistoryProvider, child) {
        return Stack(
          children: [
            Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return GridSkeleton(
                    padding: const EdgeInsets.all(16),
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    itemCount: 6,
                    itemBuilder: (context, index) => const ProductCardSkeleton(),
                  );
                }

                if (productProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(productProvider.error!),
                        ElevatedButton(
                          onPressed: () => productProvider.loadProducts(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final products = productProvider.products;

                if (products.isEmpty) {
                  return const Center(child: Text('Tidak ada produk ditemukan'));
                }

                return RefreshIndicator(
                  onRefresh: () => productProvider.loadProducts(),
                  child: CustomScrollView(
                    slivers: [
                      // Search bar dan Category filter sebagai satu floating sliver app bar
                      SliverAppBar(
                        floating: true,
                        snap: true,
                        automaticallyImplyLeading: false,
                        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                        elevation: 0,
                        toolbarHeight: 148,
                        flexibleSpace: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Search bar
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                                child: SearchBar(
                                  controller: _searchController,
                                  focusNode: _searchFocusNode,
                                  hintText: 'Cari produk...',
                                  leading: Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Icon(
                                      Icons.search,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? kAccentColor
                                          : kPrimaryColor,
                                    ),
                                  ),
                                  trailing: [
                                    // History button
                                    if (searchHistoryProvider.hasHistory &&
                                        _searchController.text.isEmpty)
                                      IconButton(
                                        icon: Icon(
                                          Icons.history,
                                          color:
                                              Theme.of(context).brightness == Brightness.dark
                                                  ? kAccentColor
                                                  : kPrimaryColor,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showSearchHistory = !_showSearchHistory;
                                          });
                                          if (_showSearchHistory) {
                                            _searchFocusNode.requestFocus();
                                          }
                                        },
                                        tooltip: 'Riwayat pencarian',
                                      ),
                                    // Clear button
                                    if (_searchController.text.isNotEmpty)
                                      IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _showSearchHistory = false;
                                          });
                                          productProvider.searchProducts('');
                                        },
                                      ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _showSearchHistory =
                                          value.isEmpty && searchHistoryProvider.hasHistory;
                                    });
                                    productProvider.searchProducts(value);
                                  },
                                  onTap: () {
                                    setState(() {
                                      _showSearchHistory = _searchController.text.isEmpty &&
                                          searchHistoryProvider.hasHistory;
                                    });
                                  },
                                  onSubmitted: (value) {
                                    if (value.trim().isNotEmpty) {
                                      searchHistoryProvider.addToHistory(value);
                                      setState(() {
                                        _showSearchHistory = false;
                                      });
                                    }
                                  },
                                ),
                              ),
                              // Category filter
                              SizedBox(
                                height: 50,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  children: [
                                    _buildCategoryChip('Semua', null, productProvider),
                                    ...ProductCategory.all.map(
                                      (category) => _buildCategoryChip(
                                          category, category, productProvider),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      // Product grid sebagai sliver
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return _buildProductCard(products[index]);
                            },
                            childCount: products.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Search History Dropdown (tetap sebagai overlay)
            if (_showSearchHistory && searchHistoryProvider.history.isNotEmpty)
              Positioned(
                top: 80,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Riwayat Pencarian',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                searchHistoryProvider.clearHistory();
                                setState(() {
                                  _showSearchHistory = false;
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(0, 32),
                              ),
                              child: const Text(
                                'Hapus Semua',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      ...searchHistoryProvider.history.take(5).map((item) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.history, size: 20),
                          title: Text(
                            item.query,
                            style: const TextStyle(fontSize: 14),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              searchHistoryProvider.removeFromHistory(item.query);
                              if (searchHistoryProvider.history.isEmpty) {
                                setState(() {
                                  _showSearchHistory = false;
                                });
                              }
                            },
                          ),
                          onTap: () {
                            _searchController.text = item.query;
                            Provider.of<ProductProvider>(
                              context,
                              listen: false,
                            ).searchProducts(item.query);
                            setState(() {
                              _showSearchHistory = false;
                            });
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChip(
    String label,
    String? category,
    ProductProvider productProvider,
  ) {
    final isSelected = productProvider.selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          productProvider.filterByCategory(selected ? category : null);
        },
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image with multi-image indicator and wishlist
            AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[200],
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              );
                            },
                          )
                        : const Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                  // Multi-image indicator
                  if (product.allImages.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library, size: 12, color: Colors.white),
                            const SizedBox(width: 2),
                            Text(
                              '${product.allImages.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Wishlist button
                        Consumer2<WishlistProvider, AuthProvider>(
                          builder: (context, wishlistProvider, authProvider, child) {
                            final isInWishlist = wishlistProvider.isInWishlist(product.id);
                            return InkWell(
                              onTap: () {
                                if (authProvider.user != null) {
                                  wishlistProvider.toggleWishlist(authProvider.user!.id, product);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isInWishlist
                                            ? 'Dihapus dari wishlist'
                                            : 'Ditambahkan ke wishlist',
                                      ),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                              child: Icon(
                                isInWishlist ? Icons.favorite : Icons.favorite_border,
                                color: isInWishlist ? Colors.red : Colors.grey,
                                size: 18,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Rating row
                    if (product.totalReviews > 0)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            product.averageRating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ' (${product.totalReviews})',
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ],
                      )
                    else
                      Text(
                        product.category,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Rp ${_formatPrice(product.price)}',
                            style: const TextStyle(
                              color: kPrimaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Consumer<CartProvider>(
                          builder: (context, cart, child) {
                            return InkWell(
                              onTap: () {
                                cart.addToCart(product);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ditambahkan ke keranjang'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add_shopping_cart,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

// Delegate untuk category filter yang bisa floating
class _CategoryFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _CategoryFilterDelegate({required this.child});

  @override
  double get minExtent => 58;

  @override
  double get maxExtent => 58;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_CategoryFilterDelegate oldDelegate) {
    return false;
  }
}
