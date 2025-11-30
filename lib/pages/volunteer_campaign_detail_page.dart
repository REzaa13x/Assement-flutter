import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/custom_widgets.dart';

class VolunteerCampaignDetailPage extends StatefulWidget {
  final VolunteerCampaign? campaign;

  const VolunteerCampaignDetailPage({Key? key, this.campaign}) : super(key: key);

  @override
  State<VolunteerCampaignDetailPage> createState() => _VolunteerCampaignDetailPageState();
}

class _VolunteerCampaignDetailPageState extends State<VolunteerCampaignDetailPage> {
  @override
  Widget build(BuildContext context) {
    final VolunteerCampaign campaign = widget.campaign ?? VolunteerCampaign(
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
    );

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(campaign.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              campaign.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Color(0xFF2972FF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            campaign.location,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2972FF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        campaign.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Event Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailItem(
                        icon: Icons.date_range,
                        label: 'Date',
                        value: '${_formatDate(campaign.startDate)} - ${_formatDate(campaign.endDate)}',
                      ),
                      _buildDetailItem(
                        icon: Icons.people,
                        label: 'Spots Available',
                        value: '${campaign.availableSpots} of ${campaign.maxVolunteers}',
                      ),
                      _buildDetailItem(
                        icon: Icons.check_circle,
                        label: 'Registered',
                        value: '${campaign.registeredVolunteers} volunteers',
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Requirements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          campaign.requirements,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Benefits',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2972FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          campaign.benefits,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2972FF),
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/volunteer_registration');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2972FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Join This Campaign',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          // Share functionality can be added here
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.share, color: Color(0xFF2972FF)),
                            SizedBox(width: 8),
                            Text(
                              'Share this campaign',
                              style: TextStyle(
                                color: Color(0xFF2972FF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF2972FF),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}