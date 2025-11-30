import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/custom_widgets.dart';

class VolunteerCampaignListPage extends StatefulWidget {
  const VolunteerCampaignListPage({Key? key}) : super(key: key);

  @override
  State<VolunteerCampaignListPage> createState() => _VolunteerCampaignListPageState();
}

class _VolunteerCampaignListPageState extends State<VolunteerCampaignListPage> {
  List<VolunteerCampaign> volunteerCampaigns = [
    VolunteerCampaign(
      id: 1,
      title: 'Beach Cleanup Campaign',
      description: 'Join us in cleaning up the coastline and protecting marine life',
      imageUrl: 'https://picsum.photos/seed/volunteer1/600/400',
      location: 'Bali, Indonesia',
      startDate: DateTime(2025, 12, 20),
      endDate: DateTime(2025, 12, 22),
      maxVolunteers: 100,
      registeredVolunteers: 65,
      requirements: 'Willingness to work in the sun, comfortable with physical activity',
      benefits: 'Lunch provided, certificate of participation',
    ),
    VolunteerCampaign(
      id: 2,
      title: 'Elderly Care Support',
      description: 'Spend time with elderly residents and provide companionship',
      imageUrl: 'https://picsum.photos/seed/volunteer2/600/400',
      location: 'Jakarta, Indonesia',
      startDate: DateTime(2025, 12, 15),
      endDate: DateTime(2025, 12, 30),
      maxVolunteers: 50,
      registeredVolunteers: 32,
      requirements: 'Good communication skills, patience, and empathy',
      benefits: 'Experience in social work, reference letter',
    ),
    VolunteerCampaign(
      id: 3,
      title: 'Education Support Program',
      description: 'Teach basic reading and writing to children in rural areas',
      imageUrl: 'https://picsum.photos/seed/volunteer3/600/400',
      location: 'Yogyakarta, Indonesia',
      startDate: DateTime(2026, 1, 5),
      endDate: DateTime(2026, 1, 20),
      maxVolunteers: 30,
      registeredVolunteers: 18,
      requirements: 'Basic teaching skills, patience with children',
      benefits: 'Teaching experience, personal satisfaction',
    ),
    VolunteerCampaign(
      id: 4,
      title: 'Community Garden Project',
      description: 'Help establish a community garden for local residents',
      imageUrl: 'https://picsum.photos/seed/volunteer4/600/400',
      location: 'Bandung, Indonesia',
      startDate: DateTime(2025, 11, 30),
      endDate: DateTime(2025, 12, 15),
      maxVolunteers: 40,
      registeredVolunteers: 25,
      requirements: 'Physical ability to work outdoors, enthusiasm for gardening',
      benefits: 'Fresh produce, gardening skills',
    ),
    VolunteerCampaign(
      id: 5,
      title: 'Disaster Relief Distribution',
      description: 'Help distribute food and supplies to disaster-affected areas',
      imageUrl: 'https://picsum.photos/seed/volunteer5/600/400',
      location: 'Aceh, Indonesia',
      startDate: DateTime(2025, 12, 10),
      endDate: DateTime(2025, 12, 25),
      maxVolunteers: 75,
      registeredVolunteers: 45,
      requirements: 'Physical stamina, ability to lift heavy items',
      benefits: 'Experience in emergency response, humanitarian work',
    ),
    VolunteerCampaign(
      id: 6,
      title: 'Children\'s Reading Program',
      description: 'Read to children and help them develop literacy skills',
      imageUrl: 'https://picsum.photos/seed/volunteer6/600/400',
      location: 'Surabaya, Indonesia',
      startDate: DateTime(2025, 12, 18),
      endDate: DateTime(2026, 1, 8),
      maxVolunteers: 25,
      registeredVolunteers: 15,
      requirements: 'Love for reading, patience with children',
      benefits: 'Reading experience, community impact',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Volunteer Opportunities', showBackButton: true),
      body: ListView.builder(
        itemCount: volunteerCampaigns.length,
        itemBuilder: (context, index) {
          final campaign = volunteerCampaigns[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/volunteer_campaign_detail',
                  arguments: campaign,
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 120,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                      child: Container(
                        width: 100,
                        height: double.infinity,
                        child: Image.network(
                          campaign.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              campaign.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              campaign.location,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.date_range,
                                  size: 12,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_formatDate(campaign.startDate)} - ${_formatDate(campaign.endDate)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: campaign.registeredVolunteers / campaign.maxVolunteers,
                              minHeight: 4,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2972FF)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${campaign.registeredVolunteers} of ${campaign.maxVolunteers} spots filled',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}