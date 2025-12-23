import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/donation_campaign.dart';

const Color kPrimaryColor = Color(0xFF2972FF);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF888888);

class ListCampaignPage extends StatefulWidget {
  const ListCampaignPage({Key? key}) : super(key: key);

  @override
  State<ListCampaignPage> createState() => _ListCampaignPageState();
}

class _ListCampaignPageState extends State<ListCampaignPage> {
  bool _isLoading = true;
  
  // Data Master (Semua Data)
  List<DonationCampaign> _allCampaigns = [];
  // Data Tampil (Hasil Filter)
  List<DonationCampaign> _displayCampaigns = [];
  
  String _selectedCategory = "Semua";

  @override
  void initState() {
    super.initState();
    _fetchCampaigns();
  }

  Future<void> _fetchCampaigns() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      // Data Dummy Lengkap
      final data = [
        DonationCampaign(
          id: 1,
          title: 'Wakaf Air Bersih Desa',
          description: 'Bantu desa kekeringan di pelosok.',
          imageUrl: 'https://images.pexels.com/photos/19123083/pexels-photo-19123083.jpeg',
          targetAmount: 50000000,
          currentAmount: 32000000,
          category: 'Infrastruktur',
        ),
        DonationCampaign(
          id: 2,
          title: 'Beasiswa Anak Yatim',
          description: 'Pendidikan untuk masa depan cerah.',
          imageUrl: 'https://images.pexels.com/photos/1739842/pexels-photo-1739842.jpeg',
          targetAmount: 30000000,
          currentAmount: 18000000,
          category: 'Pendidikan',
        ),
        DonationCampaign(
          id: 3,
          title: 'Bantuan Banjir Bandang',
          description: 'Makanan & Obat untuk pengungsi.',
          imageUrl: 'https://images.pexels.com/photos/10926715/pexels-photo-10926715.jpeg',
          targetAmount: 100000000,
          currentAmount: 75000000,
          category: 'Bencana',
        ),
        DonationCampaign(
          id: 4,
          title: 'Bantu Petani Lokal',
          description: 'Modal bibit untuk petani kecil.',
          imageUrl: 'https://images.pexels.com/photos/2132250/pexels-photo-2132250.jpeg',
          targetAmount: 25000000,
          currentAmount: 12000000,
          category: 'Ekonomi',
        ),
        DonationCampaign(
          id: 5,
          title: 'Ambulans Gratis',
          description: 'Layanan kesehatan desa terpencil.',
          imageUrl: 'https://images.pexels.com/photos/6529858/pexels-photo-6529858.jpeg',
          targetAmount: 40000000,
          currentAmount: 27000000,
          category: 'Kesehatan',
        ),
        DonationCampaign(
          id: 6,
          title: 'Listrik Tenaga Surya',
          description: 'Cahaya untuk desa tanpa listrik.',
          imageUrl: 'https://images.pexels.com/photos/9875415/pexels-photo-9875415.jpeg',
          targetAmount: 60000000,
          currentAmount: 15000000,
          category: 'Infrastruktur',
        ),
      ];

      setState(() {
        _allCampaigns = data;
        _displayCampaigns = data; // Awalnya tampilkan semua
        _isLoading = false;
      });
    }
  }

  // LOGIKA FILTER (Berfungsi)
  void _filterData(String category) {
    setState(() {
      _selectedCategory = category;
      if (category == "Semua") {
        _displayCampaigns = _allCampaigns;
      } else {
        _displayCampaigns = _allCampaigns
            .where((item) => item.category.toLowerCase() == category.toLowerCase())
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      // Menggunakan CustomScrollView agar header menyatu dengan scroll (Tidak Cacat)
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. APP BAR MENYATU (SLIVER)
          const SliverAppBar(
            automaticallyImplyLeading: false, // Hapus tombol back
            backgroundColor: Colors.white,
            floating: true, // Header muncul saat scroll up
            pinned: false,
            elevation: 0,
            centerTitle: true,
            title: Text(
              "Program Donasi",
              style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),

          // 2. FILTER CHIPS (Scroll Horizontal)
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
                    _buildFilterChip("Kesehatan"), // Sesuai data dummy
                    _buildFilterChip("Pendidikan"),
                    _buildFilterChip("Bencana"),
                    _buildFilterChip("Infrastruktur"),
                  ],
                ),
              ),
            ),
          ),

          // 3. GRID CONTENT
          _isLoading
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
                          (context, index) => _buildModernGridCard(_displayCampaigns[index]),
                          childCount: _displayCampaigns.length,
                        ),
                      ),
                    ),
          
          // Padding bawah agar tidak kepotong navbar
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_off, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text("Tidak ada program di kategori ini", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
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
          color: isSelected ? kPrimaryColor : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : kTextSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // Helper untuk cek kategori aktif (Case Insensitive sederhana)
  bool _selectedFilterMatches(String label) {
    return _selectedCategory.toLowerCase() == label.toLowerCase();
  }

  Widget _buildModernGridCard(DonationCampaign data) {
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
              '/campaign_detail',
              arguments: data,
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
                      child: CachedNetworkImage(
                        imageUrl: data.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[200]),
                        errorWidget: (context, url, error) => Container(color: Colors.grey[200], child: const Icon(Icons.error)),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data.category,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: kPrimaryColor),
                        ),
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
                        data.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: kTextPrimary, height: 1.2),
                      ),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: data.progress,
                              minHeight: 6,
                              backgroundColor: Colors.grey[100],
                              valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Terkumpul", style: TextStyle(fontSize: 9, color: Colors.grey)),
                                  Text(
                                    "Rp ${(data.currentAmount/1000000).toStringAsFixed(0)}Jt",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: kPrimaryColor),
                                  ),
                                ],
                              ),
                              Text(
                                "${(data.progress * 100).toInt()}%",
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kTextPrimary),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}