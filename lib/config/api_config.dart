// api_config.dart
// File konfigurasi untuk endpoint-endpoint API sesuai dengan Laravel kamu

class ApiEndpoints {
  // Base endpoints untuk campaign
  static const String campaigns = 'v1/campaigns';
  static const String campaignDetail = 'v1/campaigns/{id}';
  static const String urgentCampaigns = 'v1/campaigns/urgent';
  static const String myCampaigns = 'v1/my-campaigns';

  // Endpoint untuk image proxy
  static const String imageProxy = 'images/{folder}/{filename}';

  // Endpoint untuk autentikasi
  static const String register = 'v1/register';
  static const String login = 'v1/login';
  static const String logout = 'v1/logout';
  static const String me = 'v1/me';

  // Endpoint untuk donasi
  static const String donations = 'v1/donations';
  static const String donationDetail = 'v1/donations/{order_id}';
  static const String myDonations = 'v1/my-donations';
  static const String processDonation = 'v1/donations/process/midtrans';

  // Endpoint untuk profile
  static const String profile = 'v1/profile';
  static const String profileDonations = 'v1/profile/donations';
  static const String profileVolunteer = 'v1/profile/volunteer';
  static const String profileHistory = 'v1/profile/history';
  static const String profileStats = 'v1/profile/stats';

  // Endpoint untuk volunteer
  static const String volunteerCampaigns = 'v1/volunteer-campaigns';
  static const String volunteerApplications = 'v1/volunteer-applications';

  // Endpoint untuk pembayaran midtrans
  static const String midtransPayment = 'v1/campaigns/{id}/midtrans-payment';
}

class ApiHeaders {
  static const Map<String, String> json = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Fungsi untuk menambahkan token autentikasi jika tersedia
  static Map<String, String> withAuth(String? token) {
    if (token == null || token.isEmpty) {
      return json;
    }

    return {
      ...json,
      'Authorization': 'Bearer $token',
    };
  }
}
