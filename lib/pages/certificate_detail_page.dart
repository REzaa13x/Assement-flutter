import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/volunteer_certificate.dart';
import '../repositories/certificate_repository.dart';
import '../services/auth_service.dart';

const Color kPrimaryColor = Color(0xFF2972FF);
const Color kBackgroundColor = Color(0xFFF8FAFC);
const Color kTextPrimary = Color(0xFF0F172A);
const Color kTextSecondary = Color(0xFF64748B);
const Color kGoldColor = Color(0xFFD4A851);

class CertificateDetailPage extends StatefulWidget {
  final VolunteerCertificate? certificate;

  const CertificateDetailPage({Key? key, this.certificate}) : super(key: key);

  @override
  State<CertificateDetailPage> createState() => _CertificateDetailPageState();
}

class _CertificateDetailPageState extends State<CertificateDetailPage> {
  VolunteerCertificate? _certificate;
  bool _isLoading = false;
  bool _isDownloading = false;
  bool _isVerifying = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _certificate = widget.certificate;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_certificate != null) {
        _fetchDetail(_certificate!.id);
        return;
      }
      if (_certificate == null) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is VolunteerCertificate) {
          setState(() {
            _certificate = args;
          });
        } else if (args is int) {
          _fetchDetail(args);
        } else if (args is Map && args['id'] != null) {
          final int id = args['id'] is int
              ? args['id']
              : int.tryParse(args['id'].toString()) ?? 0;
          _fetchDetail(id);
        }
      }
    });
  }

  Future<void> _fetchDetail(int id) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final token = await AuthService.getToken();
      final detail =
          await CertificateRepository.getCertificateDetail(id, token: token);
      if (mounted) {
        setState(() {
          _certificate = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleDownloadPdf() async {
    final cert = _certificate;
    if (cert == null || _isDownloading) return;

    if (!cert.isDownloadable) {
      _showWarningSnackBar(
          'Sertifikat belum dapat diunduh. Kampanye harus selesai terlebih dahulu.');
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final token = await AuthService.getToken();
      final downloadUrl =
          await CertificateRepository.getDownloadUrl(cert.id, token: token);
      final opened = await launchUrl(Uri.parse(downloadUrl),
          mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
      if (!opened) throw Exception('Tidak dapat membuka unduhan sertifikat.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Membuka unduhan file sertifikat PDF...')),
              ],
            ),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal mengunduh sertifikat: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _showVerificationDialog(VolunteerCertificate cert) async {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);
    final Map<String, dynamic> result;
    try {
      result =
          await CertificateRepository.verifyCertificate(cert.certificateNumber);
    } catch (_) {
      if (mounted) {
        _showErrorSnackBar(
            'Gagal memverifikasi sertifikat. Silakan coba lagi.');
      }
      return;
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
    if (!mounted) return;
    final valid = result['is_valid'] == true;
    final data = result['data'] is Map ? result['data'] as Map : const {};
    final status = data['status']?.toString() ?? '';
    final title = valid
        ? 'Sertifikat Valid'
        : status == 'revoked'
            ? 'Sertifikat Dicabut'
            : 'Sertifikat Belum Valid';
    await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(title),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No. Sertifikat: ${cert.certificateNumber}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(result['message']?.toString() ??
                        'Data sertifikat tidak tersedia.'),
                    if (data.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                          'Relawan: ${data['volunteer_name'] ?? cert.volunteerName}'),
                      Text(
                          'Kegiatan: ${data['campaign_name'] ?? cert.campaignName}'),
                      Text('Status: ${data['status_label'] ?? status}'),
                    ],
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tutup'))
              ],
            ));
  }

  Future<void> _shareCertificate(
      VolunteerCertificate cert, String platform) async {
    final verificationUrl = cert.normalizedVerifyUrl;
    if (verificationUrl.isEmpty) {
      _showErrorSnackBar('Tautan verifikasi belum tersedia.');
      return;
    }
    final text = 'Sertifikat kegiatan relawan "${cert.campaignName}" di DonGiv';
    final uri = platform == 'whatsapp'
        ? Uri.https(
            'api.whatsapp.com', '/send', {'text': '$text $verificationUrl'})
        : Uri.https('www.linkedin.com', '/shareArticle',
            {'mini': 'true', 'url': verificationUrl, 'title': text});
    try {
      if (!await launchUrl(uri,
          mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank')) {
        throw Exception('Aplikasi tujuan tidak tersedia.');
      }
    } catch (_) {
      if (mounted) {
        _showErrorSnackBar('Tidak dapat membuka tautan berbagi sertifikat.');
      }
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
    final cert = _certificate;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Detail Sertifikat',
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
          if (cert != null)
            IconButton(
              icon: const Icon(Icons.verified_outlined, color: kPrimaryColor),
              tooltip: 'Status Verifikasi',
              onPressed:
                  _isVerifying ? null : () => _showVerificationDialog(cert),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _errorMessage.isNotEmpty
              ? _buildErrorState()
              : cert == null
                  ? const Center(
                      child: Text('Data sertifikat tidak ditemukan.'))
                  : _buildDetailContent(cert),
    );
  }

  Widget _buildDetailContent(VolunteerCertificate cert) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Status Banner
          _buildStatusBanner(cert),
          const SizedBox(height: 20),

          // 2. Digital Certificate Card
          _buildVisualCertificateCard(cert),
          const SizedBox(height: 24),

          // 3. Action Buttons Panel
          _buildActionPanel(cert),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(VolunteerCertificate cert) {
    Color bannerBg;
    Color borderColor;
    Color textColor;
    IconData icon;
    String statusTitle;
    String description;

    if (cert.isActive) {
      bannerBg = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFBBF7D0);
      textColor = const Color(0xFF15803D);
      icon = Icons.verified_rounded;
      statusTitle = 'Sertifikat Valid';
      description =
          'Sertifikat ini aktif dan sah. Dapat diunduh sebagai berkas PDF resmi serta diverifikasi keasliannya secara publik.';
    } else if (cert.isPending) {
      bannerBg = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      textColor = const Color(0xFFB45309);
      icon = Icons.access_time_filled_rounded;
      statusTitle = 'Menunggu Kampanye Selesai';
      description =
          'Sertifikat ini berstatus ${cert.statusLabel} dan dapat diunduh dalam format PDF setelah kampanye selesai dilaksanakan pada ${cert.endDate ?? "jadwal yang ditentukan"}.';
    } else {
      bannerBg = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
      textColor = const Color(0xFFB91C1C);
      icon = Icons.cancel_rounded;
      statusTitle = 'Sertifikat Dicabut';
      description =
          'Sertifikat ini telah dicabut dan tidak lagi berlaku sebagai portofolio resmi.';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Status: ${cert.statusLabel}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualCertificateCard(VolunteerCertificate cert) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Watermark "DGV"
          Positioned(
            right: -20,
            bottom: 40,
            child: Opacity(
              opacity: 0.03,
              child: Text(
                'DGV',
                style: TextStyle(
                  fontSize: 180,
                  fontWeight: FontWeight.w900,
                  color: Colors.blue[900],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Ornamen Border Luar Sertifikat
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: kGoldColor.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      // Header Logo DonGiv
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.volunteer_activism_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'DonGiv',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E293B),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Bintang Emas Dekorasi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                              width: 32,
                              height: 1,
                              color: kGoldColor.withValues(alpha: 0.6)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0),
                            child:
                                Icon(Icons.star, color: kGoldColor, size: 14),
                          ),
                          Container(
                              width: 32,
                              height: 1,
                              color: kGoldColor.withValues(alpha: 0.6)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Judul Sertifikat
                      const Text(
                        'SERTIFIKAT PENGHARGAAN',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'CERTIFICATE OF APPRECIATION',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: kGoldColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'Dengan bangga dipersembahkan kepada:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: kTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Nama Relawan
                      Text(
                        cert.volunteerName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 70,
                        height: 2,
                        decoration: BoxDecoration(
                          color: const Color(0xFFBFDBFE),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Kalimat Apresiasi
                      const Text(
                        'Atas dedikasi, partisipasi aktif, dan kontribusi nyata sebagai relawan sosial dalam kegiatan:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '"${cert.campaignName}"',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Grid Rincian Informasi
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: _buildCertDetailItem(
                                        'Kategori', cert.category)),
                                Expanded(
                                    child: _buildCertDetailItem(
                                        'Lokasi', cert.location)),
                              ],
                            ),
                            const Divider(height: 16, color: Color(0xFFE2E8F0)),
                            Row(
                              children: [
                                Expanded(
                                    child: _buildCertDetailItem(
                                        'Tingkat Relawan',
                                        cert.volunteerLevel)),
                                Expanded(
                                    child: _buildCertDetailItem('Jam Relawan',
                                        '${cert.totalVolunteerHours} Jam')),
                              ],
                            ),
                            if (cert.startDate != null ||
                                cert.endDate != null) ...[
                              const Divider(
                                  height: 16, color: Color(0xFFE2E8F0)),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildCertDetailItem(
                                      'Periode Kegiatan',
                                      '${cert.startDate ?? "-"} s/d ${cert.endDate ?? "-"}',
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildCertDetailItem(
                                        'Penyelenggara', cert.organizerName),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Footer Sertifikat (QR Code, Nomor, Tim Verifikasi)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Kiri: Nomor Sertifikat & Tanggal Rilis
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'NO. SERTIFIKAT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: kTextSecondary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    cert.certificateNumber,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Diterbitkan: ${cert.issueDate ?? "-"}',
                                  style: const TextStyle(
                                      fontSize: 10, color: kTextSecondary),
                                ),
                              ],
                            ),
                          ),

                          // Tengah: QR Code
                          if (cert.qrCode != null && cert.qrCode!.isNotEmpty)
                            Expanded(
                              flex: 2,
                              child: Column(
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0xFFCBD5E1)),
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: cert.normalizedQrCode,
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) =>
                                          const Center(
                                        child: SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(
                                        Icons.qr_code,
                                        size: 32,
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Pindai Verifikasi',
                                    style: TextStyle(
                                        fontSize: 8,
                                        color: kTextSecondary,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),

                          // Kanan: Tanda Tangan Tim Verifikasi
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                    width: 80,
                                    height: 1,
                                    color: const Color(0xFF94A3B8)),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tim Verifikasi',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const Text(
                                  'DonGiv Platform',
                                  style: TextStyle(
                                      fontSize: 9, color: kTextSecondary),
                                ),
                              ],
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
        ],
      ),
    );
  }

  Widget _buildCertDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionPanel(VolunteerCertificate cert) {
    final bool isDownloadable = cert.isDownloadable;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.download_for_offline_rounded,
                  color: kPrimaryColor, size: 20),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                'Unduh & Portofolio Sertifikat',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: kTextPrimary,
                ),
              )),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isDownloadable
                ? 'Berkas PDF resmi dapat disimpan dan digunakan sebagai bukti portofolio kegiatan relawan Anda.'
                : 'Tombol unduh akan aktif setelah seluruh rangkaian kegiatan relawan selesai dilaksanakan.',
            style: const TextStyle(
                fontSize: 12, color: kTextSecondary, height: 1.4),
          ),
          const SizedBox(height: 18),

          // Tombol Unduh PDF
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: (isDownloadable && !_isDownloading)
                  ? _handleDownloadPdf
                  : null,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: Text(
                _isDownloading
                    ? 'Mengunduh Sertifikat...'
                    : (isDownloadable
                        ? 'Unduh PDF Resmi'
                        : 'Unduhan Belum Tersedia'),
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Status Verifikasi
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed:
                  _isVerifying ? null : () => _showVerificationDialog(cert),
              icon: const Icon(Icons.verified_outlined, size: 18),
              label: const Text(
                'Lihat Status Verifikasi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimaryColor,
                side: const BorderSide(color: kPrimaryColor),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Wrap(spacing: 10, runSpacing: 8, children: [
            OutlinedButton.icon(
                onPressed: () => _shareCertificate(cert, 'whatsapp'),
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('WhatsApp')),
            OutlinedButton.icon(
                onPressed: () => _shareCertificate(cert, 'linkedin'),
                icon: const Icon(Icons.work_outline, size: 18),
                label: const Text('LinkedIn')),
          ]),
          const SizedBox(height: 12),
          // Tombol "Ke Beranda" (Arahkan pengguna ke Home utama aplikasi Flutter DonGiv)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                // Arahkan pengguna ke halaman Home utama aplikasi Flutter DonGiv tanpa menumpuk halaman
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false);
              },
              icon: const Icon(Icons.home_rounded, size: 20),
              label: const Text(
                'Ke Beranda',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A), // Dark slate premium
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Tombol "Kembali ke Daftar Sertifikat"
          SizedBox(
            width: double.infinity,
            height: 46,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text(
                'Kembali ke Daftar Sertifikat',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: kTextSecondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
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
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Gagal Memuat Detail Sertifikat',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: kTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}
