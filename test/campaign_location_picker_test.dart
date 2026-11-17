import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_application_1/models/campaign_location.dart';
import 'package:flutter_application_1/pages/campaign_location_picker_page.dart';
import 'package:flutter_application_1/services/campaign_location_service.dart';

class MemoryCampaignTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(File('test/fixtures/campaign-photo.png').readAsBytesSync());
}

class FakeCampaignLocationService extends CampaignLocationService {
  LatLng? reversed;
  bool denyGps = false;
  @override
  Future<List<CampaignLocation>> search(String query) async => const [
        CampaignLocation(
            latitude: -6.8912345,
            longitude: 107.6101234,
            address: 'Sekolah Bandung, Jawa Barat',
            district: 'Coblong',
            city: 'Bandung',
            province: 'Jawa Barat')
      ];
  @override
  Future<CampaignLocation> reverse(LatLng point) async {
    reversed = point;
    return CampaignLocation(
        latitude: point.latitude,
        longitude: point.longitude,
        address: 'Alamat titik pilihan',
        city: 'Bandung',
        province: 'Jawa Barat');
  }

  @override
  Future<LatLng> currentPosition() async {
    if (denyGps) throw Exception('Izin lokasi belum diberikan.');
    return const LatLng(-6.9123456, 107.6123456);
  }
}

class TestDeviceLocation extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.denied;
  bool requested = false;
  bool positionRead = false;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    requested = true;
    return LocationPermission.whileInUse;
  }

  @override
  Future<Position> getCurrentPosition(
      {LocationSettings? locationSettings}) async {
    positionRead = true;
    return Position(
        longitude: 107.6123456,
        latitude: -6.9123456,
        timestamp: DateTime(2026),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0);
  }
}

void main() {
  Future<void> showPicker(
      WidgetTester tester,
      FakeCampaignLocationService service,
      ValueChanged<CampaignLocation?> onPicked) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                    body: Center(
                        child: TextButton(
                  onPressed: () async =>
                      onPicked(await Navigator.push<CampaignLocation>(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CampaignLocationPickerPage(
                                    locationService: service,
                                    tileProvider: MemoryCampaignTiles(),
                                  )))),
                  child: const Text('PILIH'),
                ))))));
    await tester.tap(find.text('PILIH'));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'initial viewport cannot be submitted and search result requires explicit confirmation',
      (tester) async {
    CampaignLocation? selected;
    await showPicker(tester, FakeCampaignLocationService(),
        (location) => selected = location);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.enterText(find.byType(TextField), 'Sekolah Bandung');
    await tester.tap(find.byTooltip('Cari lokasi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sekolah Bandung, Jawa Barat'));
    await tester.pumpAndSettle();
    expect(selected, isNull);
    await tester.tap(find.text('Pilih Lokasi Ini'));
    await tester.pumpAndSettle();
    expect(selected?.latitude, -6.8912345);
    expect(selected?.longitude, 107.6101234);
  });

  testWidgets(
      'moving map updates address and confirmed coordinates match the new pin',
      (tester) async {
    final service = FakeCampaignLocationService();
    CampaignLocation? selected;
    await showPicker(tester, service, (location) => selected = location);
    await tester.tap(find.text('Gunakan Lokasi Saya'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('Alamat titik pilihan'), findsOneWidget);
    final old = service.reversed!;
    await tester.dragFrom(
        tester.getCenter(find.byType(FlutterMap)), const Offset(-80, 0));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(service.reversed?.longitude, isNot(old.longitude));
    await tester.tap(find.text('Pilih Lokasi Ini'));
    await tester.pumpAndSettle();
    expect(selected?.latitude, service.reversed?.latitude);
    expect(selected?.longitude, service.reversed?.longitude);
  });

  testWidgets(
      'location denial leaves confirmation disabled with no static fallback coordinates',
      (tester) async {
    await showPicker(
        tester, FakeCampaignLocationService()..denyGps = true, (_) {});
    await tester.tap(find.text('Gunakan Lokasi Saya'));
    await tester.pumpAndSettle();
    expect(find.text('Izin lokasi belum diberikan.'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(find.byKey(const Key('selected-coordinates')), findsNothing);
  });

  test('GPS requests permission before returning actual device coordinates',
      () async {
    final previous = GeolocatorPlatform.instance;
    final device = TestDeviceLocation();
    GeolocatorPlatform.instance = device;
    addTearDown(() => GeolocatorPlatform.instance = previous);
    final point = await CampaignLocationService().currentPosition();
    expect(device.requested, true);
    expect(device.positionRead, true);
    expect(point.latitude, -6.9123456);
    expect(point.longitude, 107.6123456);
  });

  test('permanently denied GPS does not read a device position', () async {
    final previous = GeolocatorPlatform.instance;
    final device = TestDeviceLocation()
      ..permission = LocationPermission.deniedForever;
    GeolocatorPlatform.instance = device;
    addTearDown(() => GeolocatorPlatform.instance = previous);
    await expectLater(
        CampaignLocationService().currentPosition(), throwsException);
    expect(device.requested, false);
    expect(device.positionRead, false);
  });
}
