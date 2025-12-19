import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthService {
  SupabaseClient? _supabase;

  /// Optional injection for tests. If [client] is not provided, the
  /// real Supabase client will be resolved lazily when first needed.
  AuthService([SupabaseClient? client]) : _supabase = client;

  SupabaseClient get _client => _supabase ??= Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign up - returns UserModel if successful (no email confirmation needed)
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      final client = _client;
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'phone': phone, 'address': address},
      );

      if (response.user != null) {
        // Create user profile in database using upsert to avoid conflicts
        try {
          await client.from('users').upsert({
            'id': response.user!.id,
            'email': email,
            'name': name,
            'phone': phone,
            'address': address,
            'is_admin': false,
            'created_at': DateTime.now().toIso8601String(),
          }, onConflict: 'id');

          print('User profile created successfully for ${response.user!.id}');
        } catch (dbError) {
          print('Database error creating profile: $dbError');
          // Try alternative: maybe RLS issue, profile will be created on next login
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
      final client = _client;
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Get profile from database
        final profile = await getUserProfile(response.user!.id);
        if (profile != null) {
          return profile;
        }

        // If no profile in DB, create one from user metadata
        final metadata = response.user!.userMetadata;
        final name = metadata?['name'] ?? email.split('@').first;
        final phone = metadata?['phone'] ?? '';
        final address = metadata?['address'] ?? '';

        try {
          await client.from('users').insert({
            'id': response.user!.id,
            'email': email,
            'name': name,
            'phone': phone,
            'address': address,
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
      throw Exception('$e');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _client
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
    await _client
        .from('users')
        .update({
          'name': user.name,
          'phone': user.phone,
          'address': user.address,
        })
        .eq('id', user.id);
  }

  Future<bool> isAdmin(String userId) async {
    try {
      final response = await _client
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
