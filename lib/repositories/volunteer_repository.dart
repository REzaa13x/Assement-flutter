import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../config/api_config.dart';

class VolunteerRepository {
  // Get all volunteer campaigns with optional filters
  static Future<http.Response> getVolunteerCampaignsRaw({
    int page = 1,
    String? status,
    String? location,
    String? search,
  }) async {
    String endpoint = '${ApiEndpoints.volunteerCampaigns}?page=$page';

    if (status != null) endpoint += '&status=$status';
    if (location != null) endpoint += '&location=$location';
    if (search != null) endpoint += '&search=$search';

    try {
      print('Making request to: $endpoint'); // Logging untuk debugging
      final response = await ApiService.get(endpoint); // No token needed for public endpoint

      print('Volunteer campaigns response status: ${response.statusCode}'); // Logging status
      return response;
    } catch (e) {
      print('Error in getVolunteerCampaigns: $e'); // Logging error
      rethrow;
    }
  }

  // Get a single volunteer campaign by ID
  static Future<http.Response> getVolunteerCampaignRaw(int id) async {
    try {
      final endpoint = '${ApiEndpoints.volunteerCampaigns}/$id';
      print('Making request to: $endpoint'); // Logging untuk debugging
      final response = await ApiService.get(endpoint); // No token needed for public endpoint

      print('Volunteer campaign response status: ${response.statusCode}'); // Logging status
      return response;
    } catch (e) {
      print('Error in getVolunteerCampaign: $e'); // Logging error
      rethrow;
    }
  }

  // Get all volunteer applications for authenticated user
  static Future<http.Response> getVolunteerApplicationsRaw({String? token, int page = 1}) async {
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is required to get volunteer applications');
    }

    try {
      print('Making request to: v1/volunteer-applications?page=$page'); // Logging untuk debugging
      final response = await ApiService.get('v1/volunteer-applications?page=$page', token: token);

      print('Volunteer applications response status: ${response.statusCode}'); // Logging status
      print('Volunteer applications response body: ${response.body}'); // Logging response body

      return response;
    } catch (e) {
      print('Error in getVolunteerApplications: $e'); // Logging error
      rethrow;
    }
  }

  // Get a specific volunteer application
  static Future<http.Response> getVolunteerApplicationRaw(int id, {String? token}) async {
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is required to get volunteer application');
    }

    try {
      print('Making request to: v1/volunteer-applications/$id'); // Logging untuk debugging
      final response = await ApiService.get('v1/volunteer-applications/$id', token: token);

      print('Specific volunteer application response status: ${response.statusCode}'); // Logging status
      print('Specific volunteer application response body: ${response.body}'); // Logging response body

      return response;
    } catch (e) {
      print('Error in getVolunteerApplication: $e'); // Logging error
      rethrow;
    }
  }

  // Apply to a volunteer campaign (sesuai format website & backend Laravel)
  static Future<http.Response> applyToVolunteerCampaignRaw({
    required int volunteerCampaignId,
    required String posisiDilamar,
    required String alamat,
    required String alasanBergabung,
    http.MultipartFile? cvFile,
    // Parameter legacy / opsional untuk backward compatibility
    String? motivation,
    String? skills,
    String? name,
    String? email,
    String? phone,
    required String? token,
  }) async {
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is required to apply to volunteer campaign');
    }

    try {

      final Map<String, String> fields = {
        'volunteer_campaign_id': volunteerCampaignId.toString(),
        'posisi_dilamar': posisiDilamar,
        'alamat': alamat,
        'alasan_bergabung': alasanBergabung,
        // Kirim juga alias field untuk kompatibilitas penuh:
        'skills': posisiDilamar,
        'motivation': alasanBergabung,
      };

      if (name != null) fields['name'] = name;
      if (email != null) fields['email'] = email;
      if (phone != null) fields['phone'] = phone;

      final response = await ApiService.postMultipart(
        'v1/volunteer-applications',
        fields: fields,
        file: cvFile,
        token: token,
      );

      return response;
    } catch (e) {
      print('Error in applyToVolunteerCampaign: $e');
      rethrow;
    }
  }

  // Update a volunteer application
  static Future<http.Response> updateVolunteerApplicationRaw({
    required int id,
    String? motivation,
    String? skills,
    required String? token,
  }) async {
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is required to update volunteer application');
    }

    try {
      print('Making request to: v1/volunteer-applications/$id'); // Logging untuk debugging
      final response = await ApiService.put('v1/volunteer-applications/$id', {
        if (motivation != null) 'motivation': motivation,
        if (skills != null) 'skills': skills,
      }, token: token);

      print('Update volunteer application response status: ${response.statusCode}'); // Logging status
      print('Update volunteer application response body: ${response.body}'); // Logging response body

      return response;
    } catch (e) {
      print('Error in updateVolunteerApplication: $e'); // Logging error
      rethrow;
    }
  }

  // Cancel a volunteer application
  static Future<http.Response> cancelVolunteerApplicationRaw(int id, {required String? token}) async {
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is required to cancel volunteer application');
    }

    try {
      print('Making request to: v1/volunteer-applications/$id'); // Logging untuk debugging
      final response = await ApiService.delete('v1/volunteer-applications/$id', token: token);

      print('Cancel volunteer application response status: ${response.statusCode}'); // Logging status
      print('Cancel volunteer application response body: ${response.body}'); // Logging response body

      return response;
    } catch (e) {
      print('Error in cancelVolunteerApplication: $e'); // Logging error
      rethrow;
    }
  }
}
