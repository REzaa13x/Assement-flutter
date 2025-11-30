import 'package:flutter/material.dart';
import '../models.dart';
import '../widgets/custom_widgets.dart';

class DonationHistoryPage extends StatefulWidget {
  const DonationHistoryPage({Key? key}) : super(key: key);

  @override
  State<DonationHistoryPage> createState() => _DonationHistoryPageState();
}

class _DonationHistoryPageState extends State<DonationHistoryPage> {
  List<DonationHistoryItem> donationHistory = [
    DonationHistoryItem(
      id: 1,
      campaignName: 'Clean Water for Rural Communities',
      amount: 500000,
      date: DateTime.now().subtract(const Duration(days: 3)),
      status: 'Completed',
    ),
    DonationHistoryItem(
      id: 2,
      campaignName: 'Education for Underprivileged Children',
      amount: 250000,
      date: DateTime.now().subtract(const Duration(days: 10)),
      status: 'Completed',
    ),
    DonationHistoryItem(
      id: 3,
      campaignName: 'Emergency Relief for Flood Victims',
      amount: 1000000,
      date: DateTime.now().subtract(const Duration(days: 15)),
      status: 'Completed',
    ),
    DonationHistoryItem(
      id: 4,
      campaignName: 'Support Local Farmers',
      amount: 750000,
      date: DateTime.now().subtract(const Duration(days: 22)),
      status: 'Completed',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Donation History'),
      body: donationHistory.isEmpty
          ? const Center(
              child: Text(
                'No donation history yet',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: donationHistory.length,
              itemBuilder: (context, index) {
                final donation = donationHistory[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Status indicator
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: donation.status == 'Completed'
                                ? Colors.green
                                : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                donation.campaignName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                              const SizedBox(height: 4),
                              
                              Text(
                                'Rp ${donation.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF2972FF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              
                              const SizedBox(height: 4),
                              
                              Text(
                                '${donation.date.day}/${donation.date.month}/${donation.date.year} • ${donation.status}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
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