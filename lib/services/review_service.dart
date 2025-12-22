import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/review_model.dart';

class ReviewService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all reviews for a product
  Future<List<ReviewModel>> getProductReviews(String productId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*, users(name, avatar_url)')
          .eq('product_id', productId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ReviewModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  // Get rating summary for a product
  Future<ProductRatingSummary> getProductRatingSummary(String productId) async {
    try {
      final reviews = await getProductReviews(productId);
      return ProductRatingSummary.fromReviews(reviews);
    } catch (e) {
      print('Error fetching rating summary: $e');
      return ProductRatingSummary.empty();
    }
  }

  // Add a new review
  Future<bool> addReview({
    required String productId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    try {
      // Check if user already reviewed this product
      final existing = await _supabase
          .from('reviews')
          .select('id')
          .eq('product_id', productId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Update existing review
        await _supabase
            .from('reviews')
            .update({
              'rating': rating,
              'comment': comment,
              'created_at': DateTime.now().toIso8601String(),
            })
            .eq('product_id', productId)
            .eq('user_id', userId);
      } else {
        // Insert new review
        await _supabase.from('reviews').insert({
          'product_id': productId,
          'user_id': userId,
          'rating': rating,
          'comment': comment,
        });
      }

      // Update product average rating
      await _updateProductRating(productId);

      return true;
    } catch (e) {
      print('Error adding review: $e');
      return false;
    }
  }

  // Delete a review
  Future<bool> deleteReview(String reviewId, String productId) async {
    try {
      await _supabase.from('reviews').delete().eq('id', reviewId);
      await _updateProductRating(productId);
      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }

  // Check if user has reviewed a product
  Future<ReviewModel?> getUserReview(String productId, String userId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*, users(name, avatar_url)')
          .eq('product_id', productId)
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return ReviewModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching user review: $e');
      return null;
    }
  }

  // Update product average rating
  Future<void> _updateProductRating(String productId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('rating')
          .eq('product_id', productId);

      final reviews = response as List;
      if (reviews.isEmpty) {
        await _supabase.from('products').update({
          'average_rating': 0,
          'total_reviews': 0,
        }).eq('id', productId);
      } else {
        final total = reviews.fold<int>(0, (sum, r) => sum + (r['rating'] as int));
        final average = total / reviews.length;

        await _supabase.from('products').update({
          'average_rating': average,
          'total_reviews': reviews.length,
        }).eq('id', productId);
      }
    } catch (e) {
      print('Error updating product rating: $e');
    }
  }

  // Check if user can review a product (must have delivered order containing this product)
  Future<bool> canUserReviewProduct(String productId, String userId) async {
    try {
      // Check if user has any delivered orders containing this product
      final response = await _supabase
          .from('orders')
          .select('id, order_items!inner(product_id)')
          .eq('user_id', userId)
          .eq('status', 'delivered')
          .eq('order_items.product_id', productId)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      print('Error checking review eligibility: $e');
      return false;
    }
  }

  // Get user's all reviews
  Future<List<ReviewModel>> getUserReviews(String userId) async {
    try {
      final response = await _supabase
          .from('reviews')
          .select('*, users(name)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ReviewModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching user reviews: $e');
      return [];
    }
  }
}
