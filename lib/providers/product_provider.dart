import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedCategory;
  String _searchQuery = '';

  List<ProductModel> get products =>
      _filteredProducts.isEmpty &&
          _searchQuery.isEmpty &&
          _selectedCategory == null
      ? _products
      : _filteredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _products = await _productService.getAllProducts();
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void filterByCategory(String? category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredProducts = _products;

    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      _filteredProducts = _filteredProducts
          .where((p) => p.category == _selectedCategory)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      _filteredProducts = _filteredProducts
          .where(
            (p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
  }

  void clearFilters() {
    _selectedCategory = null;
    _searchQuery = '';
    _filteredProducts = [];
    notifyListeners();
  }

  // Admin functions
  Future<bool> addProduct(ProductModel product) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newProduct = await _productService.createProduct(product);
      _products.insert(0, newProduct);
      _applyFilters();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedProduct = await _productService.updateProduct(product);
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = updatedProduct;
      }
      _applyFilters();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _productService.deleteProduct(id);
      _products.removeWhere((p) => p.id == id);
      _applyFilters();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
