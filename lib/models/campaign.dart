class Campaign {
  final int? id;
  final String? title;
  final String? description;
  final String? image;
  final double? targetAmount;
  final double? currentAmount;
  final String? endDate;
  final String? status;
  final String? category;
  final String? foundation;
  final int? userId;
  final String? slug;
  final String? kategori;  // Alias untuk category
  final String? yayasan;   // Alias untuk foundation
  final Map<String, dynamic>? user; // Informasi user jika ada

  Campaign({
    this.id,
    this.title,
    this.description,
    this.image,
    this.targetAmount,
    this.currentAmount,
    this.endDate,
    this.status,
    this.category,
    this.foundation,
    this.userId,
    this.slug,
    this.kategori,  // Tambahkan alias
    this.yayasan,   // Tambahkan alias
    this.user,
  });

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: json['id'],
      title: json['title'] ?? json['judul'] ?? '',
      description: json['description'] ?? json['deskripsi'] ?? '',
      image: json['image'] ?? json['gambar'],
      targetAmount: (json['target_amount'] is int)
          ? (json['target_amount'] as int).toDouble()
          : (json['target_amount'] is double)
              ? json['target_amount'] as double
              : double.tryParse(json['target_amount'].toString() ?? '0'),
      currentAmount: (json['current_amount'] is int)
          ? (json['current_amount'] as int).toDouble()
          : (json['current_amount'] is double)
              ? json['current_amount'] as double
              : double.tryParse(json['current_amount'].toString() ?? '0'),
      endDate: json['end_date'] ?? json['tanggal_berakhir'],
      status: json['status'],
      category: json['category'] ?? json['kategori'],
      foundation: json['foundation'] ?? json['yayasan'],
      userId: json['user_id'] ?? json['userId'],
      slug: json['slug'],
      kategori: json['kategori'] ?? json['category'],  // Alias
      yayasan: json['yayasan'] ?? json['foundation'],  // Alias
      user: json['user'] != null ? Map<String, dynamic>.from(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image': image,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'end_date': endDate,
      'status': status,
      'kategori': category,
      'yayasan': foundation,
    };
  }
}