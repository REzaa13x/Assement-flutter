import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/custom_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'campaign_detail_page.dart'; 
import '../models/donation_campaign.dart'; 
import 'list_campaign_page.dart';
import 'volunteer_campaign_list_page.dart';
import 'profile_page.dart';

// Palet Warna DonGiv
const Color kPrimaryColor = Color(0xFF2972FF);
const Color kBackgroundColor = Color(0xFFF5F7FA); 
const Color kTextPrimary = Color(0xFF1A1A1A);
const Color kTextSecondary = Color(0xFF888888);

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomeContentModern(onGoToDonation: () => _onTabTapped(1)), 
            const ListCampaignPage(), 
            const VolunteerCampaignListPage(), 
            const ProfilePage(), 
    ];

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -5)
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: kPrimaryColor,
          unselectedItemColor: Colors.grey[400],
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          elevation: 0,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Donasi'),
            BottomNavigationBarItem(icon: Icon(Icons.volunteer_activism_rounded), label: 'Relawan'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Akun'),
          ],
        ),
      ),
    );
  }
}

// --- KONTEN HOME ---
class HomeContentModern extends StatefulWidget {
  final VoidCallback onGoToDonation;

  const HomeContentModern({Key? key, required this.onGoToDonation}) : super(key: key);

  @override
  State<HomeContentModern> createState() => _HomeContentModernState();
}

class _HomeContentModernState extends State<HomeContentModern> {
  bool _isLoading = true;
  List<DonationCampaign> _allCampaigns = []; 
  List<DonationCampaign> _displayCampaigns = []; 
  String _selectedCategory = "Semua"; 

  @override
  void initState() {
    super.initState();
    _fetchCampaigns();
  }

  Future<void> _fetchCampaigns() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      final data = [
        DonationCampaign(
          id: 1,
          title: 'Wakaf Air Bersih Desa',
          description: 'Bantu desa kekeringan di pelosok negeri.',
          imageUrl: 'https://images.pexels.com/photos/19123083/pexels-photo-19123083.jpeg',
          targetAmount: 50000000,
          currentAmount: 35000000,
          category: 'Infrastruktur',
        ),
        DonationCampaign(
          id: 2,
          title: 'Beasiswa Anak Yatim',
          description: 'Pendidikan layak untuk anak kurang mampu.',
          imageUrl: 'https://images.pexels.com/photos/1739842/pexels-photo-1739842.jpeg',
          targetAmount: 20000000,
          currentAmount: 8500000,
          category: 'Pendidikan',
        ),
        DonationCampaign(
          id: 3,
          title: 'Operasi Jantung Bayi',
          description: 'Bantuan medis darurat untuk balita.',
          imageUrl: 'https://images.pexels.com/photos/263194/pexels-photo-263194.jpeg',
          targetAmount: 100000000,
          currentAmount: 92000000,
          category: 'Medis',
        ),
      ];

