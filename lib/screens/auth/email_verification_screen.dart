import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import '../user/home_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../../services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String password;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  bool _isChecking = false;
  bool _isResending = false;
  String? _message;
  bool _isError = false;

  Future<void> _checkConfirmationStatus() async {
    setState(() {
      _isChecking = true;
      _message = null;
    });

    try {
      // Try to sign in
      final user = await _authService.signIn(
        email: widget.email,
        password: widget.password,
      );

      if (user != null && mounted) {
        // Email confirmed! Navigate to appropriate screen
        if (user.isAdmin) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isError = true;
        if (e.toString().contains('belum dikonfirmasi')) {
          _message = 'Email belum dikonfirmasi. Silakan cek inbox email Anda dan klik link konfirmasi.';
        } else {
          _message = e.toString().replaceAll('Exception: ', '');
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _resendConfirmationEmail() async {
    setState(() {
      _isResending = true;
      _message = null;
    });

    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
      
      setState(() {
        _isError = false;
        _message = 'Email konfirmasi telah dikirim ulang!';
      });
    } catch (e) {
      setState(() {
        _isError = true;
        _message = 'Gagal mengirim ulang email: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Email icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 60,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Verifikasi Email Anda',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'Kami telah mengirim link konfirmasi ke:',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Email address
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.email,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                  ),
                ),
                const SizedBox(height: 24),

                // Instructions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.amber,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Silakan buka email Anda dan klik link "Confirm your mail" untuk mengaktifkan akun. Setelah itu, tekan tombol "Cek Status Konfirmasi" di bawah.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.amber[800],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Message (success/error)
                if (_message != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isError ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isError ? Colors.red.withOpacity(0.3) : Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isError ? Icons.error_outline : Icons.check_circle_outline,
                          color: _isError ? Colors.red : Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _message!,
                            style: TextStyle(
                              color: _isError ? Colors.red[800] : Colors.green[800],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // Tips
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tips:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      _buildTip('• Cek folder Spam atau Junk jika tidak menemukan email'),
                      _buildTip('• Email dikirim dari noreply@enaknih-resto.me'),
                      _buildTip('• Link konfirmasi berlaku selama 24 jam'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Check Status Button (Primary)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isChecking ? null : _checkConfirmationStatus,
                    icon: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(
                      _isChecking ? 'Mengecek...' : 'Cek Status Konfirmasi',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Resend Email Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isResending ? null : _resendConfirmationEmail,
                    icon: _isResending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(
                      _isResending ? 'Mengirim...' : 'Kirim Ulang Email',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Back to Login
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('Kembali ke Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
    );
  }
}
