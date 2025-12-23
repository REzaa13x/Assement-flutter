import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'donation_history_page.dart'; 
// import 'edit_profile_page.dart'; // Jika perlu import halaman edit (tergantung routing)

// Warna Brand DonGiv
const Color kPrimaryColor = Color(0xFF2972FF);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF757575);

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  // --- [BARU] DATA USER GLOBAL (Agar bisa diedit) ---
  static Map<String, String> userProfile = {
    'name': 'Rizky Ramadhan',
    'email': 'rizky.dev@gmail.com',
    'phone': '081234567890',
    'image': 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg',
  };

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  
  // Helper Format Uang Ringkas
  String _formatCompactCurrency(int amount) {
    if (amount >= 1000000000) {
       double val = amount / 1000000000;
       return "Rp ${val.toStringAsFixed(1).replaceAll('.0', '')}M";
    } else if (amount >= 1000000) {
      double val = amount / 1000000;
      return "Rp ${val.toStringAsFixed(1).replaceAll('.0', '')}jt";
    } else if (amount >= 1000) {
       double val = amount / 1000;
       return "Rp ${val.toStringAsFixed(0)}rb";
    }
    return "Rp $amount";
  }

  @override
  Widget build(BuildContext context) {
    // Hitung Total Donasi Real-time
    int totalDonation = 0;
    int totalPrograms = 0;

    if (DonationHistoryPage.globalHistoryData.isNotEmpty) {
      totalDonation = DonationHistoryPage.globalHistoryData
          .where((item) => item['status'] == 'Berhasil')
          .fold(0, (sum, item) => sum + (int.tryParse(item['amount'].toString()) ?? 0));
      
      totalPrograms = DonationHistoryPage.globalHistoryData.length;
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER PROFIL
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Background Gradient
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0052CC), Color(0xFF2972FF)],
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                ),
                const Positioned(
                  top: 60,
                  child: Text(
                    "Profil Saya",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Kartu Profil
                Positioned(
                  bottom: -60,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // FOTO PROFIL (Mengambil dari Static Data)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: ProfilePage.userProfile['image']!, // <--- UPDATED
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.grey[200]),
                              errorWidget: (context, url, error) => const Icon(Icons.person),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // NAMA USER (Mengambil dari Static Data)
                        Text(
                          ProfilePage.userProfile['name']!, // <--- UPDATED
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary),
                        ),
                        const SizedBox(height: 4),
                        // EMAIL USER (Mengambil dari Static Data)
                        Text(
                          ProfilePage.userProfile['email']!, // <--- UPDATED
                          style: const TextStyle(fontSize: 14, color: kTextSecondary),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Donatur Aktif 🏅",
                            style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 80),

            // STATISTIK KEBAIKAN
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildStatCard(
                    "Total Donasi", 
                    _formatCompactCurrency(totalDonation), 
                    Icons.monetization_on_outlined, 
                    Colors.orange
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    "Program", 
                    totalPrograms.toString(), 
                    Icons.favorite_outline, 
                    Colors.red
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // MENU OPTIONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildMenuSection(
                    title: "Akun",
                    items: [
                      // --- [UPDATED] TOMBOL EDIT PROFIL ---
                      _buildMenuItem(Icons.person_outline, "Edit Profil", () {
                        // Navigasi ke Edit Profil dan Refresh saat kembali
                        Navigator.pushNamed(context, '/edit_profile').then((_) {
                           setState(() {}); // Refresh agar Nama berubah jika diedit
                        });
                      }),
                      // ------------------------------------
                      
                      _buildMenuItem(Icons.history, "Riwayat Donasi", () {
                         Navigator.pushNamed(context, '/donation_history').then((_) {
                           setState(() {});
                         });
                      }),
                      _buildMenuItem(Icons.credit_card, "Metode Pembayaran", () {}),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildMenuSection(
                    title: "Lainnya",
                    items: [
                      _buildMenuItem(Icons.info_outline, "Tentang Aplikasi", () {}),
                      _buildMenuItem(Icons.help_outline, "Bantuan & Dukungan", () {}),
                      _buildMenuItem(Icons.logout, "Keluar", () {
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      }, isDestructive: true),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            const Text("Versi 1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // (Widget Helper di bawah SAMA SAJA, tidak berubah)
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary)),
            Text(label, style: const TextStyle(fontSize: 12, color: kTextSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: kTextSecondary)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : kPrimaryColor),
      title: Text(
        title, 
        style: TextStyle(
          color: isDestructive ? Colors.red : kTextPrimary,
          fontWeight: isDestructive ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}