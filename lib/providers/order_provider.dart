import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/cart_model.dart';
import '../models/user_model.dart';
import '../services/order_service.dart';
import '../services/statistics_service.dart';



class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<OrderModel> _orders = [];
  List<OrderModel> _userOrders = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _statistics;
  List<Map<String, dynamic>> _chartData = [];

  List<OrderModel> get orders => _orders;
  List<OrderModel> get userOrders => _userOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get statistics => _statistics;
  List<Map<String, dynamic>> get chartData => _chartData;

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
    final data = await statisticsService.loadStatistics();

    _statistics = data;

    // Ambil monthly_sales_trend untuk chart
    _chartData = (data['monthly_sales_trend'] as List)
        .map<Map<String, dynamic>>((e) => {
              'date': DateTime.parse('${e['month']}-01'),
              'sales': (e['sales'] as num).toDouble(),
            })
        .toList();
  } catch (e) {
    _error = e.toString();
    _statistics = null;
    _chartData = [];
  }

  _isLoading = false;
  notifyListeners();
}


  void clearError() {
    _error = null;
    notifyListeners();
  }
}
