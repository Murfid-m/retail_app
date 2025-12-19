import 'package:flutter/material.dart';
import '../models/wishlist_model.dart';
import '../models/product_model.dart';
import '../services/wishlist_service.dart';

class WishlistProvider extends ChangeNotifier {
  final WishlistService _wishlistService = WishlistService();

  List<WishlistItem> _wishlist = [];
  Set<String> _wishlistProductIds = {};
  bool _isLoading = false;
  String? _error;

  List<WishlistItem> get wishlist => _wishlist;
  Set<String> get wishlistProductIds => _wishlistProductIds;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get wishlistCount => _wishlist.length;

  /// Load wishlist for a user
  Future<void> loadWishlist(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wishlist = await _wishlistService.getWishlist(userId);
      _wishlistProductIds = _wishlist.map((item) => item.productId).toSet();
    } catch (e) {
      _error = 'Gagal memuat wishlist: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if a product is in wishlist
  bool isInWishlist(String productId) {
    return _wishlistProductIds.contains(productId);
  }

  /// Toggle wishlist status for a product
  Future<void> toggleWishlist(String userId, ProductModel product) async {
    final productId = product.id;
    final wasInWishlist = isInWishlist(productId);

    // Optimistic update
    if (wasInWishlist) {
      _wishlistProductIds.remove(productId);
      _wishlist.removeWhere((item) => item.productId == productId);
    } else {
      _wishlistProductIds.add(productId);
      // Add temporary item
      _wishlist.insert(0, WishlistItem(
        id: 'temp_$productId',
        userId: userId,
        productId: productId,
        createdAt: DateTime.now(),
        product: product,
      ));
    }
    notifyListeners();

    try {
      final isNowInWishlist = await _wishlistService.toggleWishlist(userId, productId);
      
      // Sync with server response
      if (isNowInWishlist != !wasInWishlist) {
        // Server response different from expectation, reload
        await loadWishlist(userId);
      }
    } catch (e) {
      // Revert on error
      if (wasInWishlist) {
        _wishlistProductIds.add(productId);
        _wishlist.insert(0, WishlistItem(
          id: 'temp_$productId',
          userId: userId,
          productId: productId,
          createdAt: DateTime.now(),
          product: product,
        ));
      } else {
        _wishlistProductIds.remove(productId);
        _wishlist.removeWhere((item) => item.productId == productId);
      }
      _error = 'Gagal mengubah wishlist: $e';
      notifyListeners();
    }
  }

  /// Remove from wishlist
  Future<void> removeFromWishlist(String userId, String productId) async {
    // Optimistic update
    final removedItem = _wishlist.firstWhere(
      (item) => item.productId == productId,
      orElse: () => WishlistItem(
        id: '',
        userId: userId,
        productId: productId,
        createdAt: DateTime.now(),
      ),
    );
    
    _wishlistProductIds.remove(productId);
    _wishlist.removeWhere((item) => item.productId == productId);
    notifyListeners();

    try {
      await _wishlistService.removeFromWishlist(userId, productId);
    } catch (e) {
      // Revert on error
      _wishlistProductIds.add(productId);
      _wishlist.insert(0, removedItem);
      _error = 'Gagal menghapus dari wishlist: $e';
      notifyListeners();
    }
  }

  /// Clear wishlist (local only, for logout)
  void clearWishlist() {
    _wishlist = [];
    _wishlistProductIds = {};
    _error = null;
    notifyListeners();
  }
}
