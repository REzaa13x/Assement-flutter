import 'package:flutter/material.dart';
import '../widgets/campaign_list.dart';

class CampaignPage extends StatelessWidget {
  const CampaignPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaigns'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: const CampaignList(),
    );
  }
}