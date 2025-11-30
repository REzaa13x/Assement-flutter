import 'package:flutter/material.dart';
import '../widgets/custom_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'My Profile', showBackButton: false),
      body: ListView(
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF2972FF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      'https://picsum.photos/seed/profile/200/200',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'John Doe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'johndoe@example.com',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Profile options
          _buildProfileOption(
            icon: Icons.person,
            title: 'Edit Profile',
            onTap: () {
              Navigator.pushNamed(context, '/edit_profile');
            },
          ),
          _buildProfileOption(
            icon: Icons.history,
            title: 'Donation History',
            onTap: () {
              Navigator.pushNamed(context, '/donation_history');
            },
          ),
          _buildProfileOption(
            icon: Icons.volunteer_activism,
            title: 'My Volunteering',
            onTap: () {
              // Navigate to volunteering history page
            },
          ),
          _buildProfileOption(
            icon: Icons.monetization_on,
            title: 'Start a Campaign',
            onTap: () {
              Navigator.pushNamed(context, '/start_campaign');
            },
          ),
          
          const SizedBox(height: 24),
          
          // About section
          _buildProfileOption(
            icon: Icons.info,
            title: 'About Us',
            onTap: () {
              Navigator.pushNamed(context, '/about_us');
            },
          ),
          _buildProfileOption(
            icon: Icons.help,
            title: 'How It Works',
            onTap: () {
              Navigator.pushNamed(context, '/how_it_works');
            },
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2972FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF2972FF),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}