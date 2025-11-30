import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'About Us'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Logo/Title
              const Center(
                child: Text(
                  'DonateNow',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2972FF),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // About Description
              const Text(
                'About Our Platform',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              const Text(
                'DonateNow is a digital platform designed to connect donors with worthy causes around the world. We believe that everyone has the power to make a positive impact, and we provide the tools to make giving simple, secure, and meaningful.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Vision Section
              const Text(
                'Our Vision',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'To create a world where every person has access to basic needs and opportunities for a better life through the power of collective giving.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Mission Section
              const Text(
                'Our Mission',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'To facilitate transparent and efficient charitable giving by connecting donors with verified causes, ensuring that every donation reaches those who need it most.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Purpose Section
              const Text(
                'Our Purpose',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'We exist to bridge the gap between compassion and action. Our platform enables individuals and organizations to contribute to meaningful causes, track their impact, and see the real-world difference their donations make.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Team Introduction
              const Text(
                'Our Team',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              const Text(
                'We are a dedicated team of professionals passionate about social impact and technology. Our diverse backgrounds in technology, social work, and finance allow us to create innovative solutions for charitable giving.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}