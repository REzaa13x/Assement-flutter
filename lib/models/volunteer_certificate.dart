import '../config/app_config.dart';

class CertificateMeta {
  final int total;
  final int totalActive;
  final int totalHours;
  final String volunteerLevel;

  CertificateMeta({
    required this.total,
    required this.totalActive,
    required this.totalHours,
    required this.volunteerLevel,
  });

  factory CertificateMeta.fromJson(Map<String, dynamic> json) {
    return CertificateMeta(
      total: json['total'] is int ? json['total'] : int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      totalActive: json['total_active'] is int
          ? json['total_active']
          : int.tryParse(json['total_active']?.toString() ?? '0') ?? 0,
      totalHours: json['total_hours'] is int
          ? json['total_hours']
          : int.tryParse(json['total_hours']?.toString() ?? '0') ?? 0,
      volunteerLevel: json['volunteer_level']?.toString() ?? 'Relawan Baru',
    );
  }
}

class VolunteerCertificate {
  final int id;
  final String certificateId;
  final String certificateNumber;
  final int volunteerId;
  final String volunteerName;
  final int? campaignId;
  final String campaignName;
  final String category;
  final String location;
  final String? startDate;
  final String? endDate;
  final String? issueDate;
  final String volunteerLevel;
  final int totalVolunteerHours;
  final String organizerName;
  final String status; // 'active', 'pending', 'revoked'
  final String statusLabel;
  final bool isDownloadable;
  final String? certificateFile;
  final String? qrCode;
  final String? verifyUrl;
  final String? downloadUrl;
  final String? createdAt;

  VolunteerCertificate({
    required this.id,
    required this.certificateId,
    required this.certificateNumber,
    required this.volunteerId,
    required this.volunteerName,
    this.campaignId,
    required this.campaignName,
    required this.category,
    required this.location,
    this.startDate,
    this.endDate,
    this.issueDate,
    required this.volunteerLevel,
    required this.totalVolunteerHours,
    required this.organizerName,
    required this.status,
    required this.statusLabel,
    required this.isDownloadable,
    this.certificateFile,
    this.qrCode,
    this.verifyUrl,
    this.downloadUrl,
    this.createdAt,
  });

  bool get isActive => status.toLowerCase() == 'active';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isRevoked => status.toLowerCase() == 'revoked';

  /// Normalisasi URL jika berjalan pada Android Emulator (127.0.0.1 -> 10.0.2.2)
  String normalizeUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (AppConfig.apiUrl.contains('10.0.2.2') && raw.contains('127.0.0.1')) {
      return raw.replaceAll('127.0.0.1', '10.0.2.2');
    }
    if (AppConfig.apiUrl.contains('10.0.2.2') && raw.contains('localhost')) {
      return raw.replaceAll('localhost', '10.0.2.2');
    }
    return raw;
  }

  String get normalizedQrCode => normalizeUrl(qrCode);
  String get normalizedVerifyUrl => normalizeUrl(verifyUrl);
  String get normalizedDownloadUrl => normalizeUrl(downloadUrl);

  factory VolunteerCertificate.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final int parsedId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    final rawVolId = json['volunteer_id'];
    final int parsedVolId = rawVolId is int ? rawVolId : int.tryParse(rawVolId?.toString() ?? '0') ?? 0;

    final rawCampId = json['campaign_id'];
    final int? parsedCampId = rawCampId is int ? rawCampId : int.tryParse(rawCampId?.toString() ?? '');

    final rawHours = json['total_volunteer_hours'];
    final int parsedHours = rawHours is int ? rawHours : int.tryParse(rawHours?.toString() ?? '8') ?? 8;

    final rawDownloadable = json['is_downloadable'];
    final bool parsedDownloadable = rawDownloadable is bool
        ? rawDownloadable
        : (rawDownloadable?.toString().toLowerCase() == 'true' || rawDownloadable == 1);

    final String statusStr = json['status']?.toString() ?? 'pending';
    final String fallbackStatusLabel = statusStr == 'active'
        ? 'Aktif'
        : (statusStr == 'pending' ? 'Menunggu Kampanye Selesai' : 'Dicabut');

    return VolunteerCertificate(
      id: parsedId,
      certificateId: json['certificate_id']?.toString() ?? '',
      certificateNumber: json['certificate_number']?.toString() ?? '',
      volunteerId: parsedVolId,
      volunteerName: json['volunteer_name']?.toString() ?? 'Relawan DonGiv',
      campaignId: parsedCampId,
      campaignName: json['campaign_name']?.toString() ?? 'Kegiatan Relawan',
      category: json['category']?.toString() ?? 'Relawan',
      location: json['location']?.toString() ?? '-',
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      issueDate: json['issue_date']?.toString(),
      volunteerLevel: json['volunteer_level']?.toString() ?? 'Relawan Baru',
      totalVolunteerHours: parsedHours,
      organizerName: json['organizer_name']?.toString() ?? 'Dongiv',
      status: statusStr,
      statusLabel: json['status_label']?.toString() ?? fallbackStatusLabel,
      isDownloadable: parsedDownloadable,
      certificateFile: json['certificate_file']?.toString(),
      qrCode: json['qr_code']?.toString(),
      verifyUrl: json['verify_url']?.toString(),
      downloadUrl: json['download_url']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
