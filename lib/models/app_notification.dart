/// Model notifikasi DonGiv (riwayat notifikasi di aplikasi).
///
/// Datanya berasal dari endpoint `GET /api/v1/notifications`.
class AppNotification {
  final String id;
  final String type;
  final String category; // donasi | relawan | kampanye | sistem | general
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final String? status; // approved | rejected | pending dll jika ada

  const AppNotification({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.message,
    required this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.status,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final dataMap = rawData is Map<String, dynamic>
        ? rawData
        : (rawData is Map ? Map<String, dynamic>.from(rawData) : <String, dynamic>{});

    // Normalisasi kategori: donasi/donation -> 'donasi', relawan/volunteer -> 'relawan'
    String rawCategory = (json['category'] ?? dataMap['category'] ?? 'general').toString().toLowerCase();
    if (rawCategory == 'donation') rawCategory = 'donasi';
    if (rawCategory == 'volunteer') rawCategory = 'relawan';

    // Status lamaran atau donasi jika tersedia
    final statusVal = dataMap['status']?.toString().toLowerCase();

    // Bersihkan judul dan pesan dari emoji atau karakter rusak
    final cleanTitle = _cleanText(json['title']?.toString() ?? 'Notifikasi');
    final cleanMessage = _cleanText(json['message']?.toString() ?? '');

    return AppNotification(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      category: rawCategory,
      title: cleanTitle.isEmpty ? 'Notifikasi' : cleanTitle,
      message: cleanMessage,
      data: dataMap,
      isRead: json['is_read'] == true || json['read_at'] != null,
      readAt: _parseDate(json['read_at']),
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      status: statusVal,
    );
  }

  /// Order ID transaksi donasi terkait (null untuk non-donasi).
  String? get orderId {
    final value = data['order_id'];
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  /// ID kegiatan relawan terkait (null untuk non-relawan).
  int? get campaignId {
    final raw = data['campaign_id'];
    if (raw == null) return null;
    return int.tryParse('$raw');
  }

  /// Slug kegiatan relawan jika ada di data payload atau url
  String? get campaignSlug {
    if (data['campaign_slug'] != null) {
      return data['campaign_slug'].toString();
    }
    final url = data['url']?.toString();
    if (url != null && url.contains('/volunteer/status/')) {
      final parts = url.split('/volunteer/status/');
      if (parts.length > 1) return parts[1].trim();
    }
    return null;
  }

  /// Status khusus relawan / approval
  bool get isVolunteerApproved =>
      status == 'approved' ||
      title.toLowerCase().contains('diterima') ||
      message.toLowerCase().contains('telah diterima') ||
      message.toLowerCase().contains('anda diterima');

  bool get isVolunteerRejected =>
      status == 'rejected' ||
      title.toLowerCase().contains('ditolak') ||
      message.toLowerCase().contains('belum dapat diterima') ||
      message.toLowerCase().contains('belum dapat kami terima');

  bool get isDonationSuccess =>
      category == 'donasi' &&
      (title.toLowerCase().contains('berhasil') || message.toLowerCase().contains('berhasil'));

  static String _cleanText(String? input) {
    if (input == null || input.isEmpty) return '';
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{FE00}-\u{FE0F}\u{1F900}-\u{1F9FF}\u{1FA70}-\u{1FAFF}\u{FFFD}]',
      unicode: true,
    );
    String clean = input.replaceAll(emojiRegex, '');
    clean = clean.replaceAll(RegExp(r'\?+\s*(YZ|OS|T|S)?'), '');
    clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
    return clean;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null || value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
