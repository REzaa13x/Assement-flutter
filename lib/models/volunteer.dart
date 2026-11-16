class VolunteerCampaign {
  final int? id;
  final String title;
  final String description;
  final String? imageUrl;
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final int maxVolunteers;
  final int registeredVolunteers;
  final String requirements;
  final String benefits;
  final int progress;

  VolunteerCampaign({
    this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.maxVolunteers,
    required this.registeredVolunteers,
    required this.requirements,
    required this.benefits,
    required this.progress,
  });

  factory VolunteerCampaign.fromJson(Map<String, dynamic> json) {
    return VolunteerCampaign(
      id: json['id'],
      title: json['title'] ?? json['judul'] ?? '',
      description: json['description'] ?? json['deskripsi'] ?? '',
      imageUrl: json['image'] ?? json['gambar'] ?? json['image_path'] ?? json['photo'] ?? json['foto'] ?? '',
      location: json['location'] ?? json['lokasi'] ?? '',
      startDate: _parseDateTime(json['start_date']) ?? _parseDateTime(json['tanggal_mulai']) ?? DateTime.now(),
      endDate: _parseDateTime(json['end_date']) ?? _parseDateTime(json['tanggal_selesai']) ?? DateTime.now(),
      maxVolunteers: json['kuota_total'] ?? json['kuota'] ?? 0,
      registeredVolunteers: json['kuota_terisi'] ?? 0,
      requirements: json['requirements'] ?? json['persyaratan'] ?? '',
      benefits: json['benefits'] ?? json['manfaat'] ?? '',
      progress: json['progress'] ?? 0,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image': imageUrl,
      'location': location,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'kuota_total': maxVolunteers,
      'kuota_terisi': registeredVolunteers,
      'requirements': requirements,
      'benefits': benefits,
      'progress': progress,
    };
  }
}

class VolunteerApplication {
  final int? id;
  final int? userId;
  final int? volunteerCampaignId;
  final String motivation;
  final String skills;
  final String status;
  final DateTime createdAt;
  final VolunteerCampaign? campaign;

  VolunteerApplication({
    this.id,
    this.userId,
    this.volunteerCampaignId,
    required this.motivation,
    required this.skills,
    required this.status,
    required this.createdAt,
    this.campaign,
  });

  factory VolunteerApplication.fromJson(Map<String, dynamic> json) {
    return VolunteerApplication(
      id: json['id'],
      userId: json['user_id'],
      volunteerCampaignId: json['volunteer_campaign_id'],
      motivation: json['motivation'] ?? json['alasan'] ?? '',
      skills: json['skills'] ?? json['keahlian'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: _parseDateTime(json['created_at']) ?? _parseDateTime(json['tanggal_dibuat']) ?? DateTime.now(),
      campaign: json['campaign'] != null ? VolunteerCampaign.fromJson(json['campaign']) : null,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'volunteer_campaign_id': volunteerCampaignId,
      'motivation': motivation,
      'skills': skills,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'campaign': campaign?.toJson(),
    };
  }
}

class VolunteerCampaignResponse {
  final List<VolunteerCampaign> data;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  VolunteerCampaignResponse({
    required this.data,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory VolunteerCampaignResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List;
    final campaigns = dataList.map((item) => VolunteerCampaign.fromJson(item)).toList();

    return VolunteerCampaignResponse(
      data: campaigns,
      currentPage: json['current_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
      total: json['total'] ?? 0,
      lastPage: json['last_page'] ?? 1,
    );
  }
}

class VolunteerApplicationResponse {
  final List<VolunteerApplication> data;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  VolunteerApplicationResponse({
    required this.data,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory VolunteerApplicationResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List;
    final applications = dataList.map((item) => VolunteerApplication.fromJson(item)).toList();

    return VolunteerApplicationResponse(
      data: applications,
      currentPage: json['current_page'] ?? 1,
      perPage: json['per_page'] ?? 10,
      total: json['total'] ?? 0,
      lastPage: json['last_page'] ?? 1,
    );
  }
}