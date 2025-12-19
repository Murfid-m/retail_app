import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../models/user_model.dart';
import '../services/order_service.dart';
import '../services/statistics_service.dart';



class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<OrderModel> _orders = [];
  List<OrderModel> _filteredOrders = [];
  List<OrderModel> _userOrders = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _statistics;
  List<Map<String, dynamic>> _chartData = [];
  
  // Filter properties
  String? _selectedStatus;
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  
  // Statistics date range
  DateTime? _statsStartDate;
  DateTime? _statsEndDate;

  List<OrderModel> get orders => _filteredOrders.isEmpty && _searchQuery.isEmpty && _selectedStatus == null && _startDate == null && _endDate == null
      ? _orders
      : _filteredOrders;
  List<OrderModel> get userOrders => _userOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get statistics => _statistics;
  List<Map<String, dynamic>> get chartData => _chartData;
  String? get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  DateTime? get statsStartDate => _statsStartDate;
  DateTime? get statsEndDate => _statsEndDate;

  Future<OrderModel?> createOrder({
    required UserModel user,
    required List<CartItem> cartItems,
    required String shippingAddress,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final order = await _orderService.createOrder(
        user: user,
        cartItems: cartItems,
        shippingAddress: shippingAddress,
      );
      _userOrders.insert(0, order);
      _isLoading = false;
      notifyListeners();
      return order;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> loadUserOrders(String oderId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _userOrders = await _orderService.getUserOrders(oderId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Admin functions
  Future<void> loadAllOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _orderService.getAllOrders();
      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _orderService.updateOrderStatus(orderId, status);
      
      // Update local list
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final updatedOrder = OrderModel(
          id: _orders[index].id,
          oderId: _orders[index].oderId,
          userName: _orders[index].userName,
          userPhone: _orders[index].userPhone,
          userEmail: _orders[index].userEmail,
          shippingAddress: _orders[index].shippingAddress,
          items: _orders[index].items,
          totalAmount: _orders[index].totalAmount,
          status: status,
          createdAt: _orders[index].createdAt,
        );
        _orders[index] = updatedOrder;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

Future<void> loadStatistics() async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final statisticsService = StatisticsService();
    final data = await statisticsService.loadStatistics(
      startDate: _statsStartDate,
      endDate: _statsEndDate,
    );

    _statistics = data;

    // Ambil last_7_days untuk chart
    _chartData = (data['last_7_days'] as List)
        .map<Map<String, dynamic>>((e) => {
              'date': e['date'],
              'sales': (e['sales'] as num).toDouble(),
            })
        .toList();
  } catch (e) {
    print('❌ OrderProvider error: $e');
    _error = e.toString();
    _statistics = null;
    _chartData = [];
  }

  _isLoading = false;
  notifyListeners();
}

  void setStatsDateRange(DateTime? startDate, DateTime? endDate) {
    _statsStartDate = startDate;
    _statsEndDate = endDate;
    notifyListeners();
    loadStatistics();
  }

  void clearStatsDateRange() {
    _statsStartDate = null;
    _statsEndDate = null;
    notifyListeners();
    loadStatistics();
  }


  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Filtering methods
  void filterByStatus(String? status) {
    _selectedStatus = status;
    _applyFilters();
    notifyListeners();
  }

  void searchOrders(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterByDateRange(DateTime? startDate, DateTime? endDate) {
    _startDate = startDate;
    _endDate = endDate;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredOrders = _orders;

    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      _filteredOrders = _filteredOrders
          .where((o) => o.status.toLowerCase() == _selectedStatus!.toLowerCase())
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      _filteredOrders = _filteredOrders
          .where((o) => 
              o.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              o.userEmail.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              o.userPhone.contains(_searchQuery) ||
              o.id.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    if (_startDate != null) {
      _filteredOrders = _filteredOrders
          .where((o) => o.createdAt.isAfter(_startDate!) || o.createdAt.isAtSameMomentAs(_startDate!))
          .toList();
    }

    if (_endDate != null) {
      _filteredOrders = _filteredOrders
          .where((o) => o.createdAt.isBefore(_endDate!.add(const Duration(days: 1))))
          .toList();
    }
  }

  void clearFilters() {
    _selectedStatus = null;
    _searchQuery = '';
    _startDate = null;
    _endDate = null;
    _filteredOrders = [];
    notifyListeners();
  }
}
