import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';

class HowItWorksPage extends StatelessWidget {
  const HowItWorksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'How It Works'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'How Our Donation Platform Works',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            Expanded(
              child: ListView(
                children: [
                  _buildStepItem(
                    step: 1,
                    title: 'Choose a Cause',
                    description: 'Browse through our verified donation campaigns and select the cause that resonates with you.',
                    icon: Icons.search,
                  ),
                  
                  _buildStepItem(
                    step: 2,
                    title: 'Make a Donation',
                    description: 'Enter your personal information and donation amount. All transactions are secure and encrypted.',
                    icon: Icons.monetization_on,
                  ),
                  
                  _buildStepItem(
                    step: 3,
                    title: 'Secure Payment',
                    description: 'Complete your payment through our secure payment gateway. We support multiple payment methods.',
                    icon: Icons.lock,
                  ),
                  
                  _buildStepItem(
                    step: 4,
                    title: 'Track Impact',
                    description: 'Monitor how your donation is being used and the impact it\'s making in the community.',
                    icon: Icons.visibility,
                  ),
                  
                  _buildStepItem(
                    step: 5,
                    title: 'Receive Updates',
                    description: 'Get regular updates about the campaign progress and success stories from beneficiaries.',
                    icon: Icons.notifications,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required int step,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step number with icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2972FF),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    step.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Step description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
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
  }
}