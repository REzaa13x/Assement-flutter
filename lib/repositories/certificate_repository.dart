import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/volunteer_certificate.dart';
import '../services/api_service.dart';

class CertificateListResult {
  final List<VolunteerCertificate> certificates;
  final CertificateMeta? meta;
  final String? message;

  CertificateListResult({
    required this.certificates,
    this.meta,
    this.message,
  });
}

class CertificateRepository {
  /// Mengambil daftar sertifikat milik pengguna yang sedang login
  static Future<CertificateListResult> getMyCertificates(
      {String? token}) async {
    try {
      final response = await ApiService.get('v1/certificates', token: token);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final dynamic rawList = json['data'];

        List<VolunteerCertificate> list = [];
        if (rawList is List) {
          list = rawList
              .map((e) =>
                  VolunteerCertificate.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }

        CertificateMeta? meta;
        if (json['meta'] != null && json['meta'] is Map) {
          meta =
              CertificateMeta.fromJson(Map<String, dynamic>.from(json['meta']));
        }

        return CertificateListResult(
          certificates: list,
          meta: meta,
          message: json['message']?.toString(),
        );
      } else if (response.statusCode == 401) {
        throw Exception('Sesi login telah berakhir. Silakan login kembali.');
      } else {
        final Map<String, dynamic>? err = _tryParseJson(response.body);
        final String msg = err?['message'] ??
            'Gagal mengambil daftar sertifikat (${response.statusCode})';
        throw Exception(msg);
      }
    } catch (e) {
      debugPrint('CertificateRepository.getMyCertificates error: $e');
      rethrow;
    }
  }

  /// Mengambil detail satu sertifikat milik pengguna
  static Future<VolunteerCertificate> getCertificateDetail(int id,
      {String? token}) async {
    try {
      final response =
          await ApiService.get('v1/certificates/$id', token: token);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final dynamic rawData = json['data'];
        if (rawData is Map) {
          return VolunteerCertificate.fromJson(
              Map<String, dynamic>.from(rawData));
        }
        throw Exception('Data sertifikat tidak valid');
      } else if (response.statusCode == 404) {
        throw Exception('Sertifikat tidak ditemukan.');
      } else if (response.statusCode == 401) {
        throw Exception('Sesi login telah berakhir. Silakan login kembali.');
      } else {
        final Map<String, dynamic>? err = _tryParseJson(response.body);
        final String msg = err?['message'] ??
            'Gagal mengambil detail sertifikat (${response.statusCode})';
        throw Exception(msg);
      }
    } catch (e) {
      debugPrint('CertificateRepository.getCertificateDetail error: $e');
      rethrow;
    }
  }

  /// Mengambil URL download (signed temporary route dari Laravel)
  static Future<String> getDownloadUrl(int id, {String? token}) async {
    try {
      final response = await ApiService.get('v1/certificates/$id/download-url',
          token: token);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final String? rawUrl = json['download_url']?.toString();
        if (rawUrl != null && rawUrl.isNotEmpty) {
          final normalized = AppConfig.resolveServerUrl(rawUrl);
          final uri = Uri.parse(normalized);
          if (uri.scheme != 'https' && uri.scheme != 'http') {
            throw Exception('URL unduhan sertifikat tidak valid.');
          }
          return normalized;
        }
        throw Exception('URL download tidak ditemukan');
      } else if (response.statusCode == 403) {
        final Map<String, dynamic>? err = _tryParseJson(response.body);
        final String msg = err?['message'] ??
            'Sertifikat belum dapat diunduh. Kegiatan relawan belum selesai.';
        throw Exception(msg);
      } else {
        final Map<String, dynamic>? err = _tryParseJson(response.body);
        final String msg = err?['message'] ??
            'Gagal memperoleh link download (${response.statusCode})';
        throw Exception(msg);
      }
    } catch (e) {
      debugPrint('CertificateRepository.getDownloadUrl error: $e');
      rethrow;
    }
  }

  /// Download langsung raw bytes PDF dari endpoint API
  static Future<Uint8List> downloadCertificatePdfBytes(int id,
      {String? token}) async {
    try {
      final url = ApiService.endpointUri('v1/certificates/$id/download');
      final requestHeaders = {
        'Accept': 'application/pdf',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(url, headers: requestHeaders)
          .timeout(ApiService.requestTimeout);

      if (response.statusCode == 200) {
        if (response.bodyBytes.length < 5 ||
            String.fromCharCodes(response.bodyBytes.take(5)) != '%PDF-') {
          throw Exception('Server tidak mengembalikan file PDF sertifikat.');
        }
        return response.bodyBytes;
      } else if (response.statusCode == 403) {
        final Map<String, dynamic>? err = _tryParseJson(response.body);
        final String msg = err?['message'] ??
            'Sertifikat belum dapat diunduh. Kegiatan belum selesai.';
        throw Exception(msg);
      } else {
        throw Exception('Gagal mengunduh file PDF (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('CertificateRepository.downloadCertificatePdfBytes error: $e');
      rethrow;
    }
  }

  /// Verifikasi sertifikat secara publik menggunakan nomor sertifikat
  static Future<Map<String, dynamic>> verifyCertificate(
      String certificateNumber) async {
    try {
      final response = await ApiService.get(
          'v1/certificate/verify/${Uri.encodeComponent(certificateNumber)}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final Map<String, dynamic>? err = _tryParseJson(response.body);
        final String msg = err?['message'] ?? 'Gagal memverifikasi sertifikat';
        throw Exception(msg);
      }
    } catch (e) {
      debugPrint('CertificateRepository.verifyCertificate error: $e');
      rethrow;
    }
  }

  static Map<String, dynamic>? _tryParseJson(String body) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) return parsed;
      if (parsed is Map) return Map<String, dynamic>.from(parsed);
    } catch (_) {}
    return null;
  }
}
