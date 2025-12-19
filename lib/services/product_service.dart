import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import 'email_service.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EmailService _emailService = EmailService();
  
  // Threshold for low stock warning
  static const int lowStockThreshold = 3;

  Future<List<ProductModel>> getAllProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((product) => ProductModel.fromJson(product))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('category', category)
          .order('created_at', ascending: false);

      return (response as List)
          .map((product) => ProductModel.fromJson(product))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .ilike('name', '%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((product) => ProductModel.fromJson(product))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<ProductModel?> getProductById(String id) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', id)
          .single();

      return ProductModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Admin functions
  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      final response = await _supabase
          .from('products')
          .insert(product.toJsonWithoutId())
          .select()
          .single();

      return ProductModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<ProductModel> updateProduct(ProductModel product) async {
    try {
      final response = await _supabase
          .from('products')
          .update(product.toJsonWithoutId())
          .eq('id', product.id)
          .select()
          .single();

      return ProductModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _supabase.from('products').delete().eq('id', id);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadProductImage(File file, String fileName) async {
    try {
      await _supabase.storage
          .from('products')
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final url = _supabase.storage.from('products').getPublicUrl(fileName);
      return url;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadProductImageBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      await _supabase.storage
          .from('products')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final url = _supabase.storage.from('products').getPublicUrl(fileName);
      return url;
    } catch (e) {
      rethrow;
    }
  }

  /// Update product stock after order is placed
  Future<void> updateProductStock(String productId, int quantityOrdered) async {
    try {
      // Get current stock
      final response = await _supabase
          .from('products')
          .select('stock, name, category')
          .eq('id', productId)
          .single();
      
      final currentStock = response['stock'] as int;
      final newStock = currentStock - quantityOrdered;
      
      // Update stock
      await _supabase
          .from('products')
          .update({'stock': newStock < 0 ? 0 : newStock})
          .eq('id', productId);
      
      print('Updated stock for product $productId: $currentStock -> $newStock');
    } catch (e) {
      print('Error updating product stock: $e');
      rethrow;
    }
  }

  /// Get all products with low stock (stock <= threshold)
  Future<List<ProductModel>> getLowStockProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .lte('stock', lowStockThreshold)
          .order('stock', ascending: true);

      return (response as List)
          .map((product) => ProductModel.fromJson(product))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Check stock levels and send notification if any products are low
  Future<void> checkAndNotifyLowStock() async {
    try {
      final lowStockProducts = await getLowStockProducts();
      
      if (lowStockProducts.isEmpty) {
        print('No low stock products found');
        return;
      }

      print('Found ${lowStockProducts.length} low stock products');

      final productsData = lowStockProducts.map((product) => {
        'productName': product.name,
        'currentStock': product.stock,
        'category': product.category,
      }).toList();

      await _emailService.notifyLowStock(products: productsData);
    } catch (e) {
      print('Error checking low stock: $e');
    }
  }

  /// Check specific products for low stock after order
  Future<void> checkOrderedProductsStock(List<String> productIds) async {
    try {
      final List<Map<String, dynamic>> lowStockProducts = [];

      for (final productId in productIds) {
        final response = await _supabase
            .from('products')
            .select('name, stock, category')
            .eq('id', productId)
            .single();
        
        final stock = response['stock'] as int;
        if (stock <= lowStockThreshold) {
          lowStockProducts.add({
            'productName': response['name'],
            'currentStock': stock,
            'category': response['category'],
          });
        }
      }

      if (lowStockProducts.isNotEmpty) {
        print('${lowStockProducts.length} products now have low stock after order');
        await _emailService.notifyLowStock(products: lowStockProducts);
      }
    } catch (e) {
      print('Error checking ordered products stock: $e');
    }
  }
}
