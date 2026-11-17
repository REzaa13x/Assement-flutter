import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/campaign_location.dart';
import 'package:flutter_application_1/pages/start_campaign_page.dart';
import 'package:flutter_application_1/widgets/rupiah_input_formatter.dart';

class CampaignTestImagePicker extends ImagePicker {
  Uint8List bytes = File('test/fixtures/campaign-photo.png').readAsBytesSync();
  ImageSource? selectedSource;
  @override
  Future<XFile?> pickImage(
      {required ImageSource source,
      double? maxWidth,
      double? maxHeight,
      int? imageQuality,
      CameraDevice preferredCameraDevice = CameraDevice.rear,
      bool requestFullMetadata = true}) async {
    selectedSource = source;
    return XFile.fromData(bytes, name: 'campaign.png', mimeType: 'image/png');
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(
      {'auth_token': 'test-token', 'user_data': '{"id":42,"name":"Pengaju"}'}));
  const location = CampaignLocation(
      latitude: -6.8912345,
      longitude: 107.6101234,
      address: 'Jalan Pendidikan, Coblong, Bandung',
      district: 'Coblong',
      city: 'Bandung',
      province: 'Jawa Barat',
      postalCode: '40132');

  Widget app(CampaignTestImagePicker picker) => MaterialApp(
        home: StartCampaignPage(
            imagePicker: picker, pickLocation: (_, __) async => location),
        routes: {
          '/campaign_history': (_) =>
              const Scaffold(body: Text('RIWAYAT PENGAJUAN'))
        },
      );

  Future<void> type(WidgetTester tester, String key, String value) async {
    final field = find.byKey(Key(key));
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tester.pump();
  }

