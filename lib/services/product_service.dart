import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

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
      await _supabase.storage.from('products').upload(
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

  Future<String> uploadProductImageBytes(Uint8List bytes, String fileName) async {
    try {
      await _supabase.storage.from('products').uploadBinary(
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
}
