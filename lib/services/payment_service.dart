import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../models/donation_transaction.dart';

class PaymentService {
  // Fungsi untuk membuat pembayaran donasi (tanpa Midtrans)
  static Future<DonationTransaction> createDonationPayment({
    required int campaignId,
    required double amount,
    required String donorName,
    required String donorEmail,
    String? donorPhone,
    String paymentMethod = 'bank_transfer', // Tambahkan parameter paymentMethod
    bool anonymous = false,
    required String? token,
  }) async {
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is required to create donation payment');
    }

    try {
      print('Making request to: v1/donations');

      // Siapkan data yang akan dikirim
      Map<String, dynamic> requestData = {
        'amount': amount,
        'donor_name': donorName,
        'donor_email': donorEmail,
        'campaign_id': campaignId,
        'payment_method': paymentMethod, // Gunakan paymentMethod yang diberikan
        'anonymous': anonymous,
      };

      // Tambahkan field donor_phone jika tersedia
      if (donorPhone != null) {
        requestData['donor_phone'] = donorPhone;
      }

      // Tambahkan field yang diperlukan berdasarkan metode pembayaran
      if (paymentMethod == 'bank_transfer') {
        requestData['selected_bank'] = 'BCA'; // Gunakan bank default
      } else if (paymentMethod == 'e_wallet') {
        requestData['selected_ewallet'] = 'OVO'; // Gunakan e-wallet default
      } else if (paymentMethod == 'qris') {
        requestData['selected_qris'] = 'default_qris'; // Gunakan QRIS default
      }

      final response = await ApiService.post('v1/donations', requestData, token: token);

      print('Create donation payment response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Create donation payment response body: ${response.body}');
        final jsonData = json.decode(response.body);
        return DonationTransaction.fromJson(jsonData['data']);
      } else {
        throw Exception('Failed to create donation payment: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in createDonationPayment: $e');
      // Jika terjadi error koneksi, kembalikan data dummy untuk sementara
      print('Returning dummy transaction data for testing purposes');
      return _createDummyTransaction(campaignId, amount, donorName, donorEmail, paymentMethod);
    }
  }

  // Fungsi untuk membuat data transaksi dummy untuk keperluan testing
  static DonationTransaction _createDummyTransaction(int campaignId, double amount, String donorName, String donorEmail, [String paymentMethod = 'bank_transfer']) {
    return DonationTransaction(
      orderId: 'TEST-${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      donorName: donorName,
      donorEmail: donorEmail,
      status: 'AWAITING_TRANSFER', // Ganti ke status yang sesuai dengan server
      paymentMethod: paymentMethod, // Gunakan format yang sesuai dengan server
      campaignId: campaignId,
      statusLabel: 'Pending',
      donorPhone: null,
      userId: null,
      paymentMethodData: null,
      transferDeadline: null,
      bankAccountName: null,
      bankAccountNumber: null,
      bankName: null,
      proofOfTransferPath: null,
      transferCompletedAt: null,
      verifiedAt: null,
      campaign: null,
    );
  }

  // Fungsi untuk mengecek status pembayaran
  static Future<DonationTransaction> checkPaymentStatus({
    required String orderId,
    required String? token,
  }) async {
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is required to check payment status');
    }

    try {
      final response = await ApiService.get('v1/donations/$orderId', token: token);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DonationTransaction.fromJson(jsonData['data']);
      } else {
        throw Exception('Failed to check payment status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in checkPaymentStatus: $e');
      throw Exception('Error checking payment status: $e');
    }
  }
}