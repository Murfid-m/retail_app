import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Create user profile in users table
        try {
          await _supabase.from('users').upsert({
            'id': response.user!.id,
            'email': email,
            'name': name,
            'phone': phone,
            'address': address,
            'is_admin': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (dbError) {
          // If table doesn't exist or other DB error, log it but don't fail auth
          print('Database error creating profile: $dbError');
        }

        return UserModel(
          id: response.user!.id,
          email: email,
          name: name,
          phone: phone,
          address: address,
          isAdmin: false,
          createdAt: DateTime.now(),
        );
      }
      return null;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal mendaftar: $e');
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Get profile from database
        final profile = await getUserProfile(response.user!.id);
        if (profile != null) {
          return profile;
        }
        
        // If no profile in DB, create one
        try {
          await _supabase.from('users').upsert({
            'id': response.user!.id,
            'email': email,
            'name': email.split('@').first,
            'phone': '',
            'address': '',
            'is_admin': false,
            'created_at': DateTime.now().toIso8601String(),
          });
          
          // Fetch again to get the proper data
          return await getUserProfile(response.user!.id);
        } catch (e) {
          print('Error creating profile: $e');
          // Return basic user model as fallback
          return UserModel(
            id: response.user!.id,
            email: email,
            name: email.split('@').first,
            phone: '',
            address: '',
            isAdmin: false,
            createdAt: DateTime.now(),
          );
        }
      }
      return null;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal masuk: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      print('getUserProfile response: $response'); // Debug log
      final user = UserModel.fromJson(response);
      print('User isAdmin: ${user.isAdmin}'); // Debug log
      return user;
    } catch (e) {
      print('getUserProfile error: $e'); // Debug log
      return null;
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _supabase.from('users').update({
      'name': user.name,
      'phone': user.phone,
      'address': user.address,
    }).eq('id', user.id);
  }

  Future<bool> isAdmin(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('is_admin')
          .eq('id', userId)
          .single();
      return response['is_admin'] ?? false;
    } catch (e) {
      return false;
    }
  }
}
