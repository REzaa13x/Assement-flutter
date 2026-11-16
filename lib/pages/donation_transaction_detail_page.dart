import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/donation_transaction.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

const Color _kPrimaryColor = Color(0xFF2972FF);
const Color _kBackgroundColor = Color(0xFFF5F7FA);

/// Halaman detail satu transaksi donasi.
///
/// Dibuka ketika notifikasi perubahan status donasi ditekan, sehingga
/// pengguna langsung melihat transaksi yang dimaksud.
class DonationTransactionDetailPage extends StatefulWidget {
  final String orderId;

  const DonationTransactionDetailPage({Key? key, required this.orderId})
      : super(key: key);

  @override
  State<DonationTransactionDetailPage> createState() =>
      _DonationTransactionDetailPageState();
}

class _DonationTransactionDetailPageState
    extends State<DonationTransactionDetailPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  DonationTransaction? _transaction;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Sesi kamu sudah berakhir. Silakan login kembali.');
      }

      final response = await ApiService.get(
        'v1/donations/${widget.orderId}',
        token: token,
      );

      if (response.statusCode == 200) {
        final decoded = _decode(response.body);
        final data = decoded['data'];

        if (data is Map<String, dynamic>) {
          setState(() {
            _transaction = DonationTransaction.fromJson(data);
            _isLoading = false;
          });
          return;
        }

        throw Exception('Data donasi tidak ditemukan');
      }

      if (response.statusCode == 404) {
        throw Exception('Donasi tidak ditemukan atau bukan milikmu');
      }

      throw Exception('Gagal memuat detail donasi (${response.statusCode})');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Map<String, dynamic> _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return <String, dynamic>{};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Detail Donasi',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              const Text(
                'Gagal memuat detail donasi',
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
                onPressed: _fetch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final transaction = _transaction;
    if (transaction == null) {
      return const Center(child: Text('Data donasi tidak tersedia'));
    }

    return RefreshIndicator(
      color: _kPrimaryColor,
      onRefresh: _fetch,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Kartu utama: status + jumlah + kampanye
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(transaction.status)
                            .withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel(transaction.status),
                        style: TextStyle(
                          color: _statusColor(transaction.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.volunteer_activism_rounded,
                      color: _statusColor(transaction.status),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _formatRupiah(transaction.amount),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  transaction.campaign?.title ?? 'Donasi Umum',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                _infoRow('Kode Transaksi', transaction.orderId),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Kartu rincian
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rincian',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 12),
                _infoRow('Nama Donatur', transaction.donorName),
                _infoRow('Email', transaction.donorEmail),
                if (transaction.donorPhone != null &&
                    transaction.donorPhone!.isNotEmpty)
                  _infoRow('Telepon', transaction.donorPhone!),
                _infoRow(
                  'Metode Pembayaran',
                  _paymentMethodLabel(transaction.paymentMethod),
                ),
                if (transaction.bankName != null &&
                    transaction.bankName!.isNotEmpty)
                  _infoRow('Bank', transaction.bankName!),
                if (transaction.bankAccountNumber != null &&
                    transaction.bankAccountNumber!.isNotEmpty)
                  _infoRow('No. Rekening', transaction.bankAccountNumber!),
                if (transaction.transferDeadline != null)
                  _infoRow(
                    'Batas Transfer',
                    _formatDateTime(transaction.transferDeadline!),
                  ),
                if (transaction.verifiedAt != null)
                  _infoRow(
                    'Diverifikasi',
                    _formatDateTime(transaction.verifiedAt!),
                  ),
                _infoRow('Status', _statusLabel(transaction.status)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, '/donation_history'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Lihat Semua Riwayat Donasi',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'AWAITING_TRANSFER':
        return 'Menunggu Transfer';
      case 'PENDING_VERIFICATION':
        return 'Menunggu Verifikasi';
      case 'VERIFIED':
        return 'Terverifikasi';
      case 'CANCELLED':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'AWAITING_TRANSFER':
        return const Color(0xFFF59E0B);
      case 'PENDING_VERIFICATION':
        return const Color(0xFF2972FF);
      case 'VERIFIED':
        return const Color(0xFF16A34A);
      case 'CANCELLED':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'bank_transfer':
        return 'Transfer Bank';
      case 'e_wallet':
        return 'E-Wallet';
      case 'qris':
        return 'QRIS';
      default:
        return method;
    }
  }

  String _formatRupiah(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        );
    return 'Rp $formatted';
  }

  String _formatDateTime(DateTime time) {
    final local = time.isUtc ? time.toLocal() : time;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day ${months[local.month - 1]} ${local.year}, $hour:$minute';
  }
}
