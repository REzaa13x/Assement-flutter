import 'package:flutter/material.dart';

// Warna Brand DonGiv
const Color kPrimaryColor = Color(0xFF2972FF);
const Color kSecondaryColor = Color(0xFF0052CC); // Warna biru lebih gelap untuk gradasi
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF888888);

class DonationHistoryPage extends StatefulWidget {
  const DonationHistoryPage({Key? key}) : super(key: key);

  // --- WADAH DATA GLOBAL (JANGAN DIHAPUS) ---
  // Static agar data tersimpan meskipun pindah halaman
  static List<Map<String, dynamic>> globalHistoryData = [
    {
      'title': 'Wakaf Air Bersih Desa',
      'amount': 500000,
      'date': '22/12/2025 14:30',
      'status': 'Berhasil',
      'category': 'Infrastruktur',
    },
    {
      'title': 'Beasiswa Anak Yatim',
      'amount': 100000,
      'date': '15/12/2025 09:15',
      'status': 'Berhasil',
      'category': 'Pendidikan',
    },
  ];

  @override
  State<DonationHistoryPage> createState() => _DonationHistoryPageState();
}

class _DonationHistoryPageState extends State<DonationHistoryPage> {

  // Helper Format Rupiah
  String _formatCurrency(int amount) {
    String amountStr = amount.toString();
    String result = '';
    int count = 0;
    for (int i = amountStr.length - 1; i >= 0; i--) {
      result = amountStr[i] + result;
      count++;
      if (count == 3 && i > 0) {
        result = '.' + result;
        count = 0;
      }
    }
    return 'Rp $result';
  }

  @override
  Widget build(BuildContext context) {
    final dataToShow = DonationHistoryPage.globalHistoryData;

    // Hitung Total Donasi
    int totalDonation = dataToShow
        .where((item) => item['status'] == 'Berhasil')
        .fold(0, (sum, item) => sum + (int.tryParse(item['amount'].toString()) ?? 0));

    return Scaffold(
      backgroundColor: kBackgroundColor,
      // AppBar Transparan karena kita pakai Custom Header
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Riwayat Kebaikan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // 1. MODERN GRADIENT HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 100, 24, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kPrimaryColor, kSecondaryColor],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              boxShadow: [
                BoxShadow(color: Color(0x402972FF), blurRadius: 20, offset: Offset(0, 10)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text("Total Donasi Anda", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _formatCurrency(totalDonation),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36, // Font Besar
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.volunteer_activism, color: Colors.white70, size: 14),
                    SizedBox(width: 6),
                    Text(
                      "Terima kasih telah menjadi #OrangBaik", 
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)
                    ),
                  ],
                )
              ],
            ),
          ),

          // 2. LIST RIWAYAT
          Expanded(
            child: dataToShow.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    itemCount: dataToShow.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      // Balik urutan (Terbaru di atas)
                      final item = dataToShow[dataToShow.length - 1 - index];
                      return _buildModernHistoryCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
            child: Icon(Icons.receipt_long_rounded, size: 50, color: Colors.grey[300]),
          ),
          const SizedBox(height: 16),
          Text("Belum ada riwayat donasi", style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildModernHistoryCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Bisa tambahkan navigasi ke detail transaksi jika mau
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Kategori dengan Background Halus
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(item['category']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getCategoryIcon(item['category']),
                    color: _getCategoryColor(item['category']),
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Detail Transaksi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['title'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kTextPrimary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['date'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatCurrency(int.tryParse(item['amount'].toString()) ?? 0),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: kPrimaryColor,
                            ),
                          ),
                          _buildStatusBadge(item['status']),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    if (status == 'Berhasil') {
      color = Colors.green;
    } else {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Pendidikan': return Icons.school_rounded;
      case 'Medis': return Icons.medical_services_rounded;
      case 'Bencana': return Icons.flood_rounded;
      case 'Infrastruktur': return Icons.water_drop_rounded;
      default: return Icons.volunteer_activism_rounded;
    }
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Pendidikan': return Colors.orange;
      case 'Medis': return Colors.red;
      case 'Bencana': return Colors.brown;
      case 'Infrastruktur': return Colors.blue;
      default: return kPrimaryColor;
    }
  }
}