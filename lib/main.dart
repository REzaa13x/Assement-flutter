import 'package:flutter/material.dart';
import 'models.dart'; // Model lama (tetap biarkan untuk halaman lain)
import 'models/donation_campaign.dart'; // <--- 1. TAMBAHKAN IMPORT INI
import 'models/volunteer_campaign.dart';

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
import 'pages/campaign_history_page.dart';
import 'pages/volunteer_history_page.dart';
import 'pages/my_certificates_page.dart';
import 'pages/certificate_detail_page.dart';
import 'models/volunteer_certificate.dart';
import 'pages/notifications_page.dart'; // Halaman riwayat notifikasi
import 'pages/donation_transaction_detail_page.dart'; // Detail donasi dari notifikasi
import 'pages/assistant_chat_page.dart'; // DonGiv Assistant Chatbot
import 'pages/campaign_page.dart'; // Import new campaign page
import 'pages/reviews_page.dart'; // Halaman Ulasan dan Rating
import 'pages/login_page.dart'; // Import login page
import 'pages/register_page.dart'; // Import register page
import 'pages/splash_page.dart'; // Import splash page
import 'services/notification_service.dart'; // Import layanan notifikasi (FCM)
import 'widgets/web_api_test.dart'; // Import web API test widget
import 'widgets/connection_debug.dart'; // Import connection debug widget
import 'widgets/manual_api_test.dart'; // Import manual API test widget

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi notifikasi (FCM + notifikasi lokal) sebelum aplikasi tampil.
  // Jika Firebase belum dikonfigurasi, proses ini gagal diam-diam dan
  // seluruh fitur lain tetap berjalan normal.
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Donation App',
      // Navigator global untuk navigasi dari notifikasi (FCM)
      navigatorKey: NotificationService.navigatorKey,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2972FF),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/splash',
      // Build only the splash at startup; Flutter otherwise also builds '/'
      // underneath '/splash', starting dashboard requests before login.
      onGenerateInitialRoutes: (_) => [
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/splash'),
          builder: (_) => const SplashPage(),
        ),
      ],
      routes: {
        '/splash': (context) => const SplashPage(),
        '/': (context) => const HomePage(),
        '/list_campaign': (context) => const ListCampaignPage(),
        '/api_campaigns': (context) =>
            const CampaignPage(), // New route for API-based campaigns
        '/api_test': (context) => const WebApiTestScreen(), // API test route
        '/debug': (context) => const ConnectionDebugScreen(), // Debug route
        '/manual_test': (context) =>
            const ManualApiTest(), // Manual API test route
        '/login': (context) => const LoginPage(), // Login route
        '/register': (context) => const RegisterPage(), // Register route

        // --- 2. PERBAIKAN DI BAGIAN INI ---
        '/campaign_detail': (context) {
          // Ganti 'Campaign?' menjadi 'DonationCampaign'
          // Kita memaksa args dibaca sebagai DonationCampaign karena dikirim dari Home
          final campaign =
              ModalRoute.of(context)!.settings.arguments as DonationCampaign;
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
          final campaign =
              ModalRoute.of(context)?.settings.arguments as VolunteerCampaign?;
          return VolunteerCampaignDetailPage(campaign: campaign);
        },
        '/volunteer_registration': (context) =>
            const VolunteerRegistrationFormPage(),
        '/start_campaign': (context) => const StartCampaignPage(),
        '/profile': (context) => const ProfilePage(),
        '/edit_profile': (context) => const EditProfilePage(),
        '/donation_history': (context) => const DonationHistoryPage(),
        '/campaign_history': (context) => const CampaignHistoryPage(),
        '/volunteer_history': (context) => const VolunteerHistoryPage(),
        '/my_certificates': (context) => const MyCertificatesPage(),
        '/certificate_detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final cert = args is VolunteerCertificate ? args : null;
          return CertificateDetailPage(certificate: cert);
        },
        '/notifications': (context) => const NotificationsPage(),
        '/assistant_chat': (context) => const AssistantChatPage(),
        '/donation_transaction_detail': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          final orderId = arguments is Map
              ? (arguments['order_id']?.toString() ?? '')
              : (arguments?.toString() ?? '');
          return DonationTransactionDetailPage(orderId: orderId);
        },
        '/reviews': (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          return ReviewsPage(
            initialActivityType: args?['activity_type']?.toString(),
            initialActivityId: args?['activity_id'] != null
                ? int.tryParse(args!['activity_id'].toString())
                : null,
            initialCampaignTitle: args?['campaign_title']?.toString(),
          );
        },
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