  Future<void> choose(WidgetTester tester, String key, String value) async {
    final dropdown = find.byKey(Key(key));
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(value).last);
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester) async {
    await type(tester, 'campaign-title', 'Renovasi Sekolah');
    await choose(tester, 'campaign-category', 'Pendidikan');
    await type(tester, 'campaign-story',
        'Penggalangan dana untuk memperbaiki sekolah warga.');
    await type(tester, 'campaign-target', '10000000');
    expect(
        tester
            .widget<EditableText>(find.descendant(
              of: find.byKey(const Key('campaign-target')),
              matching: find.byType(EditableText),
            ))
            .controller
            .text,
        '10.000.000');
    await tester.ensureVisible(find.text('Pilih tanggal berakhir'));
    await tester.tap(find.text('Pilih tanggal berakhir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih Tanggal'));
    await tester.pumpAndSettle();
    await type(tester, 'campaign-recipient', 'Sekolah Warga');
    await choose(tester, 'campaign-recipient-type', 'Komunitas');
    await type(tester, 'campaign-recipient-info',
        'Para siswa membutuhkan ruang belajar yang aman.');
    await type(tester, 'campaign-contact', '081234567890');
    await choose(tester, 'campaign-distribution', 'Langsung');
    await tester.ensureVisible(find.byKey(const Key('campaign-location')));
    await tester.tap(find.byKey(const Key('campaign-location')));
    await tester.pumpAndSettle();
    expect(find.text('Jalan Pendidikan, Coblong, Bandung'), findsOneWidget);
    await tester.ensureVisible(find.text('Tambahkan Foto'));
    await tester.tap(find.text('Tambahkan Foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih dari galeri'));
    await tester.pumpAndSettle();
    expect(find.text('Ganti Foto'), findsOneWidget);
  }

  for (final width in [320.0, 412.0]) {
    testWidgets(
        'campaign form fits $width and validates required fields with keyboard open',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(app(CampaignTestImagePicker()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajukan Kampanye'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih dan konfirmasi lokasi bantuan.'), findsOneWidget);
      expect(find.text('Tambahkan foto utama kampanye.'), findsOneWidget);
      await tester.showKeyboard(find.byKey(const Key('campaign-title')));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tambahkan Foto'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'complete form sends real multipart fields once and shows pending confirmation',
      (tester) async {
    final picker = CampaignTestImagePicker();
    final response = Completer<http.Response>();
    var calls = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(app(picker));
      await tester.pumpAndSettle();
      await fill(tester);
      await tester.tap(find.text('Ajukan Kampanye'));
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull);
      expect(calls, 1);
      response.complete(http.Response(
          '{"data":{"id":99,"status":"pending","title":"Renovasi Sekolah"}}',
          201));
      await tester.pumpAndSettle();
      expect(find.textContaining('sedang menunggu verifikasi admin'),
          findsOneWidget);
      expect(picker.selectedSource, ImageSource.gallery);
      await tester.tap(find.text('Lihat Riwayat'));
      await tester.pumpAndSettle();
      expect(find.text('RIWAYAT PENGAJUAN'), findsOneWidget);
    },
        () => MockClient((request) {
              calls++;
              expect(request.method, 'POST');
              expect(request.url.path, '/api/v1/campaigns');
              expect(request.headers['Authorization'], 'Bearer test-token');
              expect(request.headers['content-type'],
                  startsWith('multipart/form-data'));
              for (final value in [
                '-6.8912345',
                '107.6101234',
                'Sekolah Warga',
                'Komunitas',
                '081234567890',
                'Langsung',
                'Jalan Pendidikan, Coblong, Bandung'
              ]) {
                expect(latin1.decode(request.bodyBytes), contains(value));
              }
              expect(latin1.decode(request.bodyBytes).toLowerCase(),
                  contains('content-type: image/png'));
              expect(latin1.decode(request.bodyBytes),
                  isNot(contains('name="user_id"')));
              expect(latin1.decode(request.bodyBytes),
                  isNot(contains('name="status"')));
              return response.future;
            }));
  });

  testWidgets('camera photo can be removed and oversized uploads are rejected',
      (tester) async {
    final picker = CampaignTestImagePicker();
    await tester.pumpWidget(app(picker));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tambahkan Foto'));
    await tester.tap(find.text('Tambahkan Foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ambil dari kamera'));
    await tester.pumpAndSettle();
    expect(picker.selectedSource, ImageSource.camera);
    await tester.ensureVisible(find.text('Hapus Foto'));
    await tester.tap(find.text('Hapus Foto'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus Foto'), findsNothing);
    picker.bytes = Uint8List(2 * 1024 * 1024 + 1);
    await tester.tap(find.text('Tambahkan Foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih dari galeri'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Ukuran foto maksimal 2 MB'), findsOneWidget);
    expect(find.text('Hapus Foto'), findsNothing);
  });

  testWidgets('location survives editing other fields and cancelling a location change', (tester) async {
    var choices = 0;
    CampaignLocation? previous;
    await tester.pumpWidget(MaterialApp(home: StartCampaignPage(
      pickLocation: (_, selected) async {
        previous = selected;
        choices++;
        return choices == 1 ? location : null;
      },
    )));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('campaign-location')));
    await tester.tap(find.byKey(const Key('campaign-location')));
    await tester.pumpAndSettle();
    await type(tester, 'campaign-title', 'Judul yang diperbarui');
    await tester.ensureVisible(find.text('Ubah Lokasi'));
    await tester.tap(find.text('Ubah Lokasi')); await tester.pumpAndSettle();
    expect(previous?.latitude, location.latitude);
    expect(previous?.longitude, location.longitude);
    expect(find.text('Jalan Pendidikan, Coblong, Bandung'), findsOneWidget);
  });

  test('rupiah input formats thousands and preserves exact integer amount', () {
    final formatted = RupiahInputFormatter().formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
            text: 'Rp 10.000.000',
            selection: TextSelection.collapsed(offset: 13)));
    expect(formatted.text, '10.000.000');
    expect(RupiahInputFormatter.amount(formatted.text), 10000000);
  });
}