      setState(() {
        _allCampaigns = data;
        _displayCampaigns = data; 
        _isLoading = false;
      });
    }
  }

  // Fungsi Filter Logika (Client Side)
  void _filterCampaigns(String category) {
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
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. HEADER DONGIV 
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Text("Don", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kPrimaryColor)),
                      Text("Giv", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: kTextPrimary)),
                    ],
                  ),
                  // Notifikasi Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.notifications_none_rounded, color: kTextPrimary, size: 24),
                  )
                ],
              ),
            ),
          ),

          // 2. SEARCH BAR & FUNCTIONAL CATEGORIES
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: "Cari program kebaikan...",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                
                // Categories (Horizontal Scroll & Fungsional)
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildCategoryChip(Icons.grid_view_rounded, "Semua"),
                      _buildCategoryChip(Icons.medical_services_outlined, "Medis"),
                      _buildCategoryChip(Icons.school_outlined, "Pendidikan"),
                      _buildCategoryChip(Icons.water_drop_outlined, "Infrastruktur"),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. HERO BANNER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: _buildHeroBanner(),
            ),
          ),

          // 4. SECTION HEADER
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Mendesak & Pilihan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary)),
                  GestureDetector(
                    onTap: widget.onGoToDonation,
                    child: const Text('Lihat Semua', style: TextStyle(fontSize: 14, color: kPrimaryColor, fontWeight: FontWeight.w600))
                  ),
                ],
              ),
            ),
          ),

          // 5. CAMPAIGN LIST (YANG SUDAH DIFILTER)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 295, 
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _displayCampaigns.isEmpty
                      ? _buildEmptyState() // Tampilan jika filter kosong
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _displayCampaigns.length,
                          itemBuilder: (context, index) => _buildModernCampaignCard(_displayCampaigns[index], context),
                        ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // --- WIDGETS PENDUKUNG ---

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text("Belum ada kampanye di kategori ini", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  // Widget Chip yang Bisa Diklik
  Widget _buildCategoryChip(IconData icon, String label) {
    bool isActive = _selectedCategory == label;
    return GestureDetector(
      onTap: () => _filterCampaigns(label), // Panggil fungsi filter saat diklik
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? kPrimaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: Colors.grey[200]!),
          boxShadow: isActive 
            ? [BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
            : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : kTextSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : kTextSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: CachedNetworkImageProvider('https://images.pexels.com/photos/6646917/pexels-photo-6646917.jpeg'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent, 
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: const Text('URGENT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Bantu Korban Gempa\nCianjur Bangkit', 
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, height: 1.2)
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(height: 3, width: 40, color: kPrimaryColor),
                    const SizedBox(width: 8),
                    const Text('Donasi Sekarang', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernCampaignCard(DonationCampaign data, BuildContext context) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/campaign_detail',
            arguments: data,
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                    imageUrl: data.imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(color: Colors.grey[200]),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data.category,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: kPrimaryColor),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: kTextPrimary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.verified_user, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Yayasan DonGiv Peduli', 
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: data.progress,
                      minHeight: 6,
                      backgroundColor: Colors.grey[100],
                      valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Terkumpul', style: TextStyle(fontSize: 10, color: kTextSecondary)),
                          Text(
                            'Rp ${(data.currentAmount/1000000).toStringAsFixed(1)}jt', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kPrimaryColor)
                          ),
                        ],
                      ),
                       Text(
                        '${(data.progress*100).toInt()}%', 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kTextPrimary)
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _VolunteerCampaignListPageContent extends StatelessWidget {
  const _VolunteerCampaignListPageContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final volunteerCampaigns = [
      VolunteerCampaign(
        id: 1,
        title: 'Kampanye Kebersihan Pantai',
        description: 'Bergabunglah dengan kami membersihkan pesisir pantai dan melindungi kehidupan laut',
        imageUrl: 'https://source.unsplash.com/600x400/?beach,cleanup,ocean',
        location: 'Bali, Indonesia',
        startDate: DateTime(2025, 12, 20),
        endDate: DateTime(2025, 12, 22),
        maxVolunteers: 100,
        registeredVolunteers: 65,
        requirements: 'Bersedia bekerja di bawah terik matahari, nyaman dengan aktivitas fisik',
        benefits: 'Makan siang disediakan, sertifikat partisipasi',
      ),
      VolunteerCampaign(
        id: 2,
        title: 'Dukungan Perawatan Lansia',
        description: 'Menghabiskan waktu dengan penduduk lanjut usia dan memberikan teman',
        imageUrl: 'https://source.unsplash.com/600x400/?elderly,care,help',
        location: 'Jakarta, Indonesia',
        startDate: DateTime(2025, 12, 15),
        endDate: DateTime(2025, 12, 30),
        maxVolunteers: 50,
        registeredVolunteers: 32,
        requirements: 'Kemampuan komunikasi yang baik, kesabaran, dan empati',
        benefits: 'Pengalaman dalam pekerjaan sosial, surat referensi',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Peluang Relawan',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: volunteerCampaigns.length,
        itemBuilder: (context, index) {
          final campaign = volunteerCampaigns[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/volunteer_campaign_detail',
                  arguments: campaign,
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 120,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                      child: CachedNetworkImage(
                        imageUrl: campaign.imageUrl,
                        width: 100,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 100,
                          height: double.infinity,
                          color: Colors.grey[300]!,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 100,
                          height: double.infinity,
                          color: Colors.grey[300]!,
                          child: const Icon(
                            Icons.broken_image,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              campaign.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              campaign.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.date_range,
                                  size: 12,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_formatDate(campaign.startDate)} - ${_formatDate(campaign.endDate)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
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
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _ProfilePageContent extends StatelessWidget {
  const _ProfilePageContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF2972FF),
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: 'https://source.unsplash.com/200x200/?avatar,profile',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300]!,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[300]!,
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Budi Santoso',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'budi.santoso@example.com',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Profile options
          _buildProfileOption(
            icon: Icons.person,
            title: 'Edit Profil',
            onTap: () {
              Navigator.pushNamed(context, '/edit_profile');
            },
          ),
          _buildProfileOption(
            icon: Icons.history,
            title: 'Riwayat Donasi',
            onTap: () {
              Navigator.pushNamed(context, '/donation_history');
            },
          ),
          _buildProfileOption(
            icon: Icons.volunteer_activism,
            title: 'Relawan Saya',
            onTap: () {
              // Navigate to volunteering history page
            },
          ),
          _buildProfileOption(
            icon: Icons.monetization_on,
            title: 'Mulai Kampanye',
            onTap: () {
              Navigator.pushNamed(context, '/start_campaign');
            },
          ),

          const SizedBox(height: 24),

          // About section
          _buildProfileOption(
            icon: Icons.info,
            title: 'Tentang Kami',
            onTap: () {
              Navigator.pushNamed(context, '/about_us');
            },
          ),
          _buildProfileOption(
            icon: Icons.help,
            title: 'Cara Kerja',
            onTap: () {
              Navigator.pushNamed(context, '/how_it_works');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF2972FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2972FF),
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}