class ReviewModel {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final int rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Handle nested user data from join query
    String userName = 'Anonymous';
    String? avatarUrl;
    
    if (json['users'] != null && json['users']['name'] != null) {
      userName = json['users']['name'];
      avatarUrl = json['users']['avatar_url'];
    } else if (json['user_name'] != null) {
      userName = json['user_name'];
      avatarUrl = json['user_avatar_url'];
    }

    return ReviewModel(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: userName,
      userAvatarUrl: avatarUrl,
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonWithoutId() {
    return {
      'product_id': productId,
      'user_id': userId,
      'rating': rating,
      'comment': comment,
    };
  }
}

class ProductRatingSummary {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution; // 1-5 stars count

  ProductRatingSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory ProductRatingSummary.empty() {
    return ProductRatingSummary(
      averageRating: 0.0,
      totalReviews: 0,
      ratingDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
    );
  }

  factory ProductRatingSummary.fromReviews(List<ReviewModel> reviews) {
    if (reviews.isEmpty) {
      return ProductRatingSummary.empty();
    }

    final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    double totalRating = 0;

    for (final review in reviews) {
      totalRating += review.rating;
      distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
    }

    return ProductRatingSummary(
      averageRating: totalRating / reviews.length,
      totalReviews: reviews.length,
      ratingDistribution: distribution,
    );
  }
}
