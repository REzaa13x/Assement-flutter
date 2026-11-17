import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/campaign.dart';
import '../models/campaign_location.dart';
import '../models/campaign_response.dart';
import '../services/api_service.dart';

import '../config/api_config.dart';

class CampaignRepository {
  // Get all campaigns with optional filters (PUBLIC endpoint - no token needed)
  static Future<CampaignResponse> getCampaigns({
    int page = 1,
    String? status,
    String? kategori,
    String? search,
  }) async {
    String endpoint = '${ApiEndpoints.campaigns}?page=$page';

    if (status != null && status.isNotEmpty)
      endpoint += '&status=${Uri.encodeQueryComponent(status)}';
    if (kategori != null && kategori.isNotEmpty)
      endpoint += '&kategori=${Uri.encodeQueryComponent(kategori)}';
    if (search != null && search.isNotEmpty)
      endpoint += '&search=${Uri.encodeQueryComponent(search)}';

    try {
      print('Making request to: $endpoint');
      final response = await ApiService.get(endpoint);

      print('Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CampaignResponse.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw Exception('Daftar kampanye tidak ditemukan (404)');
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception(
            'Sesi telah berakhir atau tidak memiliki izin (401/403)');
      } else if (response.statusCode >= 500) {
        throw Exception(
            'Terjadi gangguan pada server backend (${response.statusCode})');
      } else {
        throw Exception('Gagal memuat kampanye (${response.statusCode})');
      }
    } catch (e) {
      print('Error in getCampaigns: $e');
      if (e is Exception && e.toString().contains('tidak ditemukan')) rethrow;
      if (e is Exception && e.toString().contains('gangguan pada server'))
        rethrow;
      if (e is Exception && e.toString().contains('Gagal memuat')) rethrow;
      throw Exception(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    }
  }

  // Get a single campaign by ID or slug (PUBLIC endpoint - no token needed)
  static Future<Campaign> getCampaign(String id) async {
    try {
      print('Making request to: v1/campaigns/$id');
      final response = await ApiService.get('v1/campaigns/$id');

      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = jsonData['data'] ?? jsonData;
        return Campaign.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Detail kampanye tidak ditemukan (404)');
      } else if (response.statusCode >= 500) {
        throw Exception(
            'Terjadi gangguan pada server backend (${response.statusCode})');
      } else {
        throw Exception(
            'Gagal memuat detail kampanye (${response.statusCode})');
      }
    } catch (e) {
      print('Error in getCampaign: $e');
      if (e is Exception &&
          (e.toString().contains('tidak ditemukan') ||
              e.toString().contains('gangguan'))) rethrow;
      throw Exception('Tidak dapat terhubung ke server.');
    }
  }

  // Get urgent campaigns (PUBLIC endpoint - no token needed)
  static Future<CampaignResponse> getUrgentCampaigns({int page = 1}) async {
    try {
      final endpoint = '${ApiEndpoints.urgentCampaigns}?page=$page';
      print('Making request to: $endpoint');
      final response = await ApiService.get(endpoint);

      print('Urgent campaigns response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CampaignResponse.fromJson(jsonData);
      } else if (response.statusCode == 404) {
        throw Exception('Kampanye mendesak tidak ditemukan');
      } else {
        throw Exception(
            'Gagal memuat kampanye mendesak (${response.statusCode})');
      }
    } catch (e) {
      print('Error in getUrgentCampaigns: $e');
      rethrow;
    }
  }

  // Create a new campaign (requires authentication - v1 API)
  static Future<Campaign> createCampaign({
    required String title,
    required String description,
    required double targetAmount,
    required String endDate,
    required String kategori,
    String? yayasan,
    String? image,
    http.MultipartFile? imageFile,
    CampaignLocation? location,
    String? recipientType,
    String? recipientDescription,
    String? whatsapp,
    String? distributionMethod,
    required String? token, // Token autentikasi wajib
  }) async {
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is required to create a campaign');
    }

