import 'dart:convert';
import '../models/donation_transaction.dart';
import 'api_service.dart';

class PaymentService {
  static Future<DonationTransaction> createDonationPayment({
    required int campaignId,
    required double amount,
    required String donorName,
    required String donorEmail,
    String? donorPhone,
    String paymentMethod = 'bank_transfer',
    String? selectedBank,
    String? selectedEwallet,
    bool anonymous = false,
    required String? token,
  }) async {
    if (token == null || token.isEmpty) {
      throw Exception('Anda harus login terlebih dahulu');
    }
    if ((paymentMethod == 'bank_transfer' && selectedBank == null) ||
        (paymentMethod == 'e_wallet' && selectedEwallet == null)) {
      throw ArgumentError('Pilih metode pembayaran terlebih dahulu');
    }
    final response = await ApiService.post(
        'v1/donations',
        {
          'amount': amount,
          'donor_name': donorName,
          'donor_email': donorEmail,
          'campaign_id': campaignId,
          'payment_method': paymentMethod,
          'anonymous': anonymous,
          if (donorPhone != null && donorPhone.isNotEmpty)
            'donor_phone': donorPhone,
          if (paymentMethod == 'bank_transfer') 'selected_bank': selectedBank,
          if (paymentMethod == 'e_wallet') 'selected_ewallet': selectedEwallet,
          if (paymentMethod == 'qris') 'selected_qris': 'default_qris',
        },
        token: token);
    final dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw Exception(
          'Respons pembayaran tidak valid. Periksa riwayat donasi sebelum mencoba kembali.');
    }
    if (response.statusCode != 200 && response.statusCode != 201) {
      final errors = body is Map ? body['errors'] : null;
      throw Exception(errors is Map
          ? errors.values.join('\n')
          : body is Map
              ? body['message'] ?? 'Gagal membuat pembayaran'
              : 'Gagal membuat pembayaran');
    }
    final transaction = DonationTransaction.fromJson(body['data']);
    if (transaction.orderId.isEmpty) {
      throw Exception(
          'Nomor transaksi tidak tersedia. Periksa riwayat donasi sebelum mencoba kembali.');
    }
    return transaction;
  }

  static Future<DonationTransaction> checkPaymentStatus(
      {required String orderId, required String? token}) async {
    if (token == null || token.isEmpty) {
      throw Exception('Anda harus login terlebih dahulu');
    }
    final response =
        await ApiService.get('v1/donations/$orderId', token: token);
    if (response.statusCode != 200) {
      throw Exception('Gagal memuat status pembayaran');
    }
    return DonationTransaction.fromJson(jsonDecode(response.body)['data']);
  }
}
