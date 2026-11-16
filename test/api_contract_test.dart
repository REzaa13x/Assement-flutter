import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/repositories/auth_repository.dart';
import 'package:flutter_application_1/repositories/campaign_repository.dart';
import 'package:flutter_application_1/repositories/notification_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('profile rejection does not persist a local success', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', '{"name":"Original"}');
    final result = await http.runWithClient(
      () => ProfileRepository.updateProfile(token: 'test', name: 'Changed'),
      () => MockClient((request) async => http.Response(
          '{"message":"Validation failed","errors":{"email":["Email invalid"]}}',
          422)),
    );
    expect(result.data, isNull);
    expect(result.message, contains('Email invalid'));
    expect(prefs.getString('user_profile'), '{"name":"Original"}');
  });

  test('notification mutations and unread count match Laravel', () async {
    final calls = <String>[];
    await http.runWithClient(() async {
      expect(await NotificationRepository.getUnreadCount(authToken: 'test'), 7);
      expect(
          await NotificationRepository.markAsRead(id: 'abc', authToken: 'test'),
          isTrue);
      expect(await NotificationRepository.markAllAsRead(authToken: 'test'),
          isTrue);
    },
        () => MockClient((request) async {
              expect(request.headers['Authorization'], 'Bearer test');
              calls.add('${request.method} ${request.url.path}');
              return http.Response('{"unread_count":7}', 200);
            }));
    expect(calls, [
      'GET /api/v1/notifications/unread-count',
      'PUT /api/v1/notifications/abc/mark-read',
      'POST /api/v1/notifications/mark-all-read',
    ]);
  });

  test('campaign image is sent as a multipart upload with campaign fields',
      () async {
    final campaign = await http.runWithClient(
      () => CampaignRepository.createCampaign(
          title: 'Bantu sekolah',
          description: 'Renovasi sekolah',
          targetAmount: 1000000,
          endDate: '2030-12-31',
          kategori: 'Pendidikan',
          token: 'test',
          imageFile: http.MultipartFile.fromBytes('image', [1, 2, 3],
              filename: 'school.png')),
      () => MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/campaigns');
        expect(
            request.headers['content-type'], startsWith('multipart/form-data'));
        expect(request.body, contains('filename="school.png"'));
        expect(request.body, contains('Pendidikan'));
        return http.Response(
            jsonEncode({
              'data': {'id': 42, 'title': 'Bantu sekolah'}
            }),
            201);
      }),
    );
    expect(campaign.id, 42);
  });
}
