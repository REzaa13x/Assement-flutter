import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../models/donation_campaign.dart';
import '../repositories/campaign_repository.dart';

class CampaignList extends StatefulWidget {
  const CampaignList({Key? key}) : super(key: key);

  @override
  State<CampaignList> createState() => _CampaignListState();
}

class _CampaignListState extends State<CampaignList> {
  List<Campaign> campaigns = [];
  bool isLoading = true;
  int currentPage = 1;
  bool hasMore = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    if (!hasMore) return;

    try {
      setState(() {
        isLoading = true;
      });

      final response = await CampaignRepository.getCampaigns(page: currentPage, status: 'verified');
      
      setState(() {
        campaigns.addAll(response.data);
        currentPage = response.currentPage + 1;
        hasMore = response.currentPage < response.lastPage;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat program donasi. Periksa koneksi Anda.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $errorMessage'),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  errorMessage = null;
                });
                _loadCampaigns();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (campaigns.isEmpty && isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          campaigns.clear();
          currentPage = 1;
          hasMore = true;
        });
        await _loadCampaigns();
      },
      child: ListView.builder(
        itemCount: campaigns.length + (isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == campaigns.length) {
            // Loading indicator at the end
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final campaign = campaigns[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              onTap: () {
                final donationCampaign = DonationCampaign(
                  id: campaign.id ?? 0,
                  title: campaign.title ?? '',
                  description: campaign.description ?? '',
                  imageUrl: campaign.image ?? 'https://via.placeholder.com/150',
                  targetAmount: campaign.targetAmount ?? 0.0,
                  currentAmount: campaign.currentAmount ?? 0.0,
                  category: campaign.kategori ?? campaign.category ?? 'Umum',
                );
                Navigator.pushNamed(
                  context,
                  '/campaign_detail',
                  arguments: donationCampaign,
                );
              },
              contentPadding: const EdgeInsets.all(16.0),
              leading: campaign.image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        campaign.image!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image_not_supported),
                          );
                        },
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.campaign),
                    ),
              title: Text(
                campaign.title ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(campaign.description != null && campaign.description!.length > 100
                      ? '${campaign.description!.substring(0, 100)}...'
                      : campaign.description ?? ''),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.category, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        campaign.kategori ?? campaign.category ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Ends: ${campaign.endDate ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: campaign.targetAmount != null && campaign.targetAmount! > 0
                        ? (campaign.currentAmount ?? 0) / campaign.targetAmount!
                        : 0,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${(campaign.currentAmount ?? 0).toStringAsFixed(0)} / Rp ${(campaign.targetAmount ?? 0).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}