    try {
      final fields = <String, String>{
        'title': title,
        'description': description,
        'target_amount': targetAmount.toString(),
        'end_date': endDate,
        'kategori': kategori,
        if (yayasan != null) 'yayasan': yayasan,
        if (recipientType != null) 'jenis_penerima': recipientType,
        if (recipientDescription != null)
          'recipient_description': recipientDescription,
        if (whatsapp != null) 'whatsapp': whatsapp,
        if (distributionMethod != null) 'penyaluran': distributionMethod,
        if (location != null) ...location.toFields(),
        if (image != null) 'image': image,
      };
      final response = imageFile != null
          ? await ApiService.postMultipart(ApiEndpoints.campaigns,
              fields: fields, file: imageFile, token: token)
          : await ApiService.post(
              ApiEndpoints.campaigns,
              {
                ...fields,
                'target_amount': targetAmount,
              },
              token: token);

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return Campaign.fromJson(jsonData['data'] ?? jsonData);
      } else {
        final body = json.decode(response.body);
        throw Exception(body['errors'] is Map
            ? (body['errors'] as Map)
                .values
                .map((value) => value is List ? value.join(' ') : '$value')
                .join('\n')
            : body['message'] ??
                'Gagal membuat kampanye (${response.statusCode})');
      }
    } catch (e) {
      if (e is TimeoutException ||
          e is http.ClientException ||
          e is FormatException) {
        throw Exception(
            'Respons pengajuan belum dapat dipastikan. Periksa Riwayat Kampanye sebelum mengirim ulang.');
      }
      rethrow;
    }
  }

  // Update an existing campaign (requires authentication - v1 API)
  static Future<Campaign> updateCampaign({
    required int id,
    String? title,
    String? description,
    double? targetAmount,
    String? endDate,
    String? kategori,
    String? yayasan,
    String? image,
    String? status,
    required String? token, // Token autentikasi wajib
  }) async {
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is required to update a campaign');
    }

    try {
      final response = await ApiService.put(
          'v1/campaigns/$id',
          {
            if (title != null) 'title': title,
            if (description != null) 'description': description,
            if (targetAmount != null) 'target_amount': targetAmount,
            if (endDate != null) 'end_date': endDate,
            if (kategori != null) 'kategori': kategori,
            if (yayasan != null) 'yayasan': yayasan,
            if (image != null) 'image': image,
            if (status != null) 'status': status,
          },
          token: token);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Campaign.fromJson(jsonData['data']);
      } else {
        throw Exception('Failed to update campaign: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating campaign: $e');
    }
  }

  // Delete a campaign (requires authentication - v1 API)
  static Future<bool> deleteCampaign(int id, {required String? token}) async {
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is required to delete a campaign');
    }

    try {
      final response =
          await ApiService.delete('v1/campaigns/$id', token: token);

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete campaign: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting campaign: $e');
    }
  }

  // Get campaigns created by logged in user (requires authentication)
  static Future<CampaignResponse> getMyCampaigns({
    required String? token,
    int page = 1,
    String? status,
    String? search,
  }) async {
    if (token == null || token.isEmpty) {
      throw Exception('Sesi telah berakhir. Silakan login kembali.');
    }

    String endpoint = '${ApiEndpoints.campaigns}?my=1&page=$page';
    if (status != null && status.isNotEmpty)
      endpoint += '&status=${Uri.encodeQueryComponent(status)}';
    if (search != null && search.isNotEmpty)
      endpoint += '&search=${Uri.encodeQueryComponent(search)}';

    try {
      print('Making request to: $endpoint');
      final response = await ApiService.get(endpoint, token: token);

      print('My campaigns response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CampaignResponse.fromJson(jsonData);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Sesi login telah berakhir. Silakan login kembali.');
      } else if (response.statusCode == 404) {
        throw Exception('Riwayat kampanye tidak ditemukan (404)');
      } else if (response.statusCode >= 500) {
        throw Exception(
            'Terjadi gangguan pada server backend (${response.statusCode})');
      } else {
        throw Exception(
            'Gagal memuat riwayat kampanye (${response.statusCode})');
      }
    } catch (e) {
      print('Error in getMyCampaigns: $e');
      if (e is Exception && e.toString().contains('login')) rethrow;
      if (e is Exception && e.toString().contains('tidak ditemukan')) rethrow;
      if (e is Exception && e.toString().contains('gangguan pada server'))
        rethrow;
      if (e is Exception && e.toString().contains('Gagal memuat')) rethrow;
      throw Exception(
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    }
  }
}
