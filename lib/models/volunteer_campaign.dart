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
  });

  int get availableSpots => maxVolunteers - registeredVolunteers;

  // --- TAMBAHKAN INI AGAR BISA BACA DATA DARI BACKEND/JSON ---
  factory VolunteerCampaign.fromJson(Map<String, dynamic> json) {
    return VolunteerCampaign(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      location: json['location'] ?? '',
      startDate: DateTime.parse(json['start_date'] ?? DateTime.now().toString()),
      endDate: DateTime.parse(json['end_date'] ?? DateTime.now().toString()),
      maxVolunteers: int.parse((json['max_volunteers'] ?? 0).toString()),
      registeredVolunteers: int.parse((json['registered_volunteers'] ?? 0).toString()),
      requirements: json['requirements'] ?? '',
      benefits: json['benefits'] ?? '',
    );
  }
}