import 'package:flutter/material.dart';
import 'models.dart'; // Model lama (tetap biarkan untuk halaman lain)
import 'models/donation_campaign.dart'; // <--- 1. TAMBAHKAN IMPORT INI

// Pages
import 'pages/home_page.dart';
import 'pages/list_campaign_page.dart';
import 'pages/volunteer_campaign_list_page.dart';
import 'pages/profile_page.dart';
import 'pages/campaign_detail_page.dart';
import 'pages/donation_form_page.dart';
import 'pages/payment_success_page.dart';
import 'pages/about_us_page.dart';
import 'pages/how_it_works_page.dart';
import 'pages/volunteer_page.dart';
import 'pages/volunteer_campaign_detail_page.dart';
import 'pages/volunteer_registration_form_page.dart';
import 'pages/start_campaign_page.dart';
import 'pages/edit_profile_page.dart';
import 'pages/donation_history_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Donation App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2972FF),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/list_campaign': (context) => const ListCampaignPage(),
        
        // --- 2. PERBAIKAN DI BAGIAN INI ---
        '/campaign_detail': (context) {
          // Ganti 'Campaign?' menjadi 'DonationCampaign'
          // Kita memaksa args dibaca sebagai DonationCampaign karena dikirim dari Home
          final campaign = ModalRoute.of(context)!.settings.arguments as DonationCampaign;
          return CampaignDetailPage(campaign: campaign);
        },
        // ----------------------------------

        '/donation_form': (context) => const DonationFormPage(),
        '/payment_success': (context) => const PaymentSuccessPage(),
        '/about_us': (context) => const AboutUsPage(),
        '/how_it_works': (context) => const HowItWorksPage(),
        '/volunteer': (context) => const VolunteerPage(),
        '/volunteer_campaigns': (context) => const VolunteerCampaignListPage(),
        '/volunteer_campaign_detail': (context) {
          final campaign = ModalRoute.of(context)?.settings.arguments as VolunteerCampaign?;
          return VolunteerCampaignDetailPage(campaign: campaign);
        },
        '/volunteer_registration': (context) => const VolunteerRegistrationFormPage(),
        '/start_campaign': (context) => const StartCampaignPage(),
        '/profile': (context) => const ProfilePage(),
        '/edit_profile': (context) => const EditProfilePage(),
        '/donation_history': (context) => const DonationHistoryPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}