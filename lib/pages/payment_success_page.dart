import 'package:flutter/material.dart';
import 'donation_history_page.dart'; // <--- 1. WAJIB IMPORT INI

const Color kPrimaryColor = Color(0xFF2972FF);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF757575);

class PaymentSuccessPage extends StatefulWidget {
  const PaymentSuccessPage({Key? key}) : super(key: key);

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  // 2. FLAG AGAR DATA TIDAK DOUBLE SAAT REBUILD
  bool _isDataSaved = false; 

  // Format Tanggal Manual
  String get _transactionTime {
    final now = DateTime.now();
    return "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  // ID Transaksi Acak
  final String _transactionRef = "TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Menangkap Data dari Halaman Form
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    final String paymentMethod = args?['method'] ?? "Metode Pembayaran";
    final String nominalStr = args?['amount'] ?? "0";
    final String title = args?['campaignTitle'] ?? "Donasi";
    final String category = args?['campaignCategory'] ?? "Umum";

    // -------------------------------------------------------------
    // 3. LOGIKA PENYIMPANAN DATA KE HISTORY (SANGAT PENTING!)
    // -------------------------------------------------------------
    if (!_isDataSaved && args != null) {
      // Kita tambahkan data baru ke List Global di halaman History
      DonationHistoryPage.globalHistoryData.add({
        'title': title,
        'amount': int.tryParse(nominalStr) ?? 0, // Konversi String ke Int
        'date': _transactionTime,
        'status': 'Berhasil',
        'category': category,
      });
      
      // Kunci agar tidak disimpan ulang kalau layar di-refresh
      _isDataSaved = true; 
    }
    // -------------------------------------------------------------

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              // Animasi Centang
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50, 
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        color: Colors.green, 
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          )
                        ],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              const Text(
                "Pembayaran Berhasil",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Terima kasih atas partisipasi Anda.\nDonasi telah berhasil diverifikasi sistem.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: kTextSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // KARTU BUKTI TRANSAKSI
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow("Status", "BERHASIL", color: Colors.green, isBold: true),
                    const Divider(height: 24),
                    _buildReceiptRow("Tanggal", _transactionTime),
                    const SizedBox(height: 12),
                    _buildReceiptRow("No. Referensi", _transactionRef),
                    const SizedBox(height: 12),
                    _buildReceiptRow("Metode", paymentMethod), 
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // TOMBOL RIWAYAT
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Pindah ke history (sekarang datanya sudah ada!)
                    Navigator.pushReplacementNamed(context, '/donation_history');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: kPrimaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Lihat Riwayat Donasi", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // TOMBOL BERANDA
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context, 
                      '/', 
                      (route) => false
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Kembali ke Beranda", 
                    style: TextStyle(fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: kTextSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? kTextPrimary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}