import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  String? _pendingVerificationEmail;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _user?.isAdmin ?? false;
  String? get pendingVerificationEmail => _pendingVerificationEmail;

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

  /// Sign up - returns Map with success status and message
  Future<Map<String, dynamic>> signUp({
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
      final result = await _authService.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
        address: address,
      );

      _isLoading = false;
      _pendingVerificationEmail = email;
      notifyListeners();
      return result;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _error};
    }
  }

  /// Verify code
  Future<bool> verifyCode({required String email, required String code}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.verifyCode(email: email, code: code);
      _isLoading = false;

      if (!success) {
        _error = 'Kode verifikasi salah';
      }

      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Resend verification code
  Future<bool> resendVerificationCode(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.resendVerificationCode(email: email);
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in after verification (skip is_verified check since we just verified)
  Future<bool> signInAfterVerification({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.signInAfterVerification(
        email: email,
        password: password,
      );
      _user = user;
      _isLoading = false;
      notifyListeners();
      return user != null;
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
      final errorMsg = e.toString();

      // Check if unverified
      if (errorMsg.contains('UNVERIFIED:')) {
        _pendingVerificationEmail = errorMsg.split('UNVERIFIED:').last;
        _error = 'Email belum diverifikasi';
      } else {
        _error = errorMsg.replaceAll('Exception: ', '');
      }

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

  void clearPendingVerification() {
    _pendingVerificationEmail = null;
    notifyListeners();
  }
}
