class ChatbotRecommendation {
  final int id;
  final String type; // 'donation' atau 'volunteer'
  final String title;
  final String category;
  final String? imageUrl;
  final String? location;
  final double progress;

  // Spesifik Donasi
  final double? targetAmount;
  final double? currentAmount;
  final String? yayasan;

  // Spesifik Relawan
  final int? maxVolunteers;
  final int? registeredVolunteers;
  final String? startDate;
  final String? endDate;

  ChatbotRecommendation({
    required this.id,
    required this.type,
    required this.title,
    required this.category,
    this.imageUrl,
    this.location,
    required this.progress,
    this.targetAmount,
    this.currentAmount,
    this.yayasan,
    this.maxVolunteers,
    this.registeredVolunteers,
    this.startDate,
    this.endDate,
  });

  bool get isDonation => type.toLowerCase() == 'donation';
  bool get isVolunteer => type.toLowerCase() == 'volunteer';

  factory ChatbotRecommendation.fromJson(Map<String, dynamic> json) {
    return ChatbotRecommendation(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      type: json['type']?.toString() ?? 'donation',
      title: json['title']?.toString() ?? 'Program DonGiv',
      category: json['category']?.toString() ?? 'Umum',
      imageUrl: json['image_url']?.toString(),
      location: json['location']?.toString(),
      progress: (json['progress'] != null)
          ? double.tryParse(json['progress'].toString()) ?? 0.0
          : 0.0,
      targetAmount: json['target_amount'] != null
          ? double.tryParse(json['target_amount'].toString())
          : null,
      currentAmount: json['current_amount'] != null
          ? double.tryParse(json['current_amount'].toString())
          : null,
      yayasan: json['yayasan']?.toString(),
      maxVolunteers: json['max_volunteers'] != null
          ? int.tryParse(json['max_volunteers'].toString())
          : null,
      registeredVolunteers: json['registered_volunteers'] != null
          ? int.tryParse(json['registered_volunteers'].toString())
          : null,
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
    );
  }
}

class ChatbotMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool usedAi;
  final List<ChatbotRecommendation> recommendations;

  ChatbotMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.usedAi = false,
    this.recommendations = const [],
  });
}
