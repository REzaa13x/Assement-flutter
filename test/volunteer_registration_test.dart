import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/pages/volunteer_registration_form_page.dart';
import 'package:flutter_application_1/pages/login_page.dart';
import 'package:flutter/services.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({
        'auth_token': 'test-token',
        'user_data': '{"id":42,"name":"Pendaftar","email":"test@example.test"}'
      }));

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (_) => MaterialPageRoute(
        settings: const RouteSettings(arguments: {
          'volunteer_campaign_id': 7,
          'volunteer_campaign_title': 'Bakti Sosial'
        }),
        builder: (_) => VolunteerRegistrationFormPage(
            pickCvFile: () async => PlatformFile(
                name: 'resume.pdf',
                size: 20,
                bytes:
                    Uint8List.fromList(utf8.encode('%PDF-1.4 test resume')))),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(DropdownButton<String>));
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tim Lapangan (Fisik)').last);
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.ensureVisible(fields.first);
    await tester.enterText(fields.first, 'Jalan Pendidikan Bandung');
    await tester.ensureVisible(fields.last);
    await tester.enterText(
        fields.last, 'Saya ingin membantu kegiatan sosial masyarakat.');
    await tester.ensureVisible(find.text('Klik untuk upload file PDF'));
    await tester.tap(find.text('Klik untuk upload file PDF'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Kirim Pendaftaran'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'complete registration sends PDF and website fields once then confirms success',
      (tester) async {
    final response = Completer<http.Response>();
    var count = 0;
    await http.runWithClient(() async {
      await open(tester);
      await tester.tap(find.text('Kirim Pendaftaran'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNull);
      expect(count, 1);
      response
          .complete(http.Response('{"data":{"id":1,"status":"pending"}}', 201));
      await tester.pumpAndSettle();
      expect(find.text('Pendaftaran Berhasil!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((request) async {
              count++;
              expect(request.url.path, '/api/v1/volunteer-applications');
              expect(request.headers['Authorization'], 'Bearer test-token');
              final body = latin1.decode(request.bodyBytes);
              for (final text in [
                'name="volunteer_campaign_id"',
                '7',
                'name="alamat"',
                'Jalan Pendidikan Bandung',
                'name="posisi_dilamar"',
                'Lapangan',
                'name="alasan_bergabung"',
                'filename="resume.pdf"',
                'application/pdf',
                '%PDF-1.4'
              ]) {
                expect(body, contains(text));
              }
              return response.future;
            }));
  });

  testWidgets('expired session opens login and back preserves registration',
      (tester) async {
    await http.runWithClient(() async {
      await open(tester);
      await tester.tap(find.text('Kirim Pendaftaran'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      expect(await SharedPreferences.getInstance().then((p) => p.getString('auth_token')), isNull);
      Navigator.of(tester.element(find.byType(LoginPage))).pop();
      await tester.pumpAndSettle();
      expect(find.text('resume.pdf'), findsOneWidget);
      expect(find.text('Jalan Pendidikan Bandung'), findsOneWidget);
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNotNull);
    }, () => MockClient((_) async => http.Response('{"message":"Unauthenticated."}', 401)));
  });

  testWidgets('API validation error preserves form and permits retry',
      (tester) async {
    await http.runWithClient(() async {
      await open(tester);
      await tester.tap(find.text('Kirim Pendaftaran'));
      await tester.pumpAndSettle();
      expect(find.text('CV tidak valid.'), findsOneWidget);
      expect(find.text('resume.pdf'), findsOneWidget);
      expect(
          tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
          isNotNull);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((_) async => http.Response(
            jsonEncode({
              'errors': {
                'cv': ['CV tidak valid.']
              }
            }),
            422)));
  });
}
