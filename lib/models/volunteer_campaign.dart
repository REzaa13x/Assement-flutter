class VolunteerCampaign {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final int maxVolunteers;
  final int registeredVolunteers;
  final String requirements;
  final String benefits;
  final String category;
  final String status;

  VolunteerCampaign({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.maxVolunteers,
    required this.registeredVolunteers,
    required this.requirements,
    required this.benefits,
    this.category = 'Umum',
    this.status = 'Aktif',
  });

  int get availableSpots => (maxVolunteers - registeredVolunteers).clamp(0, maxVolunteers);

  double get progress => maxVolunteers > 0
      ? (registeredVolunteers / maxVolunteers).clamp(0.0, 1.0)
      : 0.0;

  bool get isFull => maxVolunteers > 0 && registeredVolunteers >= maxVolunteers;

  // Parsing aman dari backend (Laravel VolunteerCampaignResource / format Flutter lama)
  factory VolunteerCampaign.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return VolunteerCampaign(
      id: parseInt(json['id']),
      title: (json['title'] ?? json['judul'] ?? json['name'] ?? 'Peluang Relawan').toString(),
      description: (json['description'] ?? json['deskripsi'] ?? '').toString(),
      imageUrl: (json['image_url'] ?? json['image'] ?? json['gambar'] ?? json['image_path'] ?? json['photo'] ?? json['foto'] ?? '').toString(),
      location: (json['location'] ?? json['lokasi'] ?? 'Indonesia').toString(),
      startDate: parseDate(json['start_date'] ?? json['tanggal_mulai']),
      endDate: parseDate(json['end_date'] ?? json['tanggal_selesai']),
      maxVolunteers: parseInt(json['max_volunteers'] ?? json['kuota_total'] ?? json['kuota']),
      registeredVolunteers: parseInt(json['registered_volunteers'] ?? json['kuota_terisi']),
      requirements: (json['requirements'] ?? json['persyaratan'] ?? 'Terbuka untuk umum, sehat jasmani dan rohani.').toString(),
      benefits: (json['benefits'] ?? json['manfaat'] ?? 'Sertifikat keikutsertaan, relasi dan pengalaman berharga.').toString(),
      category: (json['kategori'] ?? json['category'] ?? 'Umum').toString(),
      status: (json['status'] ?? 'Aktif').toString(),
    );
  }
}