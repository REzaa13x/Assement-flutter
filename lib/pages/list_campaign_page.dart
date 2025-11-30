import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/custom_widgets.dart';

class ListCampaignPage extends StatefulWidget {
  const ListCampaignPage({Key? key}) : super(key: key);

  @override
  State<ListCampaignPage> createState() => _ListCampaignPageState();
}

class _ListCampaignPageState extends State<ListCampaignPage> {
  List<Campaign> campaigns = [
    Campaign(
      id: 1,
      title: 'Clean Water for Rural Communities',
      description: 'Provide clean drinking water to villages in need',
      imageUrl: 'https://picsum.photos/seed/campaign1/600/400',
      targetAmount: 50000000,
      currentAmount: 32000000,
      category: 'Health',
    ),
    Campaign(
      id: 2,
      title: 'Education for Underprivileged Children',
      description: 'Fund education for children who cannot afford school',
      imageUrl: 'https://picsum.photos/seed/campaign2/600/400',
      targetAmount: 30000000,
      currentAmount: 18000000,
      category: 'Education',
    ),
    Campaign(
      id: 3,
      title: 'Emergency Relief for Flood Victims',
      description: 'Provide immediate aid to families affected by floods',
      imageUrl: 'https://picsum.photos/seed/campaign3/600/400',
      targetAmount: 100000000,
      currentAmount: 75000000,
      category: 'Emergency',
    ),
    Campaign(
      id: 4,
      title: 'Support Local Farmers',
      description: 'Provide seeds and tools to small-scale farmers',
      imageUrl: 'https://picsum.photos/seed/campaign4/600/400',
      targetAmount: 25000000,
      currentAmount: 12000000,
      category: 'Agriculture',
    ),
    Campaign(
      id: 5,
      title: 'Healthcare for Remote Villages',
      description: 'Provide medical supplies and healthcare to remote areas',
      imageUrl: 'https://picsum.photos/seed/campaign5/600/400',
      targetAmount: 40000000,
      currentAmount: 27000000,
      category: 'Health',
    ),
    Campaign(
      id: 6,
      title: 'Clean Energy Initiative',
      description: 'Install solar panels in off-grid communities',
      imageUrl: 'https://picsum.photos/seed/campaign6/600/400',
      targetAmount: 60000000,
      currentAmount: 15000000,
      category: 'Environment',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Donation Campaigns',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 8), // Add padding to prevent overflow
        itemCount: campaigns.length,
        itemBuilder: (context, index) {
          final campaign = campaigns[index];
          return CampaignCard(
            imageUrl: campaign.imageUrl,
            title: campaign.title,
            description: campaign.description,
            targetAmount: campaign.targetAmount,
            currentAmount: campaign.currentAmount,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/campaign_detail',
                arguments: campaign,
              );
            },
          );
        },
      ),
    );
  }
}