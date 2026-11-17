import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../models/campaign_location.dart';
import 'api_service.dart';
import 'auth_service.dart';

class CampaignLocationService {
  Future<dynamic> _get(String action, Map<String, String> query) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Silakan login untuk memilih lokasi.');
    }
    final response = await ApiService.get(
        Uri(path: 'v1/locations/$action', queryParameters: query).toString(),
        token: token);
    if (response.statusCode == 404) {
      throw Exception(
          'Layanan lokasi belum terpasang pada server. Perbarui API lokasi di backend dan periksa alamat API aplikasi.');
    }
    if (response.statusCode == 401) {
      throw Exception(
          'Sesi login berakhir. Silakan login kembali untuk memilih lokasi.');
    }
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Layanan alamat tidak tersedia. Silakan coba lagi.');
    }
    if (body is! Map) {
      throw Exception('Data layanan alamat tidak valid. Silakan coba lagi.');
    }
    if (response.statusCode != 200) {
      throw Exception(body['message'] ??
          'Layanan alamat tidak tersedia. Silakan coba lagi.');
    }
    return body['data'];
  }

  Future<List<CampaignLocation>> search(String query) async {
    final data = await _get('search', {'q': query.trim()});
    return (data as List)
        .map((item) =>
            CampaignLocation.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<CampaignLocation> reverse(LatLng point) async {
    final data = await _get('reverse', {
      'latitude': point.latitude.toStringAsFixed(7),
      'longitude': point.longitude.toStringAsFixed(7),
    });
    return CampaignLocation.fromJson(Map<String, dynamic>.from(data));
  }

  Future<LatLng> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Aktifkan layanan lokasi/GPS perangkat terlebih dahulu.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Izin lokasi diblokir. Aktifkan izin lokasi DonGiv melalui pengaturan perangkat.');
    }
    if (permission == LocationPermission.denied) {
      throw Exception(
          'Izin lokasi belum diberikan. Anda tetap dapat mencari alamat atau memilih titik di peta.');
    }
    final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 20),
    ));
    return LatLng(position.latitude, position.longitude);
  }
}
