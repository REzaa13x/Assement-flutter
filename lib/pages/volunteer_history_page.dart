import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/volunteer.dart';
import '../repositories/volunteer_repository.dart';

class VolunteerHistoryPage extends StatefulWidget {
  const VolunteerHistoryPage({Key? key}) : super(key: key);

  @override
  State<VolunteerHistoryPage> createState() => _VolunteerHistoryPageState();
}

class _VolunteerHistoryPageState extends State<VolunteerHistoryPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<VolunteerApplication> _volunteerHistory = [];
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchVolunteerHistory();
  }

  String _getFriendlyErrorMessage(dynamic error) {
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('token') || errStr.contains('unauthorized') || errStr.contains('401')) {
      return 'Sesi login telah berakhir. Silakan login kembali.';
    } else if (errStr.contains('404')) {
      return 'Riwayat relawan belum tersedia.';
    } else if (errStr.contains('socket') || errStr.contains('koneksi') || errStr.contains('network')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    return 'Terjadi kendala saat memuat riwayat relawan. Silakan coba sesaat lagi.';
  }

  Future<void> _fetchVolunteerHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      // Ambil token dari storage
      String? token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      // Coba ambil dari server
      final response = await VolunteerRepository.getVolunteerApplicationsRaw(token: token);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final dynamic rawData = jsonData['data'];
        final List<dynamic> data = rawData is List
            ? rawData
            : (rawData is Map && rawData['data'] is List ? rawData['data'] : []);

        final applications = data.map((item) {
          if (item is Map<String, dynamic>) {
            return VolunteerApplication.fromJson(item);
          } else if (item is Map) {
            return VolunteerApplication.fromJson(Map<String, dynamic>.from(item));
          }
          return VolunteerApplication.fromJson({});
        }).toList();

        setState(() {
          _volunteerHistory = applications;
          _isLoading = false;
          _hasError = false;
        });
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Silakan login kembali');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = _getFriendlyErrorMessage(e);
        });
      }
    }
  }

  Future<void> _refreshVolunteerHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      // Ambil token dari storage
      String? token = await _getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await VolunteerRepository.getVolunteerApplicationsRaw(token: token);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final dynamic rawData = jsonData['data'];
        final List<dynamic> data = rawData is List
            ? rawData
            : (rawData is Map && rawData['data'] is List ? rawData['data'] : []);

        final applications = data.map((item) {
          if (item is Map<String, dynamic>) {
            return VolunteerApplication.fromJson(item);
          } else if (item is Map) {
            return VolunteerApplication.fromJson(Map<String, dynamic>.from(item));
          }
          return VolunteerApplication.fromJson({});
        }).toList();

        setState(() {
          _volunteerHistory = applications;
          _isLoading = false;
          _hasError = false;
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = _getFriendlyErrorMessage(e);
        });
      }
    }
  }

  Future<String?> _getToken() async {
    // Dalam implementasi sebenarnya, ambil token dari storage
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Widget _buildVolunteerItem(VolunteerApplication application) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul kampanye
            Row(
              children: [
                Icon(Icons.volunteer_activism, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    application.campaign?.title ?? 'Kampanye Relawan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Gambar kampanye jika tersedia
            if (application.campaign?.imageUrl != null && application.campaign!.imageUrl!.isNotEmpty) ...[
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(
                      application.campaign!.imageUrl!,
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                child: null, // Placeholder jika diperlukan
              ),
              const SizedBox(height: 8),
            ],
            // Lokasi jika tersedia
            if (application.campaign?.location != null && application.campaign!.location.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      application.campaign!.location,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            // Status
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Status: ${application.status ?? "Tertunda"}',
                  style: TextStyle(
                    fontSize: 14,
                    color: _getStatusColor(application.status ?? "Tertunda"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Tanggal pendaftaran
            Text(
              'Mendaftar pada: ${_formatDate(application.createdAt ?? DateTime.now())}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            if (application.status?.toLowerCase() == 'approved' ||
                application.status?.toLowerCase() == 'diterima') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/my_certificates');
                  },
                  icon: const Icon(Icons.card_membership_rounded, size: 16),
                  label: const Text(
                    'Lihat Sertifikat Relawan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2972FF),
                    side: const BorderSide(color: Color(0xFF2972FF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'diterima':
      case 'active':
        return Colors.green;
      case 'rejected':
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Relawan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.card_membership_rounded, color: Color(0xFF2972FF)),
            tooltip: 'Sertifikat Saya',
            onPressed: () {
              Navigator.pushNamed(context, '/my_certificates');
            },
          ),
        ],
      ),
      body: _hasError
          ? Center(
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
                      onPressed: _refreshVolunteerHistory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2972FF),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshVolunteerHistory,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _volunteerHistory.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.volunteer_activism,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Belum ada riwayat relawan',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Anda belum pernah mendaftar sebagai relawan',
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _volunteerHistory.length,
                          itemBuilder: (context, index) {
                            return _buildVolunteerItem(_volunteerHistory[index]);
                          },
                        ),
            ),
    );
  }
}