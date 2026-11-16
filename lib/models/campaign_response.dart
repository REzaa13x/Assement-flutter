import 'campaign.dart';

class CampaignResponse {
  final List<Campaign> data;
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  CampaignResponse({
    required this.data,
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
  });

  factory CampaignResponse.fromJson(Map<String, dynamic> json) {
    final dataList = (json['data'] as List?) ?? [];
    final campaigns = dataList.map((item) => Campaign.fromJson(item as Map<String, dynamic>)).toList();
    final meta = json['meta'] as Map<String, dynamic>?;

    return CampaignResponse(
      data: campaigns,
      currentPage: json['current_page'] ?? meta?['current_page'] ?? 1,
      perPage: json['per_page'] ?? meta?['per_page'] ?? 10,
      total: json['total'] ?? meta?['total'] ?? campaigns.length,
      lastPage: json['last_page'] ?? meta?['last_page'] ?? 1,
    );
  }
}