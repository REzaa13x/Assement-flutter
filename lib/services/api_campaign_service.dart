// This file demonstrates how to integrate the API with your existing donation app
// You can use this approach to replace or enhance your existing campaign functionality

import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../repositories/campaign_repository.dart';

class ApiCampaignService {
  // This service can be used to integrate API data with your existing app
  
  // Example: Fetch campaigns and convert them to your existing model format
  static Future<List<dynamic>> getApiCampaignsForDisplay() async {
    try {
      final response = await CampaignRepository.getCampaigns();
      return response.data.map((campaign) => _convertToDisplayFormat(campaign)).toList();
    } catch (e) {
      throw Exception('Failed to load campaigns from API: $e');
    }
  }

  // Convert API campaign model to a format compatible with your existing app
  static Map<String, dynamic> _convertToDisplayFormat(Campaign campaign) {
    return {
      'id': campaign.id,
      'title': campaign.title ?? '',
      'description': campaign.description ?? '',
      'targetAmount': campaign.targetAmount ?? 0,
      'currentAmount': campaign.currentAmount ?? 0,
      'image': campaign.image,
      'endDate': campaign.endDate,
      'userId': campaign.userId,
      'status': campaign.status,
      'kategori': campaign.kategori ?? campaign.category,
      'yayasan': campaign.yayasan ?? campaign.foundation,
      // Calculate percentage for progress display
      'progressPercentage':
          (campaign.targetAmount != null && campaign.targetAmount! > 0)
              ? ((campaign.currentAmount ?? 0) / campaign.targetAmount! * 100).round()
              : 0,
    };
  }

  // Example: Get a single campaign and convert it
  static Future<Map<String, dynamic>?> getCampaignForDisplay(String id) async {
    try {
      final campaign = await CampaignRepository.getCampaign(id);
      return _convertToDisplayFormat(campaign);
    } catch (e) {
      print('Error fetching campaign: $e');
      return null;
    }
  }
  
  // Example: Create a campaign using the API
  static Future<bool> createCampaign({
    required String title,
    required String description,
    required double targetAmount,
    required String endDate,
    required String kategori,
    String? yayasan,
    String? image,
    String? token, // Token autentikasi
  }) async {
    try {
      await CampaignRepository.createCampaign(
        title: title,
        description: description,
        targetAmount: targetAmount,
        endDate: endDate,
        kategori: kategori,
        yayasan: yayasan,
        image: image,
        token: token,
      );
      return true;
    } catch (e) {
      print('Error creating campaign: $e');
      return false;
    }
  }
}

// Example widget that could be integrated into your existing app
class ApiCampaignListWidget extends StatelessWidget {
  const ApiCampaignListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ApiCampaignService.getApiCampaignsForDisplay(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ApiCampaignListWidget()),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No campaigns found'),
          );
        }

        final campaigns = snapshot.data!;
        
        return ListView.builder(
          itemCount: campaigns.length,
          itemBuilder: (context, index) {
            final campaign = campaigns[index];
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(campaign['title']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(campaign['description'].length > 100
                        ? '${campaign['description'].substring(0, 100)}...'
                        : campaign['description']),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: campaign['progressPercentage'] / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${campaign['currentAmount'].toStringAsFixed(0)} / Rp ${campaign['targetAmount'].toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}