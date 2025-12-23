import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../models/user_model.dart';
import '../auth/login_screen.dart';
import 'help_support_screen.dart';
import 'change_password_screen.dart';
import 'wishlist_screen.dart';
import 'cart_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _localeInitialized = false;
  bool _notificationsEnabled = true;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('id_ID', null);
    if (mounted) {
      setState(() {
        _localeInitialized = true;
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploadingAvatar = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;
      if (user == null) return;

      // Upload to Supabase Storage
      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last.toLowerCase();
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'avatars/$fileName';

      // Map file extension to proper MIME type
      String contentType;
      switch (fileExt) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        case 'webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg'; // fallback
      }

      final supabase = Supabase.instance.client;
      
      // Delete old avatar if exists
      if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
        try {
          final oldPath = user.avatarUrl!.split('/').last;
          await supabase.storage.from('user-avatars').remove(['avatars/$oldPath']);
        } catch (e) {
          // Ignore if old file doesn't exist
        }
      }

      // Upload new avatar
      await supabase.storage.from('user-avatars').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );

      // Get public URL
      final avatarUrl = supabase.storage.from('user-avatars').getPublicUrl(filePath);

      // Update user profile
      final updatedUser = user.copyWith(avatarUrl: avatarUrl);
      await authProvider.updateProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupload foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _editField({
    required String title,
    required String currentValue,
    required String fieldName,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) async {
    String? result;
    await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController(text: currentValue);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Edit $title'),
              content: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                maxLines: maxLines,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (validator != null) {
                      final error = validator(value);
                      if (error != null) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                        return;
                      }
                    }
                    result = value;
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && result != currentValue) {
      await _saveProfile(fieldName, result!);
    }
  }

  Future<void> _saveProfile(String field, String value) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      // Create updated user based on field
      final updatedUser = user.copyWith(
        name: field == 'name' ? value : user.name,
        phone: field == 'phone' ? value : user.phone,
        address: field == 'address' ? value : user.address,
      );

      await authProvider.updateProfile(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, WishlistProvider>(
      builder: (context, authProvider, wishlistProvider, child) {
        final user = authProvider.user;
        if (user == null) return const Center(child: Text('User tidak ditemukan'));

        // Show loading until locale is initialized
        if (!_localeInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              // Header with gradient (no AppBar leading/actions to avoid double navbar)
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                automaticallyImplyLeading: false, // Remove back button
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        // Avatar with edit button
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                              child: Hero(
                                tag: 'profile-avatar',
                                child: CircleAvatar(
                                  radius: 45,
                                  backgroundColor: Colors.white,
                                  child: _isUploadingAvatar
                                      ? const CircularProgressIndicator()
                                      : user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                          ? CircleAvatar(
                                              radius: 42,
                                              backgroundImage: CachedNetworkImageProvider(user.avatarUrl!),
                                            )
                                          : CircleAvatar(
                                              radius: 42,
                                              backgroundColor: Colors.grey[200],
                                              child: Text(
                                                (user.name ?? 'U').substring(0, 1).toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 32,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).primaryColor,
                                                ),
                                              ),
                                            ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    size: 16,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? const Color(0xFFFFC20E)
                                        : Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          user.name ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistics Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.favorite,
                              count: wishlistProvider.wishlistCount,
                              label: 'Wishlist',
                              color: Colors.red,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WishlistScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              icon: Icons.shopping_cart,
                              count: 0,
                              label: 'Keranjang',
                              color: Colors.blue,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CartScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Personal Information
                      _buildSectionTitle('Informasi Pribadi'),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        icon: Icons.person_outline,
                        title: 'Nama Lengkap',
                        value: user.name ?? '-',
                        onEdit: () => _editField(
                          title: 'Nama',
                          currentValue: user.name ?? '',
                          fieldName: 'name',
                          hint: 'Masukkan nama lengkap',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama harus diisi';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        icon: Icons.phone_outlined,
                        title: 'Nomor HP',
                        value: user.phone ?? '-',
                        onEdit: () => _editField(
                          title: 'Nomor HP',
                          currentValue: user.phone ?? '',
                          fieldName: 'phone',
                          hint: 'Masukkan nomor HP',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nomor HP harus diisi';
                            }
                            if (value.length < 10) {
                              return 'Nomor HP tidak valid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        icon: Icons.location_on_outlined,
                        title: 'Alamat',
                        value: user.address ?? '-',
                        maxLines: 2,
                        onEdit: () => _editField(
                          title: 'Alamat',
                          currentValue: user.address ?? '',
                          fieldName: 'address',
                          hint: 'Masukkan alamat lengkap',
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Alamat harus diisi';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Account Information
                      _buildSectionTitle('Informasi Akun'),
                      const SizedBox(height: 16),
                      _buildInfoCard(
                        icon: Icons.email_outlined,
                        title: 'Email',
                        value: user.email ?? '-',
                        showEdit: false,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        icon: Icons.calendar_today_outlined,
                        title: 'Bergabung Sejak',
                        value: user.createdAt != null
                            ? DateFormat('dd MMMM yyyy', 'id_ID').format(user.createdAt!)
                            : '-',
                        showEdit: false,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        icon: Icons.verified_user_outlined,
                        title: 'Status Akun',
                        value: user.isAdmin ? 'Admin' : 'User',
                        showEdit: false,
                      ),
                      const SizedBox(height: 32),

                      // Settings & Actions
                      _buildSectionTitle('Pengaturan'),
                      const SizedBox(height: 16),
                      _buildMenuTile(
                        icon: Icons.lock_outline,
                        title: 'Ubah Password',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),                      const SizedBox(height: 8),                      _buildMenuTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifikasi',
                        subtitle: _notificationsEnabled ? 'Aktif' : 'Nonaktif',
                        trailing: Switch(
                          value: _notificationsEnabled,
                          onChanged: (value) {
                            setState(() {
                              _notificationsEnabled = value;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'Notifikasi diaktifkan'
                                      : 'Notifikasi dinonaktifkan',
                                ),
                              ),
                            );
                          },
                        ),
                      ),                      const SizedBox(height: 8),                      _buildMenuTile(
                        icon: Icons.help_outline,
                        title: 'Bantuan & Dukungan',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpSupportScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildMenuTile(
                        icon: Icons.info_outline,
                        title: 'Tentang Aplikasi',
                        subtitle: 'Versi 1.0.0',
                        onTap: () {
                          _showAboutDialog();
                        },
                      ),
                      const SizedBox(height: 32),

                      // Logout button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          onPressed: () => _handleLogout(authProvider),
                          icon: const Icon(Icons.logout),
                          label: const Text('Keluar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required int count,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFFFC20E)
                    : color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    bool showEdit = true,
    int maxLines = 1,
    VoidCallback? onEdit,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: showEdit ? onEdit : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFFFC20E).withOpacity(0.1)
                      : Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFFFC20E)
                      : Theme.of(context).primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (showEdit) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.edit_outlined,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFFFC20E).withOpacity(0.1)
                : Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFFFC20E)
                : Theme.of(context).primaryColor,
            size: 20,
          ),
        ),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: trailing ?? const Icon(Icons.chevron_right),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang Aplikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.shopping_bag,
                size: 64,
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFFFC20E)
                    : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '3F',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Versi 1.0.0',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Aplikasi retail modern dengan fitur lengkap untuk mengelola produk, pesanan, dan wishlist.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(AuthProvider authProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await authProvider.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false,
        );
      }
    }
  }
}
