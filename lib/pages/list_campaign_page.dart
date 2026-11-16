import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/donation_campaign.dart';
import '../repositories/campaign_repository.dart';
import '../config/app_config.dart';

// Brand colors konsisten dengan DonGiv
const Color kPrimaryColor = Color(0xFF2972FF);
const Color kBackgroundColor = Color(0xFFF8FAFC);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF64748B);
const Color kSurfaceColor = Colors.white;

class ListCampaignPage extends StatefulWidget {
  const ListCampaignPage({Key? key}) : super(key: key);

  @override
  State<ListCampaignPage> createState() => _ListCampaignPageState();
}

class _ListCampaignPageState extends State<ListCampaignPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Data master dari API Laravel
  List<DonationCampaign> _allCampaigns = [];
  // Data hasil filter & pencarian
  List<DonationCampaign> _displayCampaigns = [];

  String _selectedCategory = "Semua";
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'Semua',
    'Bencana Alam',
    'Sosial Kemanusiaan',
    'Kesehatan',
    'Pendidikan',
    'Lingkungan',
    'Infrastruktur',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCampaigns();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getFriendlyErrorMessage(dynamic error) {
    final errStr = error.toString().toLowerCase();
    if (errStr.contains('404') || errStr.contains('tidak ditemukan')) {
      return 'Program donasi belum tersedia saat ini.';
    } else if (errStr.contains('401') || errStr.contains('403') || errStr.contains('izin')) {
      return 'Akses ditolak atau sesi telah berakhir.';
    } else if (errStr.contains('500') || errStr.contains('gangguan') || errStr.contains('server')) {
      return 'Layanan sedang dalam pemeliharaan. Silakan coba sesaat lagi.';
    } else if (errStr.contains('koneksi') ||
        errStr.contains('socket') ||
        errStr.contains('terhubung') ||
        errStr.contains('clientexception')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    return 'Terjadi kendala saat memuat data. Silakan coba lagi.';
  }

  /// Normalisasi URL gambar backend: tangani localhost, 10.0.2.2 emulator, dan deteksi placeholder
  String _normalizeImageUrl(String? rawUrl) {
    if (rawUrl == null ||
        rawUrl.isEmpty ||
        rawUrl.contains('placeholder.jpg') ||
        rawUrl.contains('via.placeholder')) {
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

  /// Bersihkan deskripsi dari karakter divider markdown atau teks acak
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
    if (text.length < 5 || RegExp(r'^(jsk|ajs|asdf|test)+$', caseSensitive: false).hasMatch(text)) {
      return 'Bantu saudara kita melalui program donasi terverifikasi ini.';
    }
    return text.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Format angka ke Rupiah standar Indonesia: Rp250.000 atau Rp0
  String _formatRupiah(double amount) {
    final int val = amount.toInt();
    if (val == 0) return 'Rp0';
    final str = val.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i > 0) {
        buffer.write('.');
      }
    }
    return 'Rp${buffer.toString().split('').reversed.join('')}';
  }

  /// Placeholder gambar branded DonGiv yang unik berdasarkan kategori (bukan 1 gambar duplikat)
  Widget _buildImagePlaceholder({
    required String title,
    required String category,
  }) {
    final catLower = category.toLowerCase();
    IconData icon = Icons.favorite_rounded;
    if (catLower.contains('bencana')) {
      icon = Icons.health_and_safety_rounded;
    } else if (catLower.contains('sehat') || catLower.contains('medis')) {
      icon = Icons.local_hospital_rounded;
    } else if (catLower.contains('didik') || catLower.contains('sekolah')) {
      icon = Icons.school_rounded;
    } else if (catLower.contains('lingkung')) {
      icon = Icons.forest_rounded;
    } else if (catLower.contains('sosial')) {
      icon = Icons.volunteer_activism_rounded;
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2972FF), Color(0xFF1E5AD6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: -15,
            bottom: -15,
            child: Container(
              width: 80,
              height: 80,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 5),
              const Text(
                'DonGiv Peduli',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
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

  Future<void> _fetchCampaigns() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
      });

      // Ambil kampanye status verified sesuai aturan bisnis DonGiv
      final response = await CampaignRepository.getCampaigns(
        page: 1,
        status: 'verified',
      );

      final mapped = response.data.map((c) => DonationCampaign(
        id: c.id ?? 0,
        title: (c.title != null && c.title!.trim().isNotEmpty) ? c.title!.trim() : 'Program Donasi DonGiv',
        description: _cleanCampaignDescription(c.description),
        imageUrl: _normalizeImageUrl(c.image),
        targetAmount: c.targetAmount ?? 0.0,
        currentAmount: c.currentAmount ?? 0.0,
        category: (c.kategori ?? c.category ?? 'Umum').trim(),
      )).toList();

      // Deduplikasi kampanye berdasarkan ID
      final Set<int> seenIds = {};
      final List<DonationCampaign> cleanData = [];
      for (final item in mapped) {
        if (item.id > 0 && seenIds.add(item.id)) {
          cleanData.add(item);
        }
      }

      if (mounted) {
        setState(() {
          _allCampaigns = cleanData;
          _isLoading = false;
          _applyFilterAndSearch();
        });
      }
    } catch (e) {
      debugPrint('Error fetching campaigns: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = _getFriendlyErrorMessage(e);
        });
      }
    }
  }

  Future<void> _refreshCampaigns() async {
    await _fetchCampaigns();
  }

  void _filterData(String category) {
    setState(() {
      _selectedCategory = category;
      _applyFilterAndSearch();
    });
  }

  void _applyFilterAndSearch() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _displayCampaigns = _allCampaigns.where((item) {
        // Filter kategori
        bool matchesCategory = true;
        if (_selectedCategory != "Semua") {
          final cat = item.category.toLowerCase().trim();
          final sel = _selectedCategory.toLowerCase().trim();
          matchesCategory = cat == sel || cat.contains(sel) || sel.contains(cat);
        }

        // Filter kata kunci pencarian
        bool matchesQuery = true;
        if (query.isNotEmpty) {
          final title = item.title.toLowerCase();
          final desc = item.description.toLowerCase();
          final cat = item.category.toLowerCase();
          matchesQuery = title.contains(query) || desc.contains(query) || cat.contains(query);
        }

        return matchesCategory && matchesQuery;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = (screenWidth - 28 - 12) / 2;
    // Tinggi konten: 174.5px (kategori, judul, deskripsi, progress, nominal, tombol, padding)
    // Tinggi gambar (4:3): cardWidth * 0.75
    final double cardHeight = (cardWidth * 0.75) + 175;
    final double calculatedAspectRatio = (cardWidth / cardHeight).clamp(0.53, 0.62);

    return _hasError
        ? _buildErrorState()
        : Scaffold(
            backgroundColor: kBackgroundColor,
            body: RefreshIndicator(
              color: kPrimaryColor,
              onRefresh: _refreshCampaigns,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                slivers: [
                  // 1. APP BAR
                  SliverAppBar(
                    automaticallyImplyLeading: false,
                    leading: Navigator.canPop(context)
                        ? IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: kTextPrimary, size: 20),
                            onPressed: () => Navigator.pop(context),
                          )
                        : null,
                    backgroundColor: Colors.white,
                    pinned: true,
                    elevation: 0,
                    centerTitle: true,
                    title: const Text(
                      "Program Donasi",
                      style: TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),

                  // 2. SEARCH BAR & FILTER CHIPS
                  SliverToBoxAdapter(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search TextField
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => FocusScope.of(context).unfocus(),
                              onChanged: (_) => _applyFilterAndSearch(),
                              decoration: InputDecoration(
                                hintText: 'Cari program donasi atau bencana...',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                                        onPressed: () {
                                          _searchController.clear();
                                          _applyFilterAndSearch();
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
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
                  ),

                  // 3. GRID KARTU KAMPANYE (2 KOLOM)
                  if (_isLoading && _allCampaigns.isEmpty)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                        ),
                      ),
                    )
                  else if (_displayCampaigns.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: calculatedAspectRatio,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 14,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildModernGridCard(_displayCampaigns[index]),
                          childCount: _displayCampaigns.length,
                        ),
                      ),
                    ),

                  // 4. SPACER BAWAH (Menjaga ruang untuk BottomNav & Floating Assistant)
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 95),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedCategory.toLowerCase() == label.toLowerCase();

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _filterData(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? kPrimaryColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? kPrimaryColor : const Color(0xFFE2E8F0),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: kPrimaryColor.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : kTextSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernGridCard(DonationCampaign data) {
    final double current = data.currentAmount;
    final double target = data.targetAmount;
    final double progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final int percent = target > 0 ? ((current / target) * 100).round() : 0;
    final imageUrl = data.imageUrl;

    return Container(
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. GAMBAR KAMPANYE (Rasio Konsisten 4:3)
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: imageUrl.isEmpty
                      ? _buildImagePlaceholder(
                          title: data.title,
                          category: data.category,
                        )
                      : CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: kPrimaryColor,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => _buildImagePlaceholder(
                            title: data.title,
                            category: data.category,
                          ),
                        ),
                ),

                // 2. KONTEN KARTU
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Kategori
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data.category.isNotEmpty ? data.category : 'Umum',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: kPrimaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Judul Kampanye
                      SizedBox(
                        height: 32,
                        child: Text(
                          data.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: kTextPrimary,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),

                      // Deskripsi Singkat
                      SizedBox(
                        height: 26,
                        child: Text(
                          data.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: kTextSecondary,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Progres Donasi
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4.5,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Nominal Terkumpul & Persentase Pencapaian
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Expanded(
                            child: Text(
                              _formatRupiah(current),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11.5,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$percent%',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Tombol Aksi "Donasi Sekarang"
                      SizedBox(
                        width: double.infinity,
                        height: 31,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/donation_form',
                              arguments: data,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.favorite_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Donasi Sekarang',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.1,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
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
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off_rounded, size: 44, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            const Text(
              "Program Tidak Ditemukan",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kTextPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              _searchController.text.isNotEmpty
                  ? "Tidak ada program donasi dengan kata kunci '${_searchController.text}'."
                  : _selectedCategory == "Semua"
                      ? "Saat ini belum ada program donasi yang tersedia."
                      : "Tidak ada program donasi di kategori '$_selectedCategory'.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextSecondary, fontSize: 13),
            ),
            if (_selectedCategory != "Semua" || _searchController.text.isNotEmpty) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _filterData("Semua");
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text("Tampilkan Semua"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimaryColor,
                  side: const BorderSide(color: kPrimaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Program Donasi",
          style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_off_rounded, size: 52, color: Colors.redAccent),
              ),
              const SizedBox(height: 20),
              const Text(
                'Gagal Memuat Program',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                style: const TextStyle(color: kTextSecondary, fontSize: 13.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchCampaigns,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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