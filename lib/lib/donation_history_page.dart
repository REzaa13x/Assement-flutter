import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/donation_transaction.dart';
import '../repositories/donation_repository.dart';
import '../services/local_donation_service.dart'; // Import local donation service

class DonationHistoryPage extends StatefulWidget {
  const DonationHistoryPage({Key? key}) : super(key: key);

  @override
  State<DonationHistoryPage> createState() => _DonationHistoryPageState();
}

class _DonationHistoryPageState extends State<DonationHistoryPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<DonationTransaction> _donationHistory = [];
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchDonationHistory();
  }

  Future<void> _fetchDonationHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Ambil token dari storage
      String? token = await _getToken();

      if (token == null || token.isEmpty) {
        // Jika token tidak ditemukan, tampilkan data lokal
        print('No token found, loading local donation history...');
        final localDonations = await LocalDonationService.getLocalDonations();
        setState(() {
          _donationHistory = localDonations;
          _isLoading = false;
          _hasMore = false;
        });
        return;
      }

      // Ambil data dari server
      try {
        print('Fetching donation history from server with token: ${token.substring(0, token.length < 10 ? token.length : 10)}...');
        final response = await DonationRepository.getDonationHistory(token: token, page: _currentPage);
        print('Server response received. Total items: ${response.data.length}');

        // Ambil data lokal
        final localDonations = await LocalDonationService.getLocalDonations();
        print('Local donations count: ${localDonations.length}');

        // Gabungkan data dari server dan lokal
        // Tambahkan data lokal ke daftar jika belum ada di server
        List<DonationTransaction> combinedDonations = List.from(response.data);

        for (var localDonation in localDonations) {
          // Cek apakah donation lokal sudah ada di data server
          bool existsInServer = combinedDonations.any((serverDonation) =>
              serverDonation.orderId == localDonation.orderId);

          // Jika belum ada di server, tambahkan ke daftar
          if (!existsInServer) {
            combinedDonations.insert(0, localDonation); // Tambahkan di awal agar terbaru muncul duluan
            print('Added local donation to combined list: ${localDonation.orderId}');
          }
        }

        print('Final combined donations count: ${combinedDonations.length}');
        setState(() {
          _donationHistory = combinedDonations;
          _isLoading = false;
          _hasMore = response.currentPage < response.lastPage;
        });
      } catch (serverError) {
        print('Server donation history failed: $serverError');
        print('Loading local donation history instead...');

        // Jika server gagal, tampilkan data lokal
        final localDonations = await LocalDonationService.getLocalDonations();
        setState(() {
          _donationHistory = localDonations;
          _isLoading = false;
          _hasMore = false;
        });
      }
    } catch (e) {
      print('Error in _fetchDonationHistory: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _refreshDonationHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      // Ambil token dari storage
      String? token = await _getToken();

      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      print('Refreshing donation history from server with token: ${token.substring(0, token.length < 10 ? token.length : 10)}...');
      final response = await DonationRepository.getDonationHistory(token: token, page: 1);
      print('Refresh server response received. Total items: ${response.data.length}');

      // Ambil data lokal
      final localDonations = await LocalDonationService.getLocalDonations();
      print('Local donations count for refresh: ${localDonations.length}');

      // Gabungkan data dari server dan lokal
      List<DonationTransaction> combinedDonations = List.from(response.data);

      for (var localDonation in localDonations) {
        // Cek apakah donation lokal sudah ada di data server
        bool existsInServer = combinedDonations.any((serverDonation) =>
            serverDonation.orderId == localDonation.orderId);

        // Jika belum ada di server, tambahkan ke daftar
        if (!existsInServer) {
          combinedDonations.insert(0, localDonation); // Tambahkan di awal agar terbaru muncul duluan
          print('Added local donation to combined list during refresh: ${localDonation.orderId}');
        }
      }

      print('Final combined donations count after refresh: ${combinedDonations.length}');
      setState(() {
        _donationHistory = combinedDonations;
        _isLoading = false;
        _hasMore = response.currentPage < response.lastPage;
        _currentPage = 1;
      });
    } catch (e) {
      print('Error in _refreshDonationHistory: $e');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  // Fungsi untuk mendapatkan token - implementasikan sesuai dengan state management Anda
  Future<String?> _getToken() async {
    // Dalam implementasi sebenarnya, ambil token dari storage
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Widget _buildDonationItem(DonationTransaction transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campaign Info
            if (transaction.campaign != null) ...[
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: transaction.campaign!.image != null
                        ? CachedNetworkImage(
                            imageUrl: transaction.campaign!.image!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.campaign),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.campaign?.title ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          transaction.campaign?.kategori ?? transaction.campaign?.category ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Donation Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Jumlah Donasi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Rp ${transaction.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Status Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(transaction.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    transaction.statusLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Order ID
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order ID',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  transaction.orderId,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tanggal',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  _formatDate(transaction.verifiedAt ?? DateTime.now()),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'VERIFIED':
        return Colors.green;
      case 'PENDING_VERIFICATION':
        return Colors.orange;
      case 'AWAITING_TRANSFER':
        return Colors.blue;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Donasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kamu belum pernah melakukan donasi.\nAyo berdonasi untuk membantu sesama!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                // textAlign: TextAlign.center, // Dihapus karena tidak digunakan di Text widget ini
              ),
            ),
          ],
        ),
      ),
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
              'Gagal memuat data',
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
              onPressed: _refreshDonationHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2972FF),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Donasi',
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
          : _donationHistory.isEmpty && !_isLoading
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _refreshDonationHistory,
                  child: _isLoading && _donationHistory.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          padding: const EdgeInsets.only(top: 16),
                          itemCount: _donationHistory.length + (_isLoading && _hasMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < _donationHistory.length) {
                              return _buildDonationItem(_donationHistory[index]);
                            } else {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                          },
                        ),
                ),
    );
  }
}