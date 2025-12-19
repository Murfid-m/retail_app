class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
  final List<String> imageUrls; // Multi-image support
  final int stock;
  final DateTime createdAt;
  final double averageRating;
  final int totalReviews;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
    this.imageUrls = const [],
    required this.stock,
    required this.createdAt,
    this.averageRating = 0.0,
    this.totalReviews = 0,
  });

  // Get all images (primary + additional)
  List<String> get allImages {
    final images = <String>[];
    if (imageUrl.isNotEmpty) {
      images.add(imageUrl);
    }
    images.addAll(imageUrls.where((url) => url.isNotEmpty && url != imageUrl));
    return images;
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Parse image_urls array
    List<String> imageUrls = [];
    if (json['image_urls'] != null) {
      if (json['image_urls'] is List) {
        imageUrls = List<String>.from(json['image_urls']);
      } else if (json['image_urls'] is String) {
        // Handle JSON string format
        try {
          final parsed = json['image_urls'];
          if (parsed is String && parsed.startsWith('[')) {
            // It's a JSON string, parse it
            imageUrls = List<String>.from(
              (parsed.replaceAll('[', '').replaceAll(']', '').replaceAll('"', ''))
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty),
            );
          }
        } catch (_) {
          imageUrls = [];
        }
      }
    }

    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      category: json['category'] ?? '',
      imageUrl: json['image_url'] ?? '',
      imageUrls: imageUrls,
      stock: json['stock'] ?? 0,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'stock': stock,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJsonWithoutId() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'image_url': imageUrl,
      'image_urls': imageUrls,
      'stock': stock,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? imageUrl,
    List<String>? imageUrls,
    int? stock,
    DateTime? createdAt,
    double? averageRating,
    int? totalReviews,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }
}

class ProductCategory {
  static const String kaos = 'Kaos';
  static const String kemeja = 'Kemeja';
  static const String celana = 'Celana';
  static const String jaket = 'Jaket';
  static const String sepatu = 'Sepatu';
  static const String aksesoris = 'Aksesoris';

  static List<String> get all => [
    kaos,
    kemeja,
    celana,
    jaket,
    sepatu,
    aksesoris,
  ];
}
