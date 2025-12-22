import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wishlist_model.dart';

class WishlistService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all wishlist items for a user with product details
  Future<List<WishlistItem>> getWishlist(String userId) async {
    try {
      final response = await _supabase
          .from('wishlists')
          .select('*, products(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => WishlistItem.fromJson(item))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Add product to wishlist
  Future<WishlistItem> addToWishlist(String userId, String productId) async {
    try {
      final response = await _supabase
          .from('wishlists')
          .insert({
            'user_id': userId,
            'product_id': productId,
          })
          .select('*, products(*)')
          .single();

      return WishlistItem.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  /// Remove product from wishlist
  Future<void> removeFromWishlist(String userId, String productId) async {
    try {
      await _supabase
          .from('wishlists')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
    } catch (e) {
      rethrow;
    }
  }

  /// Check if product is in wishlist
  Future<bool> isInWishlist(String userId, String productId) async {
    try {
      final response = await _supabase
          .from('wishlists')
          .select('id')
          .eq('user_id', userId)
          .eq('product_id', productId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Toggle wishlist status
  Future<bool> toggleWishlist(String userId, String productId) async {
    try {
      final isCurrentlyInWishlist = await isInWishlist(userId, productId);
      
      if (isCurrentlyInWishlist) {
        await removeFromWishlist(userId, productId);
        return false; // Not in wishlist anymore
      } else {
        await addToWishlist(userId, productId);
        return true; // Now in wishlist
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get wishlist count for a user
  Future<int> getWishlistCount(String userId) async {
    try {
      final response = await _supabase
          .from('wishlists')
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}
