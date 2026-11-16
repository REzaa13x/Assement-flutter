import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/donation_campaign.dart';
import '../models/volunteer_campaign.dart';
import '../repositories/campaign_repository.dart';
import '../repositories/volunteer_repository.dart';
import '../repositories/notification_repository.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';
import 'list_campaign_page.dart';
import 'volunteer_campaign_list_page.dart';
import 'profile_page.dart';
import '../models/testimonial_review.dart';
import '../repositories/review_repository.dart';

// Brand colors
const Color kPrimaryColor = Color(0xFF2972FF);
const Color kBackgroundColor = Color(0xFFF8FAFC);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF64748B);
const Color kSurfaceColor = Colors.white;

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
    final List<Widget> pages = [
      HomeContentModern(
        onGoToDonationTab: () => _onTabTapped(1),
        onGoToVolunteerTab: () => _onTabTapped(2),
      ),
      const ListCampaignPage(),
      const VolunteerCampaignListPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      floatingActionButton: _buildChatbotFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: kSurfaceColor,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: kPrimaryColor,
              unselectedItemColor: const Color(0xFF94A3B8),
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              elevation: 0,
              showSelectedLabels: true,
              showUnselectedLabels: true,
              selectedFontSize: 12,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              items: const [
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Icon(Icons.home_rounded, size: 24),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Icon(Icons.home_rounded, size: 25),
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Icon(Icons.favorite_outline_rounded, size: 24),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Icon(Icons.favorite_rounded, size: 25),
                  ),
                  label: 'Donasi',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Icon(Icons.volunteer_activism_outlined, size: 24),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Icon(Icons.volunteer_activism_rounded, size: 25),
                  ),
                  label: 'Relawan',
                ),
                BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Icon(Icons.person_outline_rounded, size: 24),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 3),
                    child: Icon(Icons.person_rounded, size: 25),
                  ),
                  label: 'Akun',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Floating Action Button DonGiv Assistant (Customer Service / Support)
  Widget _buildChatbotFloatingButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, right: 4),
      child: Hero(
        tag: 'dongiv_assistant_fab',
        child: Tooltip(
          message: 'Tanya DonGiv Assistant',
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(8),
          ),
          verticalOffset: 36,
          preferBelow: false,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, '/assistant_chat');
              },
              borderRadius: BorderRadius.circular(28),
              splashColor: Colors.white.withValues(alpha: 0.3),
              highlightColor: Colors.white.withValues(alpha: 0.15),
              child: Ink(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2972FF), Color(0xFF1E5AD6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kPrimaryColor.withValues(alpha: 0.38),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Customer support headset icon
                    const Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    // Green online indicator badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// HOME CONTENT MODERN
// ==========================================
class HomeContentModern extends StatefulWidget {
  final VoidCallback onGoToDonationTab;
  final VoidCallback onGoToVolunteerTab;

  const HomeContentModern({
    Key? key,
    required this.onGoToDonationTab,
    required this.onGoToVolunteerTab,
  }) : super(key: key);

  @override
  State<HomeContentModern> createState() => _HomeContentModernState();
}

class _HomeContentModernState extends State<HomeContentModern> {
  // Activity switcher: 0 for Donasi, 1 for Relawan
  int _selectedActivityType = 0;

  // Data state
  bool _isLoading = true;
  String? _errorMessage;
  String _userName = '';
  int _unreadNotifications = 0;

  // Donation campaigns
  List<DonationCampaign> _allCampaigns = [];
  List<DonationCampaign> _featuredCampaigns = [];
  List<DonationCampaign> _displayCampaigns = [];

  // Volunteer campaigns
  List<VolunteerCampaign> _allVolunteerCampaigns = [];
  List<VolunteerCampaign> _displayVolunteerCampaigns = [];

  // Reviews & Testimonials
  List<TestimonialReview> _reviews = [];
  bool _isLoadingReviews = false;
  final PageController _reviewPageController = PageController(viewportFraction: 0.88);
  int _currentReviewIndex = 0;

  // Filters & Search
  String _selectedCategory = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  final PageController _featuredPageController = PageController(viewportFraction: 0.92);
  int _currentFeaturedIndex = 0;

  final List<String> _donationCategories = [
    'Semua',
    'Bencana Alam',
    'Sosial Kemanusiaan',
    'Kesehatan',
    'Pendidikan',
    'Lingkungan',
    'Infrastruktur',
  ];

  final List<String> _volunteerCategories = [
    'Semua',
    'Lingkungan',
    'Sosial',
    'Pendidikan',
    'Kesehatan',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _featuredPageController.dispose();
    _reviewPageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadUserProfile(),
      _loadUnreadNotifications(),
      _fetchAllData(),
      _fetchReviews(),
    ]);
  }

  Future<void> _loadUserProfile() async {
    try {
      final userData = await AuthService.getUserData();
      if (mounted && userData != null) {
        setState(() {
          _userName = userData['name']?.toString() ?? '';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) return;
      final count = await NotificationRepository.getUnreadCount(authToken: token);
      if (mounted) {
        setState(() => _unreadNotifications = count);
      }
    } catch (_) {}
  }

  Future<void> _fetchReviews() async {
    try {
      if (mounted) setState(() => _isLoadingReviews = true);
      final reviewList = await ReviewRepository.getReviews();
      if (mounted) {
        setState(() {
          _reviews = reviewList;
          _isLoadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _reviews = TestimonialReview.sampleReviews;
          _isLoadingReviews = false;
        });
      }
    }
  }

  Future<void> _fetchAllData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch donation campaigns
      final campaignResponse = await CampaignRepository.getCampaigns(page: 1, status: 'Active');
      final mappedCampaigns = campaignResponse.data.map((c) {
        return DonationCampaign(
          id: c.id ?? 0,
          title: (c.title != null && c.title!.trim().isNotEmpty) ? c.title!.trim() : 'Program Donasi DonGiv',
          description: _cleanCampaignDescription(c.description),
          imageUrl: _normalizeImageUrl(c.image),
          targetAmount: c.targetAmount ?? 0.0,
          currentAmount: c.currentAmount ?? 0.0,
          category: (c.kategori ?? c.category ?? 'Umum').trim(),
        );
      }).toList();

      // Deduplikasi kampanye donasi berdasarkan ID untuk mencegah duplikasi data
      final Set<int> seenDonationIds = {};
      final List<DonationCampaign> campaigns = [];
      for (final camp in mappedCampaigns) {
        if (camp.id > 0 && seenDonationIds.add(camp.id)) {
          campaigns.add(camp);
        }
      }

      // 2. Fetch volunteer campaigns
      List<VolunteerCampaign> volunteerList = [];
      try {
        final volunteerResp = await VolunteerRepository.getVolunteerCampaignsRaw();
        if (volunteerResp.statusCode == 200) {
          final jsonData = json.decode(volunteerResp.body);
          final rawData = jsonData['data'];
          final List<dynamic> dataList = rawData is List
              ? rawData
              : (rawData is Map && rawData['data'] is List ? rawData['data'] : []);

          final mappedVolunteers = dataList
              .whereType<Map<String, dynamic>>()
              .map((item) => VolunteerCampaign.fromJson(item))
              .toList();

          // Deduplikasi kegiatan relawan berdasarkan ID
          final Set<int> seenVolunteerIds = {};
          for (final vol in mappedVolunteers) {
            if (vol.id > 0 && seenVolunteerIds.add(vol.id)) {
              volunteerList.add(vol);
            }
          }
        }
      } catch (vErr) {
        // Volunteer failure logged but will not crash the entire dashboard
      }

      if (mounted) {
        setState(() {
          _allCampaigns = campaigns;
          // Featured campaigns: ambil hingga 5 kampanye teratas dengan dana terkumpul tertinggi
          _featuredCampaigns = List<DonationCampaign>.from(campaigns)
            ..sort((a, b) => b.currentAmount.compareTo(a.currentAmount));
          if (_featuredCampaigns.length > 5) {
            _featuredCampaigns = _featuredCampaigns.take(5).toList();
          }

          _allVolunteerCampaigns = volunteerList;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal memuat data dari server. Silakan periksa koneksi Anda.';
        });
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    // Filter Donation
    List<DonationCampaign> filteredDonations = List.from(_allCampaigns);
    if (_selectedCategory != 'Semua') {
      filteredDonations = filteredDonations.where((c) {
        return c.category.toLowerCase().contains(_selectedCategory.toLowerCase());
      }).toList();
    }
    if (query.isNotEmpty) {
      filteredDonations = filteredDonations.where((c) {
        return c.title.toLowerCase().contains(query) ||
            c.category.toLowerCase().contains(query) ||
            c.description.toLowerCase().contains(query);
      }).toList();
    }
    _displayCampaigns = filteredDonations;

    // Filter Volunteers
    List<VolunteerCampaign> filteredVolunteers = List.from(_allVolunteerCampaigns);
    if (_selectedCategory != 'Semua') {
      filteredVolunteers = filteredVolunteers.where((v) {
        return v.category.toLowerCase().contains(_selectedCategory.toLowerCase());
      }).toList();
    }
    if (query.isNotEmpty) {
      filteredVolunteers = filteredVolunteers.where((v) {
        return v.title.toLowerCase().contains(query) ||
            v.location.toLowerCase().contains(query) ||
            v.description.toLowerCase().contains(query);
      }).toList();
    }
    _displayVolunteerCampaigns = filteredVolunteers;
  }

  String _cleanCampaignDescription(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Bantu saudara kita melalui program donasi terverifikasi ini.';
    }
    String text = raw.trim();
    if (text.contains('---')) {
      text = text.split('---').first.trim();
    }
    if (text.contains('📋')) {
      text = text.split('📋').first.trim();
    }
    // Bersihkan karakter aneh atau teks placeholder acak
    if (text.length < 5 || RegExp(r'^(jsk|ajs|asdf|test)+$', caseSensitive: false).hasMatch(text)) {
      return 'Bantu saudara kita melalui program donasi terverifikasi ini.';
    }
    return text.replaceAll(RegExp(r'\s+'), ' ');
  }

  String _normalizeImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty || rawUrl.contains('placeholder.jpg')) {
      return '';
    }
    String url = rawUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final base = AppConfig.apiUrl.replaceAll('/api', '');
      url = url.startsWith('/') ? '$base$url' : '$base/$url';
    }
    if (AppConfig.apiUrl.contains('10.0.2.2') && url.contains('127.0.0.1')) {
      url = url.replaceAll('127.0.0.1', '10.0.2.2');
    }
    if (AppConfig.apiUrl.contains('10.0.2.2') && url.contains('localhost')) {
      url = url.replaceAll('localhost', '10.0.2.2');
    }
    return url;
  }

  Widget _buildImagePlaceholder({
    required String title,
    required String category,
    bool isVolunteer = false,
    double? width,
    double? height,
  }) {
    final gradientColors = isVolunteer
        ? const [Color(0xFF0D9488), Color(0xFF14B8A6)]
        : const [Color(0xFF2972FF), Color(0xFF1E5AD6)];

    final icon = isVolunteer
        ? Icons.volunteer_activism_rounded
        : (category.toLowerCase().contains('bencana')
            ? Icons.health_and_safety_rounded
            : (category.toLowerCase().contains('kesehatan')
                ? Icons.local_hospital_rounded
                : (category.toLowerCase().contains('pendidikan')
                    ? Icons.school_rounded
                    : Icons.favorite_rounded)));

    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 5),
              Text(
                'DonGiv ${isVolunteer ? 'Relawan' : 'Peduli'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCompactCurrency(double amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)} M';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)} jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)} rb';
    }
    return 'Rp ${amount.toInt()}';
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
    return SafeArea(
      child: RefreshIndicator(
        color: kPrimaryColor,
        onRefresh: _fetchAllData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // 1. HEADER & SEARCH
            SliverToBoxAdapter(
              child: _buildHeaderAndSearch(),
            ),

            // 2. ACTIVITY TYPE SWITCHER (Donasi vs Relawan)
            SliverToBoxAdapter(
              child: _buildActivitySwitcher(),
            ),

            if (_isLoading)
              SliverToBoxAdapter(
                child: _buildSkeletonLoader(),
              )
            else if (_errorMessage != null)
              SliverToBoxAdapter(
                child: _buildErrorState(),
              )
            else ...[
              // 3. KAMPANYE UNGGULAN (CAROUSEL)
              if (_selectedActivityType == 0 && _featuredCampaigns.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildFeaturedSectionHeader(),
                ),
                SliverToBoxAdapter(
                  child: _buildFeaturedCarousel(),
                ),
              ],

              // 4. JELAJAHI KEBAIKAN (CATEGORY CHIPS)
              SliverToBoxAdapter(
                child: _buildExploreCategoryChips(),
              ),

              // 5. MAIN CONTENT BASED ON SELECTED ACTIVITY
              if (_selectedActivityType == 0) ...[
                // DONASI CONTENT
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    title: 'Mendesak & Pilihan',
                    subtitle: 'Bantuan segera untuk saudara kita',
                    actionText: 'Lihat Semua',
                    onAction: widget.onGoToDonationTab,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildDonationList(),
                ),

                // Rekomendasi Kegiatan Relawan di bawah Donasi
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    title: 'Aksi Relawan Pilihan',
                    subtitle: 'Bantu dengan tenaga dan keahlianmu',
                    actionText: 'Lihat Semua',
                    onAction: widget.onGoToVolunteerTab,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildVolunteerHorizontalPreview(),
                ),
              ] else ...[
                // RELAWAN CONTENT
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    title: 'Kegiatan Relawan Tersedia',
                    subtitle: 'Jadilah bagian dari perubahan positif',
                    actionText: 'Jelajahi Lengkap',
                    onAction: widget.onGoToVolunteerTab,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildVolunteerVerticalList(),
                ),
              ],

                // 6. CARA BERDONASI (3 Langkah Mudah)
                SliverToBoxAdapter(
                  child: _buildHowToDonateSection(),
                ),

                // 7. ULASAN SAHABAT DONGIV (Cerita & Testimoni Carousel)
                SliverToBoxAdapter(
                  child: _buildTestimonialsSection(),
                ),

                // 8. BOTTOM TRUST & TRANSPARENCY BANNER
                SliverToBoxAdapter(
                  child: _buildTrustAndReviewsSection(),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 80),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // HEADER & SEARCH
  // --------------------------------------------------------------------------
  Widget _buildHeaderAndSearch() {
    final greeting = _userName.isNotEmpty
        ? 'Halo, ${_userName.split(' ').first}!'
        : 'Halo, Sahabat DonGiv!';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo & Sapaan
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2972FF), Color(0xFF1E5AD6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Don',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: kPrimaryColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Giv',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: kTextPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        greeting,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Notification Bell with Badge
              InkWell(
                onTap: () async {
                  await Navigator.pushNamed(context, '/notifications');
                  _loadUnreadNotifications();
                },
                borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: kSurfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Icon(
                            Icons.notifications_outlined,
                            color: kTextPrimary,
                            size: 22,
                          ),
                          if (_unreadNotifications > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Text(
                                  _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),

          const SizedBox(height: 16),

          // Search Field
          Container(
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                FocusScope.of(context).unfocus();
              },
              onChanged: (_) {
                setState(() {
                  _applyFilters();
                });
              },
              decoration: InputDecoration(
                hintText: _selectedActivityType == 0
                    ? 'Cari program donasi, bencana, atau medis...'
                    : 'Cari kegiatan relawan, lokasi, atau aksi...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 22),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _applyFilters();
                          });
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 2. ACTIVITY TYPE SWITCHER (Donasi & Relawan)
  // --------------------------------------------------------------------------
  Widget _buildActivitySwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Donasi Tab
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_selectedActivityType != 0) {
                    setState(() {
                      _selectedActivityType = 0;
                      _selectedCategory = 'Semua';
                      _applyFilters();
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedActivityType == 0 ? kSurfaceColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _selectedActivityType == 0
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_rounded,
                        size: 18,
                        color: _selectedActivityType == 0 ? kPrimaryColor : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Program Donasi',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: _selectedActivityType == 0 ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedActivityType == 0 ? kPrimaryColor : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Relawan Tab
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_selectedActivityType != 1) {
                    setState(() {
                      _selectedActivityType = 1;
                      _selectedCategory = 'Semua';
                      _applyFilters();
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedActivityType == 1 ? kSurfaceColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _selectedActivityType == 1
                        ? [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.volunteer_activism_rounded,
                        size: 18,
                        color: _selectedActivityType == 1 ? kPrimaryColor : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Aksi Relawan',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: _selectedActivityType == 1 ? FontWeight.w700 : FontWeight.w500,
                          color: _selectedActivityType == 1 ? kPrimaryColor : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 3. FEATURED CAMPAIGNS CAROUSEL
  // --------------------------------------------------------------------------
  Widget _buildFeaturedSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.stars_rounded, color: Color(0xFFEAB308), size: 22),
              SizedBox(width: 6),
              Text(
                'Kampanye Unggulan',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          if (_featuredCampaigns.length > 1)
            Row(
              children: List.generate(
                _featuredCampaigns.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: _currentFeaturedIndex == index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentFeaturedIndex == index ? kPrimaryColor : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCarousel() {
    return SizedBox(
      height: 215,
      child: PageView.builder(
        controller: _featuredPageController,
        physics: const BouncingScrollPhysics(),
        itemCount: _featuredCampaigns.length,
        onPageChanged: (index) {
          setState(() {
            _currentFeaturedIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final campaign = _featuredCampaigns[index];
          final progress = campaign.progress;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/campaign_detail',
                    arguments: campaign,
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image or Consistent Placeholder
                    campaign.imageUrl.isEmpty
                        ? _buildImagePlaceholder(
                            title: campaign.title,
                            category: campaign.category,
                          )
                        : CachedNetworkImage(
                            imageUrl: campaign.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: const Color(0xFFE2E8F0),
                              child: const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => _buildImagePlaceholder(
                              title: campaign.title,
                              category: campaign.category,
                            ),
                          ),

                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.35),
                            Colors.black.withValues(alpha: 0.88),
                          ],
                          stops: const [0.25, 0.55, 1.0],
                        ),
                      ),
                    ),

                    // Tag Kategori & Prioritas
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_rounded, color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              campaign.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Content & Actions
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            campaign.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            campaign.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11.5,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Progress Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 5,
                              backgroundColor: Colors.white.withValues(alpha: 0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Terkumpul',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.75),
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        _formatCompactCurrency(campaign.currentAmount),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Target',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.75),
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        _formatCompactCurrency(campaign.targetAmount),
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/campaign_detail',
                                    arguments: campaign,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: kPrimaryColor,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text(
                                  'Donasi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
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
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 4. JELAJAHI KEBAIKAN (CATEGORY CHIPS)
  // --------------------------------------------------------------------------
  Widget _buildExploreCategoryChips() {
    final categories = _selectedActivityType == 0 ? _donationCategories : _volunteerCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Row(
            children: [
              Icon(Icons.explore_outlined, color: kPrimaryColor, size: 20),
              SizedBox(width: 6),
              Text(
                'Jelajahi Kebaikan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = cat;
                      _applyFilters();
                    });
                  },
                  showCheckmark: false,
                  backgroundColor: kSurfaceColor,
                  selectedColor: kPrimaryColor,
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : kTextSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: isSelected ? kPrimaryColor : const Color(0xFFE2E8F0),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // SECTION HEADERS
  // --------------------------------------------------------------------------
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: kTextPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Text(
                    actionText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: kPrimaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 5. DONATION CAMPAIGNS LIST (HORIZONTAL)
  // --------------------------------------------------------------------------
  Widget _buildDonationList() {
    if (_displayCampaigns.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Tidak Ada Kampanye',
        message: 'Tidak ditemukan program donasi untuk kategori atau pencarian ini.',
        onReset: () {
          _searchController.clear();
          setState(() {
            _selectedCategory = 'Semua';
            _applyFilters();
          });
        },
      );
    }

    return SizedBox(
      height: 295,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _displayCampaigns.length,
        itemBuilder: (context, index) {
          final campaign = _displayCampaigns[index];
          return _buildModernDonationCard(campaign);
        },
      ),
    );
  }

  Widget _buildModernDonationCard(DonationCampaign campaign) {
    final progress = campaign.progress;
    final percent = (progress * 100).toInt();

    return Container(
      width: 248,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/campaign_detail',
            arguments: campaign,
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar & Badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                  child: campaign.imageUrl.isEmpty
                      ? _buildImagePlaceholder(
                          title: campaign.title,
                          category: campaign.category,
                          height: 125,
                        )
                      : CachedNetworkImage(
                          imageUrl: campaign.imageUrl,
                          height: 125,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 125,
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryColor),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => _buildImagePlaceholder(
                            title: campaign.title,
                            category: campaign.category,
                            height: 125,
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      campaign.category,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: kPrimaryColor,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Konten
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Info Finansial: Terkumpul & Target
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Terkumpul',
                            style: TextStyle(fontSize: 9.5, color: kTextSecondary, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _formatCompactCurrency(campaign.currentAmount),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: kPrimaryColor,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Target',
                            style: TextStyle(fontSize: 9.5, color: kTextSecondary, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            _formatCompactCurrency(campaign.targetAmount),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // VOLUNTEER PREVIEW (HORIZONTAL DI TAB DONASI)
  // --------------------------------------------------------------------------
  Widget _buildVolunteerHorizontalPreview() {
    if (_allVolunteerCampaigns.isEmpty) {
      return _buildEmptyState(
        icon: Icons.volunteer_activism_outlined,
        title: 'Belum Ada Kegiatan Relawan',
        message: 'Kegiatan relawan akan segera dibuka. Pantau terus ya!',
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _allVolunteerCampaigns.length > 5 ? 5 : _allVolunteerCampaigns.length,
        itemBuilder: (context, index) {
          final volunteer = _allVolunteerCampaigns[index];
          return _buildModernVolunteerHorizontalCard(volunteer);
        },
      ),
    );
  }

  Widget _buildModernVolunteerHorizontalCard(VolunteerCampaign volunteer) {
    return Container(
      width: 238,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/volunteer_campaign_detail',
            arguments: volunteer,
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                  child: volunteer.imageUrl.isEmpty
                      ? _buildImagePlaceholder(
                          title: volunteer.title,
                          category: volunteer.category,
                          isVolunteer: true,
                          height: 105,
                        )
                      : CachedNetworkImage(
                          imageUrl: _normalizeImageUrl(volunteer.imageUrl),
                          height: 105,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 105,
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D9488)),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => _buildImagePlaceholder(
                            title: volunteer.title,
                            category: volunteer.category,
                            isVolunteer: true,
                            height: 105,
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      volunteer.category.isNotEmpty ? volunteer.category : 'Relawan',
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    volunteer.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          volunteer.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: kTextSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 13, color: Color(0xFF0D9488)),
                      const SizedBox(width: 4),
                      Text(
                        '${volunteer.registeredVolunteers}/${volunteer.maxVolunteers} Relawan',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D9488),
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
    );
  }

  // --------------------------------------------------------------------------
  // VOLUNTEER MAIN LIST (VERTICAL DI TAB RELAWAN)
  // --------------------------------------------------------------------------
  Widget _buildVolunteerVerticalList() {
    if (_displayVolunteerCampaigns.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off_rounded,
        title: 'Tidak Ada Aksi Relawan',
        message: 'Tidak ditemukan kegiatan relawan yang sesuai dengan pencarian atau kategori ini.',
        onReset: () {
          _searchController.clear();
          setState(() {
            _selectedCategory = 'Semua';
            _applyFilters();
          });
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _displayVolunteerCampaigns.map((volunteer) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/volunteer_campaign_detail',
                  arguments: volunteer,
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: volunteer.imageUrl.isEmpty
                          ? _buildImagePlaceholder(
                              title: volunteer.title,
                              category: volunteer.category,
                              isVolunteer: true,
                              width: 88,
                              height: 88,
                            )
                          : CachedNetworkImage(
                              imageUrl: _normalizeImageUrl(volunteer.imageUrl),
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 88,
                                height: 88,
                                color: const Color(0xFFF1F5F9),
                                child: const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0D9488)),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => _buildImagePlaceholder(
                                title: volunteer.title,
                                category: volunteer.category,
                                isVolunteer: true,
                                width: 88,
                                height: 88,
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              volunteer.category.isNotEmpty ? volunteer.category : 'Aksi Sosial',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            volunteer.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  volunteer.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11, color: kTextSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDate(volunteer.startDate),
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: kPrimaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${volunteer.registeredVolunteers}/${volunteer.maxVolunteers} Relawan',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: kPrimaryColor,
                                  ),
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
          );
        }).toList(),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 6. CARA BERDONASI (3 Langkah Mudah)
  // --------------------------------------------------------------------------
  Widget _buildHowToDonateSection() {
    final steps = [
      {
        'number': '1',
        'title': 'Pilih Kampanye',
        'desc': 'Pilih program donasi yang ingin kamu dukung.',
        'icon': Icons.favorite_rounded,
        'color': const Color(0xFF2972FF),
        'bg': const Color(0xFFEFF6FF),
      },
      {
        'number': '2',
        'title': 'Lakukan Donasi',
        'desc': 'Tentukan nominal & bayar aman di aplikasi.',
        'icon': Icons.account_balance_wallet_rounded,
        'color': const Color(0xFF0D9488),
        'bg': const Color(0xFFF0FDFA),
      },
      {
        'number': '3',
        'title': 'Pantau Penyaluran',
        'desc': 'Lihat riwayat dan laporan penyaluran nyata.',
        'icon': Icons.track_changes_rounded,
        'color': const Color(0xFF6366F1),
        'bg': const Color(0xFFEEF2FF),
      },
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 18, color: kPrimaryColor),
                  SizedBox(width: 6),
                  Text(
                    'Cara Berdonasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kTextPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '3 Langkah Mudah',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: kPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: index < steps.length - 1 ? 8 : 0,
                  ),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: step['bg'] as Color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              step['icon'] as IconData,
                              size: 16,
                              color: step['color'] as Color,
                            ),
                          ),
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (step['color'] as Color).withValues(alpha: 0.12),
                            ),
                            child: Center(
                              child: Text(
                                step['number'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: step['color'] as Color,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step['title'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        step['desc'] as String,
                        style: const TextStyle(
                          fontSize: 10,
                          color: kTextSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 7. ULASAN SAHABAT DONGIV (Horizontal Carousel)
  // --------------------------------------------------------------------------
  Widget _buildTestimonialsSection() {
    if (_isLoadingReviews) {
      return Container(
        height: 180,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(20),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasSampleReviews = _reviews.any((r) => r.isSample);

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            size: 18,
                            color: kPrimaryColor,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Cerita Sahabat DonGiv',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: kTextPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Kata #OrangBaik yang telah berbagi dan beraksi nyata',
                        style: TextStyle(
                          fontSize: 12,
                          color: kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasSampleReviews)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Text(
                          'Preview',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.pushNamed(context, '/reviews');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Lihat Semua',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: kPrimaryColor,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: kPrimaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal Carousel
          SizedBox(
            height: 200,
            child: PageView.builder(
              controller: _reviewPageController,
              itemCount: _reviews.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentReviewIndex = index);
              },
              itemBuilder: (context, index) {
                final review = _reviews[index];
                final isSelected = index == _currentReviewIndex;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.only(
                    left: index == 0 ? 20 : 6,
                    right: index == _reviews.length - 1 ? 20 : 6,
                    top: isSelected ? 2 : 10,
                    bottom: isSelected ? 4 : 12,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? kPrimaryColor.withValues(alpha: 0.35)
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: isSelected ? 0.08 : 0.03),
                        blurRadius: isSelected ? 14 : 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Avatar, Name, Role, Rating
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: const Color(0xFFEFF6FF),
                            backgroundImage: review.avatarUrl != null && review.avatarUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(review.avatarUrl!)
                                : null,
                            child: review.avatarUrl == null || review.avatarUrl!.isEmpty
                                ? Text(
                                    review.name.isNotEmpty ? review.name[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: kPrimaryColor,
                                      fontSize: 16,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.name,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: kTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        review.role,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: kPrimaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (review.rating != null) ...[
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                review.rating!.round(),
                                (i) => const Icon(
                                  Icons.star_rounded,
                                  size: 15,
                                  color: Color(0xFFF59E0B),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Review quote
                      Expanded(
                        child: Text(
                          '"${review.content}"',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF334155),
                            height: 1.45,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Dots indicator
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_reviews.length, (index) {
              final isCurrent = index == _currentReviewIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isCurrent ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isCurrent ? kPrimaryColor : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // 8. TRUST & REVIEWS SECTION
  // --------------------------------------------------------------------------
  Widget _buildTrustAndReviewsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: Color(0xFF38BDF8),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Donasi Aman & Terpercaya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Setiap program melalui verifikasi tim DonGiv',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTrustStat('100%', 'Transparan'),
                  Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.15)),
                  _buildTrustStat('24/7', 'Penyaluran'),
                  Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.15)),
                  _buildTrustStat('Terverifikasi', 'Oleh Sistem'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF38BDF8),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // SKELETON / LOADING / ERROR / EMPTY STATES
  // --------------------------------------------------------------------------
  Widget _buildSkeletonLoader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner skeleton
          Container(
            height: 190,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          const SizedBox(height: 24),
          // Chips skeleton
          Row(
            children: List.generate(
              3,
              (index) => Container(
                margin: const EdgeInsets.only(right: 10),
                width: 80,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Cards skeleton
          Row(
            children: List.generate(
              2,
              (index) => Container(
                margin: const EdgeInsets.only(right: 14),
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 44,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Data',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? 'Terjadi kendala saat terhubung ke server.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: kTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchAllData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    VoidCallback? onReset,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: kTextSecondary,
              ),
            ),
            if (onReset != null) ...[
              const SizedBox(height: 14),
              TextButton(
                onPressed: onReset,
                child: const Text(
                  'Reset Pencarian & Filter',
                  style: TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}