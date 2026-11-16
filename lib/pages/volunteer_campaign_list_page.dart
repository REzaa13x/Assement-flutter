import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/volunteer_campaign.dart';
import '../repositories/volunteer_repository.dart';
import '../config/app_config.dart';

const Color kPrimaryColor = Color(0xFF2972FF);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF888888);

class VolunteerCampaignListPage extends StatefulWidget {
  const VolunteerCampaignListPage({Key? key}) : super(key: key);

  @override
  State<VolunteerCampaignListPage> createState() => _VolunteerCampaignListPageState();
}

class _VolunteerCampaignListPageState extends State<VolunteerCampaignListPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  List<VolunteerCampaign> _allCampaigns = [];
  List<VolunteerCampaign> _displayCampaigns = [];

  String _selectedCategory = "Semua";
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    "Semua",
    "Lingkungan",
    "Pendidikan",
    "Sosial",
    "Kesehatan",
    "Bencana",
  ];

  @override
  void initState() {
    super.initState();
    _fetchVolunteerCampaigns();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getFriendlyErrorMessage(dynamic error) {
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('404') || errStr.contains('tidak ditemukan')) {
      return 'Peluang relawan belum tersedia saat ini.';
    } else if (errStr.contains('401') || errStr.contains('403') || errStr.contains('izin')) {
      return 'Akses ditolak atau sesi telah berakhir.';
    } else if (errStr.contains('500') || errStr.contains('gangguan') || errStr.contains('server')) {
      return 'Layanan relawan sedang mengalami kendala teknis. Silakan coba sesaat lagi.';
    } else if (errStr.contains('socket') ||
        errStr.contains('failed host lookup') ||
        errStr.contains('connection refused') ||
        errStr.contains('network') ||
        errStr.contains('koneksi')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    return 'Terjadi kendala saat memuat peluang relawan. Silakan coba lagi.';
  }

  String _normalizeImageUrl(String rawUrl) {
    if (rawUrl.isEmpty) return '';
    if (AppConfig.apiUrl.contains('10.0.2.2') && rawUrl.contains('127.0.0.1')) {
      return rawUrl.replaceAll('127.0.0.1', '10.0.2.2');
    }
    if (AppConfig.apiUrl.contains('10.0.2.2') && rawUrl.contains('localhost')) {
      return rawUrl.replaceAll('localhost', '10.0.2.2');
    }
    return rawUrl;
  }

  Future<void> _fetchVolunteerCampaigns() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      final response = await VolunteerRepository.getVolunteerCampaignsRaw();

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final dynamic rawData = jsonData['data'];
        final List<dynamic> dataList = rawData is List
            ? rawData
            : (rawData is Map && rawData['data'] is List ? rawData['data'] : []);

        final campaigns = dataList.map((item) {
          if (item is Map<String, dynamic>) {
            return VolunteerCampaign.fromJson(item);
          } else if (item is Map) {
            return VolunteerCampaign.fromJson(Map<String, dynamic>.from(item));
          }
          return VolunteerCampaign.fromJson({});
        }).toList();

        setState(() {
          _allCampaigns = campaigns;
          _applyFilters();
          _isLoading = false;
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

  void _applyFilters() {
    List<VolunteerCampaign> filtered = _allCampaigns;

    // Filter Kategori
    if (_selectedCategory != "Semua") {
      filtered = filtered.where((c) {
        final cat = c.category.toLowerCase();
        final sel = _selectedCategory.toLowerCase();
        return cat.contains(sel) || sel.contains(cat);
      }).toList();
    }

    // Filter Search
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return c.title.toLowerCase().contains(query) ||
            c.location.toLowerCase().contains(query) ||
            c.description.toLowerCase().contains(query);
      }).toList();
    }

    setState(() {
      _displayCampaigns = filtered;
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _applyFilters();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final monthName = date.month >= 1 && date.month <= 12 ? months[date.month - 1] : '${date.month}';
    return '${date.day} $monthName ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Peluang Relawan',
          style: TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: kTextPrimary),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchVolunteerCampaigns,
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

    return Column(
      children: [
        // Search & Category Filters Header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              // Search Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Cari peluang atau lokasi relawan...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Horizontal Category Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _categories.map((cat) => _buildFilterChip(cat)).toList(),
                ),
              ),
            ],
          ),
        ),

        // List Content
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
                    return _buildVolunteerCard(_displayCampaigns[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedCategory.toLowerCase() == label.toLowerCase();

    return GestureDetector(
      onTap: () => _onCategorySelected(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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

  Widget _buildVolunteerCard(VolunteerCampaign campaign) {
    final progress = campaign.progress;
    final normalizedUrl = _normalizeImageUrl(campaign.imageUrl);

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
          onTap: () {
            Navigator.pushNamed(
              context,
              '/volunteer_campaign_detail',
              arguments: campaign,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar Relawan
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 105,
                    height: 110,
                    child: normalizedUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: normalizedUrl,
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
                              child: const Icon(Icons.volunteer_activism_rounded, color: Colors.grey, size: 36),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.volunteer_activism_rounded, color: Colors.grey, size: 36),
                          ),
                  ),
                ),

                const SizedBox(width: 12),

                // Detail Relawan
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kategori & Status Badge
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              campaign.category,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: campaign.isFull ? Colors.orange.withOpacity(0.15) : Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              campaign.isFull ? 'Kuota Penuh' : campaign.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: campaign.isFull ? Colors.orange[800] : Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Judul
                      Text(
                        campaign.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kTextPrimary,
                          height: 1.25,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Lokasi
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: kTextSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              campaign.location,
                              style: const TextStyle(
                                fontSize: 11,
                                color: kTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 3),

                      // Tanggal Kegiatan
                      Row(
                        children: [
                          const Icon(Icons.date_range_outlined, size: 13, color: kTextSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${_formatDate(campaign.startDate)} - ${_formatDate(campaign.endDate)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: kTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Progress Kuota Relawan
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

                      // Keterangan Kuota
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${campaign.registeredVolunteers} dari ${campaign.maxVolunteers} relawan',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
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
                Icons.volunteer_activism_outlined,
                size: 56,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Peluang Relawan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != "Semua"
                  ? 'Tidak ada kegiatan relawan yang cocok dengan filter atau pencarian Anda.'
                  : 'Peluang kegiatan sukarelawan akan segera hadir di DonGiv.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: kTextSecondary,
                height: 1.4,
              ),
            ),
            if (_selectedCategory != "Semua" || _searchQuery.isNotEmpty) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = "";
                    _selectedCategory = "Semua";
                  });
                  _applyFilters();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryColor,
                  side: const BorderSide(color: kPrimaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text("Tampilkan Semua"),
              ),
            ],
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
              'Gagal Memuat Relawan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(
                color: kTextSecondary,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchVolunteerCampaigns,
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