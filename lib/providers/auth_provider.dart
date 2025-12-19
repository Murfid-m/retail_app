import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _user = await _authService.getUserProfile(currentUser.id);
        notifyListeners();
      }

      // Listen to auth state changes if Supabase is available. If not
      // initialized (e.g., in test environment), accessing authStateChanges
      // may throw — so wrap in try/catch.
      try {
        _authService.authStateChanges.listen((state) async {
          if (state.session?.user != null) {
            _user = await _authService.getUserProfile(state.session!.user.id);
          } else {
            _user = null;
          }
          notifyListeners();
        });
      } catch (_) {
        // Supabase not initialized or not available in this environment.
      }
    } catch (_) {
      // Supabase.instance may not be initialized (e.g., during widget tests).
      // Skip initialization in that case to avoid crashing tests.
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
        address: address,
      );
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _authService.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile(UserModel user) async {
    try {
      await _authService.updateUserProfile(user);
      _user = user;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
