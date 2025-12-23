import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Warna Brand
const Color kPrimaryColor = Color(0xFF2972FF);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF757575);

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Key untuk Validasi Form
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    // Data Mockup (Nanti diganti data dari User Model)
    _nameController = TextEditingController(text: "Rizky Ramadhan");
    _emailController = TextEditingController(text: "rizky.dev@gmail.com");
    _phoneController = TextEditingController(text: "081234567890");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Menutup keyboard saat tap di luar area input
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Edit Profil',
            style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // Tombol Save Text di atas (Opsional, gaya iOS)
            TextButton(
              onPressed: _saveProfile,
              child: const Text("Simpan", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 1. FOTO PROFIL EDITABLE
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: kBackgroundColor, width: 4),
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: 'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.grey[200]),
                            errorWidget: (context, url, error) => const Icon(Icons.person),
                          ),
                        ),
                      ),
                      // Ikon Kamera
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            // Logika Ganti Foto (Nanti)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Fitur ganti foto akan segera hadir")),
                            );
                          },
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: kPrimaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),

                // 2. FORM FIELDS
                _buildModernTextField(
                  controller: _nameController,
                  label: "Nama Lengkap",
                  icon: Icons.person_outline_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Nama tidak boleh kosong';
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                _buildModernTextField(
                  controller: _emailController,
                  label: "Email",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Masukkan email yang valid';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                _buildModernTextField(
                  controller: _phoneController,
                  label: "Nomor Telepon",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 50),

                // 3. TOMBOL SIMPAN UTAMA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Simpan Perubahan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // LOGIKA SIMPAN YANG BENAR
  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      
      // 1. UPDATE DATA KE VARIABLE GLOBAL (BAGIAN INI YANG HILANG SEBELUMNYA)
      setState(() {
        ProfilePage.userProfile['name'] = _nameController.text;
        ProfilePage.userProfile['email'] = _emailController.text;
        ProfilePage.userProfile['phone'] = _phoneController.text;
      });

      // 2. Tutup keyboard
      FocusScope.of(context).unfocus();

      // 3. Tampilkan Pesan Sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 1),
        ),
      );
      
      // 4. Kembali ke halaman profil
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pop(context); 
      });
    }
  }

  // WIDGET TEXT FIELD REUSABLE
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: "Masukkan $label",
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: kBackgroundColor, // Warna abu-abu muda lembut
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none, // Hilangkan garis border default
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}