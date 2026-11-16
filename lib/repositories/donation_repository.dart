import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/donation_transaction.dart';
import '../services/api_service.dart';

class DonationRepository {
  // Get user's donation history
  static Future<DonationTransactionResponse> getDonationHistory(
      {String? token, int page = 1}) async {
    if (token == null || token.isEmpty) {
      throw Exception(
          'Authentication token is required to get donation history');
    }

    try {
      // Gunakan endpoint sesuai dengan Laravel kamu: /api/v1/my-donations (endpoint yang benar dari controller Anda)
      print(
          'Making request to: v1/my-donations?page=$page'); // Endpoint sesuai Laravel kamu
      final response =
          await ApiService.get('v1/my-donations?page=$page', token: token);

      print('Donation history response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Donation history response body: ${response.body}');
        final jsonData = json.decode(response.body);

        // Format response dari Laravel: {message: "...", data: {current_page: ..., data: [...], ...}}
        if (jsonData.containsKey('data') &&
            jsonData['data'].containsKey('data')) {
          final dataSection = jsonData['data'];
          return DonationTransactionResponse(
            data: (dataSection['data'] as List)
                .map((item) => DonationTransaction.fromJson(item))
                .toList(),
            currentPage: dataSection['current_page'] ?? 1,
            perPage: dataSection['per_page'] ?? 10,
            total: dataSection['total'] ?? 0,
            lastPage: dataSection['last_page'] ?? 1,
          );
        } else if (jsonData.containsKey('data') && jsonData['data'] is List) {
          // Jika data langsung berupa array
          return DonationTransactionResponse(
            data: (jsonData['data'] as List)
                .map((item) => DonationTransaction.fromJson(item))
                .toList(),
            currentPage: page,
            perPage: 10,
            total: jsonData['data'].length,
            lastPage: page, // Estimasi lastPage
          );
        } else {
          // Jika format respons tidak sesuai ekspektasi, coba parsing langsung
          return DonationTransactionResponse.fromJson(jsonData);
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        throw Exception(
            'Failed to load donation history: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getDonationHistory: $e');
      // Jika endpoint utama gagal, coba endpoint alternatif
      try {
        // Coba endpoint profile/donations
        print('Trying alternative endpoint: v1/profile/donations?page=$page');
        final response = await ApiService.get('v1/profile/donations?page=$page',
            token: token);

        if (response.statusCode == 200) {
          final jsonData = json.decode(response.body);
          if (jsonData.containsKey('data') &&
              jsonData['data'].containsKey('data')) {
            final dataSection = jsonData['data'];
            return DonationTransactionResponse(
              data: (dataSection['data'] as List)
                  .map((item) => DonationTransaction.fromJson(item))
                  .toList(),
              currentPage: dataSection['current_page'] ?? 1,
              perPage: dataSection['per_page'] ?? 10,
              total: dataSection['total'] ?? 0,
              lastPage: dataSection['last_page'] ?? 1,
            );
          } else if (jsonData.containsKey('data') && jsonData['data'] is List) {
            // Jika data langsung berupa array
            return DonationTransactionResponse(
              data: (jsonData['data'] as List)
                  .map((item) => DonationTransaction.fromJson(item))
                  .toList(),
              currentPage: page,
              perPage: 10,
              total: jsonData['data'].length,
              lastPage: page, // Estimasi lastPage
            );
          } else {
            return DonationTransactionResponse.fromJson(jsonData);
          }
        } else {
          throw Exception(
              'Failed to load from alternative endpoint: ${response.statusCode}');
        }
      } catch (altError) {
        print('Alternative endpoint also failed: $altError');
        // Jika semua endpoint gagal, kembalikan response kosong
        return DonationTransactionResponse(
          data: [],
          currentPage: page,
          perPage: 10,
          total: 0,
          lastPage: 1,
        );
      }
    }
  }

  // Alternatif endpoint 1: /api/v1/my-donations
  static Future<DonationTransactionResponse> _getDonationHistoryAlt1(
      {int page = 1, String? token}) async {
    try {
      print('Trying alternative endpoint 1: v1/my-donations?page=$page');
      final response =
          await ApiService.get('v1/my-donations?page=$page', token: token);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DonationTransactionResponse.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to load from v1/my-donations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in alternative endpoint 1: $e');
      rethrow;
    }
  }

  // Alternatif endpoint 2: /api/my-donations (tanpa v1)
  static Future<DonationTransactionResponse> _getDonationHistoryAlt2(
      {int page = 1, String? token}) async {
    try {
      print('Trying alternative endpoint 2: my-donations?page=$page');
      final response =
          await ApiService.get('my-donations?page=$page', token: token);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DonationTransactionResponse.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to load from my-donations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in alternative endpoint 2: $e');
      rethrow;
    }
  }

  // Fungsi alternatif untuk mendapatkan donation history
  static Future<DonationTransactionResponse> _getDonationHistoryAlternative(
      {int page = 1, String? token}) async {
    try {
      print('Trying alternative endpoint: donations?page=$page');
      final response = await ApiService.get('donations?page=$page',
          token: token); // Tanpa prefix v1

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DonationTransactionResponse.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to load donation history from alternative endpoint: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in alternative donation history endpoint: $e');
      // Jika semua endpoint gagal, kembalikan response kosong
      return DonationTransactionResponse(
        data: [], // Kembalikan list kosong
        currentPage: page,
        perPage: 10,
        total: 0,
        lastPage: 1,
      );
    }
  }

  // Get a specific donation transaction
  static Future<DonationTransaction> getDonationTransaction(String orderId,
      {String? token}) async {
    if (token == null || token.isEmpty) {
      throw Exception(
          'Authentication token is required to get donation transaction');
    }

    try {
      print(
          'Making request to: v1/my-donations/$orderId'); // Gunakan endpoint yang konsisten dengan getUserDonations
      final response = await ApiService.get(
          'v1/donations/${Uri.encodeComponent(orderId)}',
          token: token);

      print('Donation transaction response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('Donation transaction response body: ${response.body}');
        final jsonData = json.decode(response.body);
        return DonationTransaction.fromJson(jsonData['data']);
      } else if (response.statusCode == 404) {
        throw Exception('Donation transaction not found');
      } else {
        throw Exception(
            'Failed to load donation transaction: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getDonationTransaction: $e');
      throw Exception('Error getting donation transaction: $e');
    }
  }

  // Create a new donation transaction (for Midtrans payment)
  // NOTE: This function has been replaced by MidtransService.createMidtransPayment
  // Use MidtransService instead for payment processing
  static Future<DonationTransaction> createDonationPayment({
    required int campaignId,
    required double amount,
    required String donorName,
    required String donorEmail,
    String? donorPhone,
    bool anonymous = false,
    required String? token,
  }) async {
    // This function is deprecated. Use MidtransService.createMidtransPayment instead.
    throw Exception(
        'This function is deprecated. Use MidtransService.createMidtransPayment instead.');
  }

  // Create a direct donation transaction (without Midtrans - for testing/simulation)
  static Future<DonationTransaction> createDirectDonation({
    required int campaignId,
    required double amount,
    required String donorName,
    required String donorEmail,
    String? donorPhone,
    bool anonymous = false,
    required String? token,
  }) async {
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is required to create donation');
    }

    try {
      print(
          'Making request to: campaigns/$campaignId/donate (direct donation)');
      final response = await ApiService.post(
          'campaigns/$campaignId/donate',
          {
            // Endpoint untuk donasi langsung
            'amount': amount,
            'donor_name': donorName,
            'donor_email': donorEmail,
            if (donorPhone != null) 'donor_phone': donorPhone,
            'anonymous': anonymous,
          },
          token: token);

      print('Create direct donation response status: ${response.statusCode}');
      if (response.statusCode == 201) {
        print('Create direct donation response body: ${response.body}');
        final jsonData = json.decode(response.body);
        return DonationTransaction.fromJson(jsonData['data']);
      } else {
        throw Exception(
            'Failed to create direct donation: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in createDirectDonation: $e');
      throw Exception('Error creating direct donation: $e');
    }
  }
}
