import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'email_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EmailService _emailService = EmailService();

  User? get currentUser => _supabase.auth.currentUser;
  
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Generate 6-digit verification code
  String _generateVerificationCode() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  /// Sign up - creates user and sends verification code via Resend
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
  }) async {
    try {
      // Generate verification code
      final verificationCode = _generateVerificationCode();
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'address': address,
        },
      );

      if (response.user != null) {
        // Create user profile with verification code (is_verified = false)
        try {
          await _supabase.from('users').upsert({
            'id': response.user!.id,
            'email': email,
            'name': name,
            'phone': phone,
            'address': address,
            'is_admin': false,
            'verification_code': verificationCode,
            'is_verified': false,
            'created_at': DateTime.now().toIso8601String(),
          }, onConflict: 'id');
          
          print('User profile created with verification code');
        } catch (dbError) {
          print('Database error creating profile: $dbError');
        }

        // Send verification code via Resend (Edge Function)
        final emailSent = await _emailService.sendVerificationCode(
          email: email,
          name: name,
          verificationCode: verificationCode,
        );

        // Sign out - user needs to verify first
        await _supabase.auth.signOut();

        return {
          'success': true,
          'userId': response.user!.id,
          'email': email,
          'name': name,
          'emailSent': emailSent,
          'message': emailSent 
            ? 'Kode verifikasi telah dikirim ke email Anda'
            : 'Registrasi berhasil, tapi gagal mengirim email. Silakan minta kirim ulang.',
        };
      }
      return {'success': false, 'message': 'Registrasi gagal'};
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Gagal mendaftar: $e');
    }
  }

  /// Verify user with 6-digit code
  Future<bool> verifyCode({
    required String email,
    required String code,
  }) async {
    try {
      print('Verifying code for email: $email');
      print('Code entered: $code');
      
      // First, get the user to see what code is stored
      final userCheck = await _supabase
          .from('users')
          .select('verification_code, is_verified')
          .eq('email', email)
          .maybeSingle();
      
      print('User data from DB: $userCheck');
      print('Stored code: ${userCheck?['verification_code']}');
      print('Is verified: ${userCheck?['is_verified']}');
      
      if (userCheck == null) {
        print('User not found in database');
        return false;
      }
      
      // Check if code matches
      if (userCheck['verification_code'] != code) {
        print('Code does not match');
        return false;
      }
      
      // Update user as verified using RPC or direct update
      print('Code matches! Updating is_verified to true...');
      
      final updateResponse = await _supabase
          .from('users')
          .update({
            'is_verified': true,
            'verification_code': null,
          })
          .eq('email', email)
          .select();
      
      print('Update response: $updateResponse');
      
      // Verify the update worked
      final verifyUpdate = await _supabase
          .from('users')
          .select('is_verified')
          .eq('email', email)
          .maybeSingle();
      
      print('After update - is_verified: ${verifyUpdate?['is_verified']}');
      
      if (verifyUpdate?['is_verified'] == true) {
        print('User verified successfully!');
        return true;
      } else {
        print('Update failed - is_verified still false');
        return false;
      }
    } catch (e) {
      print('Verification error: $e');
      return false;
    }
  }

  /// Resend verification code
  Future<bool> resendVerificationCode({
    required String email,
  }) async {
    try {
      // Get user from database
      final user = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (user == null) {
        throw Exception('Email tidak ditemukan');
      }

      if (user['is_verified'] == true) {
        throw Exception('Email sudah diverifikasi');
      }

      // Generate new code
      final newCode = _generateVerificationCode();

      // Update code in database
      await _supabase
          .from('users')
          .update({'verification_code': newCode})
          .eq('email', email);

      // Send new code via email
      return await _emailService.sendVerificationCode(
        email: email,
        name: user['name'] ?? '',
        verificationCode: newCode,
      );
    } catch (e) {
      print('Resend code error: $e');
      rethrow;
    }
  }

  /// Sign in after verification - skip is_verified check (just verified)
  Future<UserModel?> signInAfterVerification({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Get profile from database - no verification check
        final profile = await getUserProfile(response.user!.id);
        return profile;
      }
      return null;
    } on AuthException catch (e) {
      print('Auth error after verification: ${e.message}');
      throw Exception(e.message);
    } catch (e) {
      print('Sign in after verification error: $e');
      rethrow;
    }
  }

  /// Sign in - checks if user is verified first
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
        
        print('Login - User profile: ${profile?.toJson()}');
        print('Login - isVerified: ${profile?.isVerified}');
        
        if (profile != null) {
          // Check if user is verified
          if (profile.isVerified != true) {
            print('Login - User NOT verified, redirecting to verification');
            await _supabase.auth.signOut();
            throw Exception('UNVERIFIED:${profile.email}');
          }
          print('Login - User IS verified, proceeding');
          return profile;
        }
        
        // If no profile in DB, create one from user metadata
        final metadata = response.user!.userMetadata;
        final name = metadata?['name'] ?? email.split('@').first;
        final phone = metadata?['phone'] ?? '';
        final address = metadata?['address'] ?? '';
        
        try {
          await _supabase.from('users').insert({
            'id': response.user!.id,
            'email': email,
            'name': name,
            'phone': phone,
            'address': address,
            'is_admin': false,
            'is_verified': true, // If created from metadata, consider verified
            'created_at': DateTime.now().toIso8601String(),
          });
          
          return await getUserProfile(response.user!.id);
        } catch (e) {
          print('Error creating profile: $e');
          return UserModel(
            id: response.user!.id,
            email: email,
            name: email.split('@').first,
            phone: '',
            address: '',
            isAdmin: false,
            isVerified: true,
            createdAt: DateTime.now(),
          );
        }
      }
      return null;
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
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

      return UserModel.fromJson(response);
    } catch (e) {
      print('getUserProfile error: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _supabase.from('users').update({
      'name': user.name,
      'phone': user.phone,
      'address': user.address,
      'avatar_url': user.avatarUrl,
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
