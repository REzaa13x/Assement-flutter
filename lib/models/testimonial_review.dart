class TestimonialReview {
  final int id;
  final String name;
  final String role; // e.g., 'Donatur Terverifikasi', 'Relawan Terverifikasi'
  final String content;
  final String? avatarUrl;
  final double? rating;
  final bool isSample; // true jika preview / contoh pengembangan
  final String? campaignTitle;
  final String? activityType;
  final bool isVerified;
  final String? createdAtFormatted;

  const TestimonialReview({
    required this.id,
    required this.name,
    required this.role,
    required this.content,
    this.avatarUrl,
    this.rating,
    this.isSample = false,
    this.campaignTitle,
    this.activityType,
    this.isVerified = false,
    this.createdAtFormatted,
  });

  factory TestimonialReview.fromJson(Map<String, dynamic> json) {
    final String actType = json['activity_type']?.toString() ?? '';
    final String fallbackRole = actType == 'volunteer' ? 'Relawan DonGiv' : 'Donatur DonGiv';
    final String role = json['role']?.toString() ?? fallbackRole;

    return TestimonialReview(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['user_name']?.toString() ?? json['name']?.toString() ?? 'Sahabat DonGiv',
      role: role,
      content: json['comment']?.toString() ?? json['content']?.toString() ?? json['review']?.toString() ?? json['message']?.toString() ?? '',
      avatarUrl: json['user_avatar']?.toString() ?? json['avatar_url']?.toString() ?? json['avatar']?.toString() ?? json['photo']?.toString(),
      rating: json['rating'] != null ? (double.tryParse(json['rating'].toString())) : null,
      isSample: json['is_sample'] == true,
      campaignTitle: json['campaign_title']?.toString(),
      activityType: actType.isNotEmpty ? actType : null,
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      createdAtFormatted: json['created_at_formatted']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'content': content,
      'avatar_url': avatarUrl,
      'rating': rating,
      'is_sample': isSample,
      'campaign_title': campaignTitle,
      'activity_type': activityType,
      'is_verified': isVerified,
      'created_at_formatted': createdAtFormatted,
    };
  }

  /// Data preview yang ditandai secara jelas sebagai contoh pengembangan
  /// sesuai referensi kata #OrangBaik di website DonGiv jika database kosong.
  static List<TestimonialReview> get sampleReviews => const [
    TestimonialReview(
      id: 1,
      name: 'Rina Suryani',
      role: 'Donatur Rutin',
      content: 'Platformnya sangat transparan. Saya jadi tidak ragu untuk menyisihkan rezeki setiap bulan di DonGiv.',
      avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
      rating: 5.0,
      isSample: true,
      campaignTitle: 'Bantuan Pendidikan Anak Negeri',
      isVerified: true,
    ),
    TestimonialReview(
      id: 2,
      name: 'Dimas Anggara',
      role: 'Relawan & Donatur',
      content: 'Proses donasinya cepat dan praktis. Semoga DonGiv terus amanah dalam menyalurkan setiap amanah kebaikan.',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
      rating: 5.0,
      isSample: true,
      campaignTitle: 'Tanggap Darurat Banjir',
      isVerified: true,
    ),
  ];
}
