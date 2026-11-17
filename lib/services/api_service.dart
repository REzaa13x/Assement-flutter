import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/api_config.dart';

class ApiService {
  // Base URL from configuration
  static const String baseUrl = AppConfig.apiUrl;

  static const requestTimeout = Duration(seconds: 30);

  static Uri endpointUri(String endpoint) {
    final base = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final path = endpoint.replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse('$base/$path');
  }

  // Headers for API requests
  static Map<String, String> get headers {
    return ApiHeaders.json;
  }

  // GET request
  static Future<http.Response> get(String endpoint, {String? token}) async {
    final url = endpointUri(endpoint);
    final requestHeaders = {
      ...headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response =
        await http.get(url, headers: requestHeaders).timeout(requestTimeout);
    return response;
  }

  // POST request
  static Future<http.Response> post(String endpoint, dynamic data,
      {String? token, Duration timeout = requestTimeout}) async {
    final url = endpointUri(endpoint);
    final requestHeaders = {
      ...headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http
        .post(
          url,
          headers: requestHeaders,
          body: jsonEncode(data),
        )
        .timeout(timeout);
    return response;
  }

  // PUT request
  static Future<http.Response> put(String endpoint, dynamic data,
      {String? token}) async {
    final url = endpointUri(endpoint);
    final requestHeaders = {
      ...headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http
        .put(
          url,
          headers: requestHeaders,
          body: jsonEncode(data),
        )
        .timeout(requestTimeout);
    return response;
  }

  // DELETE request
  static Future<http.Response> delete(String endpoint,
      {String? token, dynamic data}) async {
    final url = endpointUri(endpoint);
    final requestHeaders = {
      ...headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final response = await http
        .delete(
          url,
          headers: requestHeaders,
          // Body opsional (mis. hapus device token membutuhkan payload)
          body: data != null ? jsonEncode(data) : null,
        )
        .timeout(requestTimeout);
    return response;
  }

  // POST Multipart request (untuk upload file seperti CV)
  static Future<http.Response> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    http.MultipartFile? file,
    String? token,
  }) async {
    final url = endpointUri(endpoint);
    final request = http.MultipartRequest('POST', url);

    // Tambahkan header
    request.headers['Accept'] = 'application/json';
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Tambahkan fields
    request.fields.addAll(fields);

    // Tambahkan file
    if (file != null) {
      request.files.add(file);
    }

    final streamedResponse = await request.send().timeout(requestTimeout);
    return await http.Response.fromStream(streamedResponse)
        .timeout(requestTimeout);
  }
}
