import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/campaign.dart';
import '../models/donation_campaign.dart';
import '../repositories/campaign_repository.dart';
import '../config/app_config.dart';

const Color kPrimaryColor = Color(0xFF2972FF);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF888888);

class CampaignHistoryPage extends StatefulWidget {
  const CampaignHistoryPage({Key? key}) : super(key: key);

  @override
  State<CampaignHistoryPage> createState() => _CampaignHistoryPageState();
}

class _CampaignHistoryPageState extends State<CampaignHistoryPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  List<Campaign> _allCampaigns = [];
  List<Campaign> _displayCampaigns = [];

  String _selectedStatusFilter = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _statusFilters = [
    'Semua',
    'Menunggu',
    'Terverifikasi',
    'Ditolak',
  ];

  @override
  void initState() {
    super.initState();
    _fetchMyCampaigns();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  String _normalizeImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (AppConfig.apiUrl.contains('10.0.2.2') && rawUrl.contains('127.0.0.1')) {
      return rawUrl.replaceAll('127.0.0.1', '10.0.2.2');
    }
    if (AppConfig.apiUrl.contains('10.0.2.2') && rawUrl.contains('localhost')) {
      return rawUrl.replaceAll('localhost', '10.0.2.2');
    }
    return rawUrl;
  }

  String _formatCurrency(double amount) {
    final str = amount.toInt().toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final month = date.month >= 1 && date.month <= 12 ? months[date.month - 1] : '${date.month}';
      return '${date.day} $month ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _fetchMyCampaigns() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Sesi login telah berakhir. Silakan login kembali.');
      }

      final response = await CampaignRepository.getMyCampaigns(token: token);

      if (mounted) {
        setState(() {
          _allCampaigns = response.data;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  void _applyFilters() {
    List<Campaign> filtered = _allCampaigns;

    // Filter berdasarkan status
    if (_selectedStatusFilter != 'Semua') {
      filtered = filtered.where((c) {
        final st = (c.status ?? '').toLowerCase();
        if (_selectedStatusFilter == 'Menunggu') {
          return st == 'pending';
        } else if (_selectedStatusFilter == 'Terverifikasi') {
          return st == 'verified' || st == 'active';
        } else if (_selectedStatusFilter == 'Ditolak') {
          return st == 'rejected';
        }
        return true;
      }).toList();
    }

    // Filter pencarian
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        final title = (c.title ?? '').toLowerCase();
        final desc = (c.description ?? '').toLowerCase();
        final cat = (c.category ?? c.kategori ?? '').toLowerCase();
        return title.contains(query) || desc.contains(query) || cat.contains(query);
      }).toList();
    }

    setState(() {
      _displayCampaigns = filtered;
    });
  }

  void _onStatusFilterSelected(String filter) {
    setState(() {
      _selectedStatusFilter = filter;
    });
    _applyFilters();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _openCampaignDetail(Campaign campaign) {
    final status = (campaign.status ?? '').toLowerCase();

    // Jika kampanye sudah terverifikasi atau aktif, bisa dibuka detailnya
    if (status == 'verified' || status == 'active') {
      final donationCampaign = DonationCampaign(
        id: campaign.id ?? 0,
        title: campaign.title ?? 'Tanpa Judul',
        description: campaign.description ?? '',
        imageUrl: _normalizeImageUrl(campaign.image),
        targetAmount: campaign.targetAmount ?? 0.0,
        currentAmount: campaign.currentAmount ?? 0.0,
        category: campaign.category ?? campaign.kategori ?? 'Umum',
      );

      Navigator.pushNamed(
        context,
        '/campaign_detail',
        arguments: donationCampaign,
      );
    } else {
      // Tampilkan bottom sheet status verifikasi jika masih pending atau rejected
      _showStatusDetailBottomSheet(campaign);
    }
  }

  void _showStatusDetailBottomSheet(Campaign campaign) {
    final status = (campaign.status ?? '').toLowerCase();
    final isPending = status == 'pending';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPending ? Colors.amber[50] : Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPending ? Icons.schedule_rounded : Icons.cancel_outlined,
                      color: isPending ? Colors.amber[800] : Colors.red[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPending ? 'Menunggu Verifikasi Admin' : 'Kampanye Ditolak',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isPending ? Colors.amber[900] : Colors.red[900],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPending
                              ? 'Kampanye sedang ditinjau oleh tim DonGiv.'
                              : 'Kampanye belum memenuhi kriteria verifikasi.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                campaign.title ?? 'Tanpa Judul',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                campaign.description ?? '-',
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kBackgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Target Donasi',
                          style: TextStyle(fontSize: 11, color: kTextSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCurrency(campaign.targetAmount ?? 0),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Kategori',
                          style: TextStyle(fontSize: 11, color: kTextSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          campaign.category ?? campaign.kategori ?? 'Umum',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Mengerti'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Riwayat Kampanye',
          style: TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchMyCampaigns,
        color: kPrimaryColor,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _allCampaigns.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    // Hitung ringkasan status
    final totalCount = _allCampaigns.length;
    final verifiedCount = _allCampaigns.where((c) {
      final st = (c.status ?? '').toLowerCase();
      return st == 'verified' || st == 'active';
    }).length;
    final pendingCount = _allCampaigns.where((c) {
      return (c.status ?? '').toLowerCase() == 'pending';
    }).length;

    return Column(
      children: [
        // Ringkasan & Filter Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              // Kartu Ringkasan
              Row(
                children: [
                  _buildStatMiniCard('Total Dibuat', '$totalCount', Icons.folder_open_rounded, Colors.blue),
                  const SizedBox(width: 10),
                  _buildStatMiniCard('Terverifikasi', '$verifiedCount', Icons.check_circle_outline_rounded, Colors.green),
                  const SizedBox(width: 10),
                  _buildStatMiniCard('Menunggu', '$pendingCount', Icons.schedule_rounded, Colors.amber),
                ],
              ),

              const SizedBox(height: 12),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari judul kampanye yang Anda buat...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Filter Status Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _statusFilters.map((st) => _buildFilterChip(st)).toList(),
                ),
              ),
            ],
          ),
        ),

        // List Kampanye
        Expanded(
          child: _displayCampaigns.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  itemCount: _displayCampaigns.length,
                  itemBuilder: (context, index) {
                    return _buildCampaignCard(_displayCampaigns[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatMiniCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedStatusFilter == label;

    return GestureDetector(
      onTap: () => _onStatusFilterSelected(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCampaignCard(Campaign campaign) {
    final status = (campaign.status ?? '').toLowerCase();
    final target = campaign.targetAmount ?? 0.0;
    final current = campaign.currentAmount ?? 0.0;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final percent = (progress * 100).round();
    final imageUrl = _normalizeImageUrl(campaign.image);

    // Konfigurasi status
    Color statusBg;
    Color statusText;
    IconData statusIcon;
    String statusLabel;

    if (status == 'verified' || status == 'active') {
      statusBg = Colors.green[50]!;
      statusText = Colors.green[800]!;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'Terverifikasi';
    } else if (status == 'rejected') {
      statusBg = Colors.red[50]!;
      statusText = Colors.red[800]!;
      statusIcon = Icons.cancel_rounded;
      statusLabel = 'Ditolak';
    } else {
      statusBg = Colors.amber[50]!;
      statusText = Colors.amber[900]!;
      statusIcon = Icons.schedule_rounded;
      statusLabel = 'Menunggu';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openCampaignDetail(campaign),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail Gambar
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 100,
                    height: 110,
                    child: imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.campaign_outlined, color: Colors.grey, size: 36),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.campaign_outlined, color: Colors.grey, size: 36),
                          ),
                  ),
                ),

                const SizedBox(width: 12),

                // Informasi Kampanye
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge & Kategori
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              campaign.category ?? campaign.kategori ?? 'Umum',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 10, color: statusText),
                                const SizedBox(width: 3),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: statusText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Judul
                      Text(
                        campaign.title ?? 'Tanpa Judul',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                          height: 1.25,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Tanggal Berakhir
                      Row(
                        children: [
                          const Icon(Icons.date_range_outlined, size: 12, color: kTextSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Batas: ${_formatDate(campaign.endDate)}',
                            style: const TextStyle(fontSize: 11, color: kTextSecondary),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 5,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Terkumpul & Persentase
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _formatCurrency(current),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: kTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: kPrimaryColor,
                            ),
                          ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 56,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Kampanye',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedStatusFilter != 'Semua'
                  ? 'Tidak ada kampanye yang cocok dengan filter atau pencarian Anda.'
                  : 'Anda belum pernah membuat kampanye donasi. Mulai langkah kebaikan Anda sekarang!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: kTextSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/start_campaign').then((_) {
                  _fetchMyCampaigns();
                });
              },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Buat Kampanye Baru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
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
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 56,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gagal Memuat Riwayat Kampanye',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'Terjadi kendala koneksi ke server.',
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchMyCampaigns,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
