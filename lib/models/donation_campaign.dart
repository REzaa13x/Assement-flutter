class DonationCampaign {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final double targetAmount;
  final double currentAmount;
  final String category; 

  DonationCampaign({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.targetAmount,
    required this.currentAmount,
    required this.category,
  });

  // Getter untuk menghitung progress bar (0.0 sampai 1.0)
  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  // BUAT API
  factory DonationCampaign.fromJson(Map<String, dynamic> json) {
    return DonationCampaign(
      id: json['id'] ?? 0,
      title: json['title'] ?? 'Tanpa Judul',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? 'https://via.placeholder.com/150',
      // Parsing aman: ubah ke String dulu baru ke double biar gak crash
      targetAmount: double.parse((json['target_amount'] ?? 0).toString()),
      currentAmount: double.parse((json['current_amount'] ?? 0).toString()),
      category: json['category'] ?? 'Umum',
    );
  }
}