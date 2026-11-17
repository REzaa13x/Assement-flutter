import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/volunteer_certificate.dart';
import '../repositories/certificate_repository.dart';
import '../services/auth_service.dart';

const Color kPrimaryColor = Color(0xFF2972FF);
const Color kBackgroundColor = Color(0xFFF8FAFC);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF64748B);

class MyCertificatesPage extends StatefulWidget {
  const MyCertificatesPage({Key? key}) : super(key: key);

  @override
  State<MyCertificatesPage> createState() => _MyCertificatesPageState();
}

class _MyCertificatesPageState extends State<MyCertificatesPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  List<VolunteerCertificate> _certificates = [];
  CertificateMeta? _meta;
  final Set<int> _downloadingIds = {};
  String _selectedFilter = 'all'; // 'all', 'active', 'pending'

  @override
  void initState() {
    super.initState();
    _fetchCertificates();
  }

  Future<void> _fetchCertificates() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Anda belum login. Silakan login terlebih dahulu.');
      }

      final result =
          await CertificateRepository.getMyCertificates(token: token);

      if (mounted) {
        setState(() {
          _certificates = result.certificates;
          _meta = result.meta;
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

  List<VolunteerCertificate> get _filteredCertificates {
    if (_selectedFilter == 'active') {
      return _certificates.where((c) => c.isActive).toList();
    } else if (_selectedFilter == 'pending') {
      return _certificates.where((c) => c.isPending).toList();
    } else if (_selectedFilter == 'revoked') {
      return _certificates.where((c) => c.isRevoked).toList();
    }
    return _certificates;
  }

  Future<void> _handleDownloadCertificate(VolunteerCertificate cert) async {
    if (_downloadingIds.contains(cert.id)) return;
    if (!cert.isDownloadable) {
      _showWarningSnackBar(
        'Sertifikat belum dapat diunduh. Kampanye harus selesai terlebih dahulu.',
      );
      return;
    }

    setState(() => _downloadingIds.add(cert.id));
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Menyiapkan file sertifikat PDF...')),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      final token = await AuthService.getToken();
      final downloadUrl =
          await CertificateRepository.getDownloadUrl(cert.id, token: token);
      final opened = await launchUrl(Uri.parse(downloadUrl),
          mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
      if (!opened) throw Exception('Tidak dapat membuka unduhan sertifikat.');
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal mengunduh sertifikat: $e');
      }
    } finally {
      if (mounted) setState(() => _downloadingIds.remove(cert.id));
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.amber[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Sertifikat Saya',
          style: TextStyle(
            color: kTextPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: kTextPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kPrimaryColor),
            tooltip: 'Segarkan',
            onPressed: _fetchCertificates,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchCertificates,
        color: kPrimaryColor,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: kPrimaryColor))
            : _hasError
                ? _buildErrorState()
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // 1. Header Ringkasan Kontribusi Relawan
        _buildContributionSummaryCard(),
        const SizedBox(height: 20),

        // 2. Filter Tab
        _buildFilterChips(),
        const SizedBox(height: 16),

        // 3. Daftar Sertifikat atau Empty State
        if (_filteredCertificates.isEmpty)
          _buildEmptyState()
        else
          ..._filteredCertificates
              .map((cert) => _buildCertificateCard(cert))
              .toList(),
      ],
    );
  }

  Widget _buildContributionSummaryCard() {
    final String level = _meta?.volunteerLevel ?? 'Relawan Baru';
    final int totalCert = _meta?.total ?? _certificates.length;
    final int activeCert =
        _meta?.totalActive ?? _certificates.where((c) => c.isActive).length;
    final int totalHours = _meta?.totalHours ??
        _certificates
            .where((c) => c.isActive)
            .fold(0, (sum, c) => sum + c.totalVolunteerHours);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TINGKAT KONTRIBUSI',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDBEAFE),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        level,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )),
                ],
              )),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Resmi',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: LayoutBuilder(
                builder: (context, constraints) => Wrap(
                      spacing: 12,
                      runSpacing: 16,
                      children: [
                        _buildStatItem('Total', '$totalCert', 'Sertifikat'),
                        _buildStatItem('Aktif', '$activeCert', 'Dapat Diunduh'),
                        _buildStatItem(
                            'Kampanye',
                            '${_meta?.totalCampaigns ?? _certificates.map((c) => c.campaignId).whereType<int>().toSet().length}',
                            'Kampanye Relawan'),
                        _buildStatItem(
                            'Kontribusi', '$totalHours', 'Total Jam'),
                      ]
                          .map((item) => SizedBox(
                              width: (constraints.maxWidth - 12) / 2,
                              child: item))
                          .toList(),
                    )),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String sub) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFFBFDBFE),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('all', 'Semua (${_certificates.length})'),
          const SizedBox(width: 8),
          _buildFilterChip('active',
              'Aktif (${_certificates.where((c) => c.isActive).length})'),
          const SizedBox(width: 8),
          _buildFilterChip('pending',
              'Menunggu Selesai (${_certificates.where((c) => c.isPending).length})'),
          const SizedBox(width: 8),
          _buildFilterChip('revoked',
              'Dicabut (${_certificates.where((c) => c.isRevoked).length})'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = key;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : kTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildCertificateCard(VolunteerCertificate cert) {
    final bool isDownloadable = cert.isDownloadable;
    final bool isPending = cert.isPending;

    // Status styling
    Color statusBg = const Color(0xFFF1F5F9);
    Color statusTextColor = const Color(0xFF475569);
    IconData statusIcon = Icons.info_outline;

    if (cert.isActive) {
      statusBg = const Color(0xFFDCFCE7);
      statusTextColor = const Color(0xFF16A34A);
      statusIcon = Icons.check_circle_rounded;
    } else if (isPending) {
      statusBg = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFFD97706);
      statusIcon = Icons.access_time_rounded;
    } else if (cert.isRevoked) {
      statusBg = const Color(0xFFFEE2E2);
      statusTextColor = const Color(0xFFDC2626);
      statusIcon = Icons.cancel_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Nomor & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.card_membership_rounded,
                            color: kPrimaryColor, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cert.certificateNumber,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusTextColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        cert.statusLabel,
                        style: TextStyle(
                          color: statusTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Nama Kampanye
            Text(
              cert.campaignName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextPrimary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),

            // Kategori, Lokasi, Jam
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _buildInfoTag(Icons.category_outlined, cert.category),
                _buildInfoTag(Icons.location_on_outlined, cert.location),
                _buildInfoTag(
                    Icons.schedule, '${cert.totalVolunteerHours} Jam'),
              ],
            ),

            if (cert.startDate != null || cert.endDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.date_range_outlined,
                      size: 13, color: kTextSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(
                    'Periode: ${cert.startDate ?? "-"} s/d ${cert.endDate ?? "-"}',
                    style: const TextStyle(fontSize: 11, color: kTextSecondary),
                  )),
                ],
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 14),

            // Pending info banner jika belum dapat diunduh
            if (isPending)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFFD97706), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sertifikat resmi dapat diunduh setelah kampanye selesai dilaksanakan pada ${cert.endDate ?? "jadwal yang ditentukan"}.',
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF92400E),
                            height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

            // Action Buttons
            Row(
              children: [
                // Tombol Lihat Detail
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/certificate_detail',
                        arguments: cert,
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Lihat Detail',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryColor,
                      side: const BorderSide(color: kPrimaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Tombol Unduh PDF (hanya aktif jika isDownloadable)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isDownloadable
                        ? () => _handleDownloadCertificate(cert)
                        : null,
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Unduh PDF',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: kTextSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
              fontSize: 12, color: kTextSecondary, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDBEAFE), width: 2),
            ),
            child: const Icon(
              Icons.card_membership_rounded,
              size: 54,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum Ada Sertifikat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sertifikat digital resmi akan tersedia setelah Anda menyelesaikan kegiatan relawan yang disetujui admin dan kampanye telah berakhir sesuai ketentuan DonGiv.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: kTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/volunteer_campaigns');
            },
            icon: const Icon(Icons.volunteer_activism_rounded, size: 18),
            label: const Text('Jelajahi Kegiatan Relawan',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.red),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Sertifikat',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Terjadi kesalahan pada koneksi server.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: kTextSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchCertificates,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
