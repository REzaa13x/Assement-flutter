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
}