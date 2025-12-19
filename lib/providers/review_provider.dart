import 'package:flutter/foundation.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

class ReviewProvider with ChangeNotifier {
  final ReviewService _reviewService = ReviewService();

  List<ReviewModel> _reviews = [];
  ProductRatingSummary _ratingSummary = ProductRatingSummary.empty();
  ReviewModel? _userReview;
  bool _isLoading = false;
  String? _error;

  List<ReviewModel> get reviews => _reviews;
  ProductRatingSummary get ratingSummary => _ratingSummary;
  ReviewModel? get userReview => _userReview;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load reviews for a product
  Future<void> loadProductReviews(String productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reviews = await _reviewService.getProductReviews(productId);
      _ratingSummary = ProductRatingSummary.fromReviews(_reviews);
    } catch (e) {
      _error = 'Gagal memuat ulasan';
      print('Error loading reviews: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load user's review for a product
  Future<void> loadUserReview(String productId, String userId) async {
    try {
      _userReview = await _reviewService.getUserReview(productId, userId);
      notifyListeners();
    } catch (e) {
      print('Error loading user review: $e');
    }
  }

  // Add or update review
  Future<bool> submitReview({
    required String productId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _reviewService.addReview(
        productId: productId,
        userId: userId,
        rating: rating,
        comment: comment,
      );

      if (success) {
        // Reload reviews
        await loadProductReviews(productId);
        await loadUserReview(productId, userId);
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = 'Gagal mengirim ulasan';
      notifyListeners();
      return false;
    }
  }

  // Delete review
  Future<bool> deleteReview(String reviewId, String productId, String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _reviewService.deleteReview(reviewId, productId);

      if (success) {
        await loadProductReviews(productId);
        _userReview = null;
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = 'Gagal menghapus ulasan';
      notifyListeners();
      return false;
    }
  }

  // Check if user can review a product (has delivered order)
  Future<bool> canUserReviewProduct(String productId, String userId) async {
    try {
      return await _reviewService.canUserReviewProduct(productId, userId);
    } catch (e) {
      print('Error checking review eligibility: $e');
      return false;
    }
  }

  // Clear state
  void clear() {
    _reviews = [];
    _ratingSummary = ProductRatingSummary.empty();
    _userReview = null;
    _error = null;
    notifyListeners();
  }
}
