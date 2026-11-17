import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/auth.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  bool _isLoggingOut = false;
  bool _hasError = false;
  String _errorMessage = '';
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Dalam implementasi sebenarnya, Anda perlu mengambil token dari storage
      // Misalnya dari SharedPreferences atau state management
      String? token = await _getToken(); // Implementasikan fungsi ini sesuai kebutuhan

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await ProfileRepository.getProfile(token: token);
      if (!mounted || _isLoggingOut) return;

      if (response.data != null) {
        setState(() {
          _userProfile = response.data;
          _isLoading = false;
        });
      } else {
        throw Exception(response.message ?? 'Gagal memuat profil');
      }
    } catch (e) {
      if (!mounted || _isLoggingOut) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  // Fungsi untuk mendapatkan token - implementasikan sesuai dengan state management Anda
  Future<String?> _getToken() async {
    return await AuthService.getToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _hasError
          ? _buildErrorState()
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildProfileContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat profil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2972FF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
            TextButton(
              onPressed: _isLoggingOut ? null : _logout,
              child: Text(_isLoggingOut ? 'Sedang keluar...' : 'Keluar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_userProfile == null) {
      return const Center(child: Text('Data profil tidak tersedia'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF2972FF),
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: _userProfile!.photo != null
                          ? CachedNetworkImage(
                              imageUrl: _userProfile!.photo!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300]!,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300]!,
                                child: const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey[300]!,
                              child: const Icon(
                                Icons.person,
                                size: 40,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2972FF),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 16,
                        color: Color(0xFF2972FF),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _userProfile!.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userProfile!.email,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Koin: ${_userProfile!.coins ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Profile options
        _buildProfileOption(
          icon: Icons.person,
          title: 'Edit Profil',
          onTap: () {
            // Navigate to edit profile page
            Navigator.pushNamed(context, '/edit_profile');
          },
        ),
        _buildProfileOption(
          icon: Icons.history,
          title: 'Riwayat Donasi',
          onTap: () {
            Navigator.pushNamed(context, '/donation_history');
          },
        ),
        _buildProfileOption(
          icon: Icons.campaign_outlined,
          title: 'Riwayat Kampanye',
          onTap: () {
            Navigator.pushNamed(context, '/campaign_history');
          },
        ),
        _buildProfileOption(
          icon: Icons.volunteer_activism,
          title: 'Riwayat Relawan',
          onTap: () {
            Navigator.pushNamed(context, '/volunteer_history');
          },
        ),
        _buildProfileOption(
          icon: Icons.card_membership_rounded,
          title: 'Sertifikat Saya',
          onTap: () {
            Navigator.pushNamed(context, '/my_certificates');
          },
        ),
        _buildProfileOption(
          icon: Icons.notifications_none,
          title: 'Notifikasi',
          onTap: () {
            Navigator.pushNamed(context, '/notifications');
          },
        ),
        _buildProfileOption(
          icon: Icons.rate_review_outlined,
          title: 'Ulasan & Rating',
          onTap: () {
            Navigator.pushNamed(context, '/reviews');
          },
        ),
        _buildProfileOption(
          icon: Icons.monetization_on,
          title: 'Mulai Kampanye',
          onTap: () {
            Navigator.pushNamed(context, '/start_campaign');
          },
        ),

        const SizedBox(height: 24),

        // Logout option
        _buildProfileOption(
          icon: Icons.logout,
          title: _isLoggingOut ? 'Sedang keluar...' : 'Keluar',
          titleColor: Colors.red,
          iconColor: Colors.red,
          onTap: _isLoggingOut ? null : _logout,
        ),

        // About section
        _buildProfileOption(
          icon: Icons.info,
          title: 'Tentang Kami',
          onTap: () {
            Navigator.pushNamed(context, '/about_us');
          },
        ),
        _buildProfileOption(
          icon: Icons.help,
          title: 'Bantuan',
          onTap: () {
            Navigator.pushNamed(context, '/help');
          },
        ),
      ],
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (iconColor ?? const Color(0xFF2972FF)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: iconColor ?? const Color(0xFF2972FF),
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: titleColor ?? Colors.black,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      final token = await _getToken();
      try {
        await NotificationService.unregisterCurrentToken()
            .timeout(const Duration(seconds: 2));
      } catch (_) {
        // Device registration must not prevent local sign out.
      }
      await AuthRepository.logout(token: token);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membersihkan sesi perangkat. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }
}
