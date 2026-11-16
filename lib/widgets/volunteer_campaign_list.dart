import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../models.dart';
import '../repositories/volunteer_repository.dart';

class VolunteerCampaignListWidget extends StatefulWidget {
  const VolunteerCampaignListWidget({Key? key}) : super(key: key);

  @override
  State<VolunteerCampaignListWidget> createState() => _VolunteerCampaignListWidgetState();
}

class _VolunteerCampaignListWidgetState extends State<VolunteerCampaignListWidget> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  List<VolunteerCampaign> _allCampaigns = [];
  List<VolunteerCampaign> _displayCampaigns = [];

  String _selectedCategory = "Semua";
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchVolunteerCampaigns();
  }

  Future<void> _fetchVolunteerCampaigns() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final response = await VolunteerRepository.getVolunteerCampaignsRaw(page: _currentPage);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> data = jsonData['data'];

        final campaigns = data.map((item) {
          // Konversi item ke format yang sesuai dengan VolunteerCampaign.fromJson
          return VolunteerCampaign.fromJson({
            'id': item['id'],
            'title': item['title'] ?? item['judul'] ?? item['name'],
            'description': item['description'] ?? item['deskripsi'],
            'image': item['image'] ?? item['gambar'],
            'location': item['location'] ?? item['lokasi'],
            'start_date': item['start_date'] ?? item['tanggal_mulai'],
            'end_date': item['end_date'] ?? item['tanggal_selesai'],
            'kuota_total': item['kuota_total'] ?? item['kuota'],
            'kuota_terisi': item['kuota_terisi'],
            'requirements': item['requirements'] ?? item['persyaratan'],
            'benefits': item['benefits'] ?? item['manfaat'],
          });
        }).toList();

        setState(() {
          _allCampaigns = campaigns;
          _displayCampaigns = campaigns; // Awalnya tampilkan semua
          _isLoading = false;
          // Tidak bisa mengakses pagination dari raw response tanpa parsing
          _hasMore = false; // Untuk sementara
        });
      } else {
        throw Exception('Failed to load volunteer campaigns: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _refreshVolunteerCampaigns() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final response = await VolunteerRepository.getVolunteerCampaignsRaw(page: 1);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> data = jsonData['data'];

        final campaigns = data.map((item) {
          // Konversi item ke format yang sesuai dengan VolunteerCampaign.fromJson
          return VolunteerCampaign.fromJson({
            'id': item['id'],
            'title': item['title'] ?? item['judul'] ?? item['name'],
            'description': item['description'] ?? item['deskripsi'],
            'image': item['image'] ?? item['gambar'],
            'location': item['location'] ?? item['lokasi'],
            'start_date': item['start_date'] ?? item['tanggal_mulai'],
            'end_date': item['end_date'] ?? item['tanggal_selesai'],
            'kuota_total': item['kuota_total'] ?? item['kuota'],
            'kuota_terisi': item['kuota_terisi'],
            'requirements': item['requirements'] ?? item['persyaratan'],
            'benefits': item['benefits'] ?? item['manfaat'],
          });
        }).toList();

        setState(() {
          _allCampaigns = campaigns;
          _displayCampaigns = campaigns;
          _isLoading = false;
          // Tidak bisa mengakses pagination dari raw response tanpa parsing
          _hasMore = false; // Untuk sementara
          _currentPage = 1;
        });
      } else {
        throw Exception('Failed to load volunteer campaigns: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  // LOGIKA FILTER
  void _filterData(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == "Semua") {
        _displayCampaigns = _allCampaigns;
      } else {
        _displayCampaigns = _allCampaigns
            .where((item) => item.location.toLowerCase().contains(category.toLowerCase()))
            .toList();
      }
    });
  }

  // Helper untuk cek kategori aktif
  bool _selectedFilterMatches(String label) {
    return _selectedCategory.toLowerCase() == label.toLowerCase();
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilterMatches(label);

    return GestureDetector(
      onTap: () => _filterData(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildVolunteerCampaignCard(VolunteerCampaign campaign) {
    final progress = campaign.maxVolunteers > 0 ? (campaign.registeredVolunteers / campaign.maxVolunteers).toDouble() : 0.0;
    
    return Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // GAMBAR
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: campaign.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: campaign.imageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.grey[200]),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.error),
                              ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            ),
                    ),
                  ],
                ),
              ),

              // KONTEN
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        campaign.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87, height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              campaign.location,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.date_range, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatDate(campaign.startDate)} - ${_formatDate(campaign.endDate)}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey[100],
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${campaign.registeredVolunteers}/${campaign.maxVolunteers} Volunteers",
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            "${(progress * 100).round()}%",
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volunteer_activism, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Tidak ada program sukarelawan", style: TextStyle(color: Colors.grey[500])),
        ],
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
              onPressed: _refreshVolunteerCampaigns,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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
    return _hasError
        ? _buildErrorState()
        : RefreshIndicator(
            onRefresh: _refreshVolunteerCampaigns,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // FILTER CHIPS (Scroll Horizontal)
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          _buildFilterChip("Semua"),
                          _buildFilterChip("Jakarta"),
                          _buildFilterChip("Bandung"),
                          _buildFilterChip("Surabaya"),
                          _buildFilterChip("Yogyakarta"),
                        ],
                      ),
                    ),
                  ),
                ),

                // GRID CONTENT
                _isLoading && _allCampaigns.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _displayCampaigns.isEmpty
                        ? SliverFillRemaining(child: _buildEmptyState())
                        : SliverPadding(
                            padding: const EdgeInsets.all(16),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.70,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => _buildVolunteerCampaignCard(_displayCampaigns[index]),
                                childCount: _displayCampaigns.length,
                              ),
                            ),
                          ),

                // Load more indicator jika masih ada data
                if (_isLoading && !_allCampaigns.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),

                // Padding bawah
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
  }
}