import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/config/app_config.dart';
import 'package:flutter_application_1/models/volunteer_certificate.dart';
import 'package:flutter_application_1/pages/certificate_detail_page.dart';
import 'package:flutter_application_1/pages/my_certificates_page.dart';
import 'package:flutter_application_1/repositories/certificate_repository.dart';

Map<String, dynamic> certificateFixture(String status, {int id = 1}) => {
      'id': id,
      'certificate_number': 'DGV-VOL-2026-$id',
      'certificate_id': 'uuid-$id',
      'volunteer_id': 42,
      'volunteer_name': 'Relawan DonGiv',
      'campaign_id': id,
      'campaign_name': 'Bersih Pantai $id',
      'category': 'Lingkungan',
      'location': 'Bandung',
      'start_date': '2026-01-01',
      'end_date': '2026-01-02',
      'issue_date': '2026-01-03',
      'volunteer_level': 'Relawan Baru',
      'total_volunteer_hours': 8,
      'organizer_name': 'DonGiv',
      'status': status,
      'status_label': status,
      'is_downloadable': status == 'active',
      'verify_url': '/certificate/verify/DGV-VOL-2026-$id',
      'download_url':
          'http://127.0.0.1:8000/volunteer/certificates/$id/download',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() =>
      SharedPreferences.setMockInitialValues({'auth_token': 'test-token'}));

  test(
      'hosting and emulator URL resolution preserves signed query and removes local port',
      () {
    const path =
        '/api/v1/certificates/1/download-signed?expires=123&signature=abc%2Fdef';
    expect(
        AppConfig.resolveServerUrl('http://127.0.0.1:8000$path',
            apiBaseUrl: 'https://donasi.example.test/api'),
        'https://donasi.example.test$path');
    expect(
        AppConfig.resolveServerUrl('http://localhost:8000$path',
            apiBaseUrl: 'http://10.0.2.2:8000/api'),
        'http://10.0.2.2:8000$path');
    expect(
        AppConfig.resolveServerUrl('/certificate/verify/ABC',
            apiBaseUrl: 'https://donasi.example.test/api'),
        'https://donasi.example.test/certificate/verify/ABC');
  });

  test('revoked and pending certificates never enable downloads', () {
    for (final status in ['pending', 'revoked']) {
      final certificate = VolunteerCertificate.fromJson(
          {...certificateFixture(status), 'is_downloadable': true});
      expect(certificate.isDownloadable, false);
    }
  });

  test('PDF API uses Bearer token and accepts actual PDF bytes', () async {
    await http.runWithClient(() async {
      final bytes = await CertificateRepository.downloadCertificatePdfBytes(1,
          token: 'test-token');
      expect(utf8.decode(bytes), startsWith('%PDF-'));
    },
        () => MockClient((request) async {
              expect(request.url.path, '/api/v1/certificates/1/download');
              expect(request.headers['Authorization'], 'Bearer test-token');
              return http.Response('%PDF-1.4 test', 200);
            }));
  });

  test('a login HTML page is not accepted as a downloaded PDF', () async {
    await http.runWithClient(() async {
      await expectLater(
          CertificateRepository.downloadCertificatePdfBytes(1,
              token: 'test-token'),
          throwsException);
    }, () => MockClient((_) async => http.Response('<html>Login</html>', 200)));
  });

  test('download link failure is surfaced without using stale session URL',
      () async {
    await http.runWithClient(() async {
      await expectLater(
          CertificateRepository.getDownloadUrl(1, token: 'test-token'),
          throwsA(predicate((e) => e.toString().contains('dicabut'))));
    },
        () => MockClient((_) async =>
            http.Response('{"message":"Sertifikat telah dicabut."}', 403)));
  });

  testWidgets(
      'list shows website contribution statistics and all certificate statuses',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: MyCertificatesPage()));
      await tester.pumpAndSettle();
      expect(find.text('Kampanye Relawan'), findsOneWidget);
      expect(find.text('Dicabut (1)'), findsOneWidget);
      expect(find.text('Bersih Pantai 1'), findsOneWidget);
    },
        () => MockClient((_) async => http.Response(
            jsonEncode({
              'data': [
                certificateFixture('active'),
                certificateFixture('pending', id: 2),
                certificateFixture('revoked', id: 3)
              ],
              'meta': {
                'total': 3,
                'total_active': 1,
                'total_hours': 8,
                'total_campaigns': 3,
                'volunteer_level': 'Relawan Baru'
              },
            }),
            200)));
  });

  testWidgets('detail refreshes status from API before allowing PDF download',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
          home: CertificateDetailPage(
        certificate:
            VolunteerCertificate.fromJson(certificateFixture('active')),
      )));
      await tester.pumpAndSettle();
      expect(find.text('Sertifikat Dicabut'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('LinkedIn'), findsOneWidget);
      final buttons =
          tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
      expect(buttons.any((button) => button.onPressed == null), true);
    },
        () => MockClient((_) async => http.Response(
            jsonEncode({'data': certificateFixture('revoked')}), 200)));
  });
}
