import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../repositories/volunteer_repository.dart';
import '../models/volunteer_campaign.dart';
import '../config/app_config.dart';
import '../services/volunteer_cv_service.dart';
import 'login_page.dart';

const Color kPrimaryColor = Color(0xFF2972FF);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const Color kTextPrimary = Color(0xFF1E293B);
const Color kTextSecondary = Color(0xFF64748B);

class VolunteerRegistrationFormPage extends StatefulWidget {
  const VolunteerRegistrationFormPage({Key? key, this.pickCvFile})
      : super(key: key);
  final Future<PlatformFile?> Function()? pickCvFile;

  @override
  State<VolunteerRegistrationFormPage> createState() =>
      _VolunteerRegistrationFormPageState();
}

class _VolunteerRegistrationFormPageState
    extends State<VolunteerRegistrationFormPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _motivationController = TextEditingController();

  String? _selectedPosition;
  PlatformFile? _selectedCvFile;
  int? _selectedCvFileSize;
  Uint8List? _selectedCvBytes;
  bool _isPickingCv = false;

  int? _volunteerCampaignId;
  String _campaignTitle = 'Kampanye Relawan';
  String _campaignImageUrl = '';

  String _userName = '';
  String _userEmail = '';
  bool _isLoadingUser = true;
  bool _isSubmitting = false;
  bool _submitted = false;

  // Pilihan posisi yang dilamar sesuai persis dengan website DonGiv
  final List<Map<String, String>> _positionOptions = const [
    {'label': 'Tim Lapangan (Fisik)', 'value': 'Lapangan'},
    {'label': 'Tim Medis / P3K', 'value': 'Medis'},
    {'label': 'Logistik & Dapur Umum', 'value': 'Logistik'},
    {'label': 'Dokumentasi & Media', 'value': 'Dokumentasi'},
    {'label': 'Pengajar / Edukator', 'value': 'Pendidikan'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is VolunteerCampaign) {
        setState(() {
          _volunteerCampaignId = args.id;
          _campaignTitle = args.title;
          _campaignImageUrl = args.imageUrl;
        });
      } else if (args is Map) {
        setState(() {
          final rawId = args['volunteer_campaign_id'];
          _volunteerCampaignId =
              rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
          _campaignTitle =
              (args['volunteer_campaign_title'] ?? 'Kampanye Relawan')
                  .toString();
          _campaignImageUrl =
              (args['volunteer_campaign_image'] ?? '').toString();

          if (args['campaign'] is VolunteerCampaign) {
            final VolunteerCampaign c = args['campaign'];
            _volunteerCampaignId = c.id;
            _campaignTitle = c.title;
            _campaignImageUrl = c.imageUrl;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _motivationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final userData = await AuthService.getUserData();
      if (!mounted) return;
      if (userData != null) {
        setState(() {
          _userName = userData['name']?.toString() ?? '';
          _userEmail = userData['email']?.toString() ?? '';
          _isLoadingUser = false;
        });
        return;
      }

      final profile = await ProfileService.getUserProfile();
      if (!mounted) return;
      if (profile != null) {
        setState(() {
          _userName = profile.name;
          _userEmail = profile.email;
          _isLoadingUser = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }

    if (mounted) {
      setState(() {
        _userName = 'Pengguna DonGiv';
        _userEmail = 'user@dongiv.org';
        _isLoadingUser = false;
      });
    }
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

  Future<void> _pickCvFile() async {
    if (_isSubmitting || _submitted || _isPickingCv) return;
    setState(() => _isPickingCv = true);
    try {
      final PlatformFile? file;
      if (widget.pickCvFile != null) {
        file = await widget.pickCvFile!();
      } else {
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          withData: true,
          withReadStream: true,
        );

        file =
            result == null || result.files.isEmpty ? null : result.files.first;
      }
      if (!mounted || file == null) return;
      final bytes = await VolunteerCvService.readPdf(file);
      if (!mounted) return;
      setState(() {
        _selectedCvFile = file;
        _selectedCvBytes = bytes;
        _selectedCvFileSize = bytes.length;
      });
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isPickingCv = false);
    }
  }

  void _removeCvFile() {
    if (_isSubmitting || _submitted || _isPickingCv) return;
    setState(() {
      _selectedCvFile = null;
      _selectedCvBytes = null;
      _selectedCvFileSize = null;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
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

  Future<void> _submitForm() async {
    if (_isSubmitting || _submitted || _isPickingCv) return;
    FocusScope.of(context).unfocus();
    // 1. Validasi form dasar (alamat & motivasi)
    final formValid = _formKey.currentState?.validate() ?? false;

    // 2. Validasi posisi
    if (_selectedPosition == null || _selectedPosition!.isEmpty) {
      _showErrorSnackBar('Silakan pilih posisi yang dilamar.');
      return;
    }

    if (!formValid) {
      return;
    }

    // 3. Validasi CV
    if (_selectedCvFile == null) {
      _showErrorSnackBar('Silakan upload file CV / Resume (PDF maks 2 MB).');
      return;
    }

    // Pastikan ID kampanye valid
    if (_volunteerCampaignId == null) {
      _showErrorSnackBar('ID kampanye relawan tidak ditemukan.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      var token = await AuthService.getToken();
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        final loggedIn = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
              builder: (_) => const LoginPage(returnToPreviousPage: true)),
        );
        if (!mounted || loggedIn != true) return;
        await _loadUserData();
        token = await AuthService.getToken();
        if (!mounted || token == null || token.isEmpty) return;
      }
      final cvBytes = _selectedCvBytes;

      if (cvBytes == null) {
        _showErrorSnackBar('Gagal membaca isi file PDF.');
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final multipartFile = http.MultipartFile.fromBytes(
        'cv',
        cvBytes,
        filename: _selectedCvFile!.name,
        contentType: MediaType('application', 'pdf'),
      );

      final response = await VolunteerRepository.applyToVolunteerCampaignRaw(
        volunteerCampaignId: _volunteerCampaignId!,
        posisiDilamar: _selectedPosition!,
        alamat: _addressController.text.trim(),
        alasanBergabung: _motivationController.text.trim(),
        cvFile: multipartFile,
        token: token,
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _submitted = true;
          _isSubmitting = false;
        });
        // Berhasil mendaftar
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                SizedBox(width: 10),
                Expanded(child: Text('Pendaftaran Berhasil!')),
              ],
            ),
            content: const Text(
              'Formulir pendaftaran relawan Anda telah berhasil dikirim! Tim kami akan segera melakukan verifikasi.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // Tutup dialog
                  Navigator.of(context)
                      .pop(true); // Kembali ke halaman sebelumnya
                },
                child: const Text(
                  'OK',
                  style: TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ],
          ),
        );
      } else if (response.statusCode == 401) {
        await AuthService.removeToken();
        if (!mounted) return;
        final loggedIn = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
              builder: (_) => const LoginPage(returnToPreviousPage: true)),
        );
        if (!mounted) return;
        if (loggedIn == true) {
          await _loadUserData();
          if (!mounted) return;
          _showErrorSnackBar(
              'Login berhasil. Silakan kirim kembali pendaftaran Anda.');
        }
      } else {
        // Tampilkan pesan kesalahan dari backend
        String errorMessage =
            'Gagal mengirim pendaftaran (Kode ${response.statusCode})';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map) {
            if (decoded['message'] != null) {
              errorMessage = decoded['message'].toString();
            }
            if (decoded['errors'] is Map) {
              final Map errors = decoded['errors'];
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                errorMessage = firstError.first.toString();
              }
            }
          }
        } catch (_) {}

        _showErrorSnackBar(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Terjadi kesalahan koneksi: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedImageUrl = _normalizeImageUrl(_campaignImageUrl);
    final motivationLength = _motivationController.text.trim().length;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Formulir Pendaftaran Relawan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. HEADER INFORMASI PROGRAM KAMPANYE (SESUAI WEBSITE DONGIV)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Gradasi Biru
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2972FF), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.volunteer_activism_rounded,
                                    color: Colors.white70, size: 18),
                                SizedBox(width: 8),
                                Expanded(
                                    child: Text(
                                  'Anda mendaftar untuk program:',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _campaignTitle,
                              style: const TextStyle(
                                color: Color(
                                    0xFFFDE047), // Aksen kuning khas DonGiv
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Gambar Kampanye
                      if (normalizedImageUrl.isNotEmpty)
                        Container(
                          width: double.infinity,
                          height: 160,
                          color: Colors.grey[200],
                          child: CachedNetworkImage(
                            imageUrl: normalizedImageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                  color: kPrimaryColor, strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey[100],
                              child: const Center(
                                child: Icon(Icons.image_not_supported_rounded,
                                    color: Colors.grey, size: 40),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. BAGIAN DATA AKUN (SESUAI DATA AUTENTIKASI PENGGUNA)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF), // Biru muda lembut
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDBEAFE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded,
                            color: kPrimaryColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'DATA AKUN',
                              style: TextStyle(
                                color: kPrimaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _isLoadingUser
                                ? const SizedBox(
                                    height: 16,
                                    width: 120,
                                    child: LinearProgressIndicator(
                                        color: kPrimaryColor),
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userName.isNotEmpty
                                            ? _userName
                                            : 'Nama Pengguna',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: kTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _userEmail.isNotEmpty
                                            ? _userEmail
                                            : 'email@example.com',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: kTextSecondary,
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

                const SizedBox(height: 24),

                // 3. FIELD FORMULIR YANG WAJIB TERSEDIA

                // A. Posisi yang Dilamar *
                _buildFieldLabel('Posisi yang Dilamar'),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedPosition == null
                          ? Colors.grey.shade300
                          : kPrimaryColor,
                      width: 1.2,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedPosition,
                      hint: const Text(
                        'Pilih posisi...',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF64748B)),
                      items: _positionOptions.map((opt) {
                        return DropdownMenuItem<String>(
                          value: opt['value'],
                          child: Text(
                            opt['label']!,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: kTextPrimary),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedPosition = val;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // B. Alamat Domisili Saat Ini *
                _buildFieldLabel('Alamat Domisili Saat Ini'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'Jalan, Kelurahan, Kota...',
                    hintStyle:
                        const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: kPrimaryColor, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Alamat domisili wajib diisi';
                    }
                    if (value.trim().length < 10) {
                      return 'Alamat domisili minimal 10 karakter';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // C. Mengapa Anda ingin bergabung? *
                _buildFieldLabel('Mengapa Anda ingin bergabung?'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _motivationController,
                  maxLines: 5,
                  onChanged: (text) => setState(() {}),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kTextPrimary),
                  decoration: InputDecoration(
                    hintText:
                        'Ceritakan motivasi dan pengalaman relevan Anda...',
                    hintStyle:
                        const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: kPrimaryColor, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Alasan bergabung wajib diisi';
                    }
                    if (value.trim().length < 20) {
                      return 'Jawaban belum mencapai minimal 20 karakter (${value.trim().length}/20)';
                    }
                    return null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    children: [
                      const Text(
                        'Minimal 20 karakter.',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                      Text(
                        '$motivationLength karakter',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: motivationLength >= 20
                              ? Colors.green[600]
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // D. Upload CV / Resume *
                _buildFieldLabel('Upload CV / Resume'),
                const SizedBox(height: 8),

                if (_selectedCvFile == null)
                  // Tampilan belum upload (Dashed border box)
                  InkWell(
                    onTap: _pickCvFile,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 28, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: kPrimaryColor.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.cloud_upload_outlined,
                              color: kPrimaryColor,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Klik untuk upload file PDF',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Maksimal ukuran file 2 MB',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // Tampilan file terpilih (Success state)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4), // Hijau muda lembut
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDCFCE7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: Color(0xFF16A34A),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'File Terpilih:',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedCvFile!.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: kTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_selectedCvFileSize != null)
                                Text(
                                  _formatFileSize(_selectedCvFileSize!),
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF64748B)),
                                ),
                            ],
                          ),
                        ),
                        // Tombol Ganti / Hapus
                        IconButton(
                          tooltip: 'Ganti File',
                          icon: const Icon(Icons.sync_rounded,
                              color: kPrimaryColor),
                          onPressed: _pickCvFile,
                        ),
                        IconButton(
                          tooltip: 'Hapus File',
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: Colors.redAccent),
                          onPressed: _removeCvFile,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 36),

                // 4. TOMBOL KIRIM PENDAFTARAN
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting || _submitted || _isPickingCv
                        ? null
                        : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      disabledBackgroundColor: kPrimaryColor.withValues(alpha: 0.6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Flexible(
                                  child: Text(
                                'Sedang Mengirim...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                  child: Text(
                                'Kirim Pendaftaran',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )),
                              SizedBox(width: 8),
                              Icon(Icons.send_rounded, size: 18),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: kTextPrimary,
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
