import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/donation_campaign.dart';
import 'package:flutter_application_1/pages/home_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Map<String, dynamic> campaigns({bool empty = false}) => {
        'data': empty
            ? []
            : [
                {
                  'id': 27,
                  'title': 'Bantu Pendidikan Nusantara',
                  'description': 'Bantuan pendidikan untuk anak-anak.',
                  'image': null,
                  'target_amount': '10000000.00',
                  'current_amount': '50000.00',
                  'status': 'verified',
                  'kategori': 'Pendidikan',
                }
              ],
        'meta': {
          'current_page': 1,
          'last_page': 1,
          'per_page': 10,
          'total': empty ? 0 : 1
        },
      };

  http.Response otherEndpoint(http.Request request) {
    if (request.url.path.endsWith('/reviews')) {
      return http.Response(
          '{"data":[],"summary":{"total_reviews":0,"average_rating":0,"distribution":{}}}',
          200);
    }
    return http.Response('{"data":[]}', 200);
  }

  Widget dashboard({ValueChanged<DonationCampaign>? onDetail}) => MaterialApp(
        home: Scaffold(
            body: HomeContentModern(
          onGoToDonationTab: () {},
          onGoToVolunteerTab: () {},
        )),
        routes: {
          '/campaign_detail': (context) {
            final campaign =
                ModalRoute.of(context)!.settings.arguments as DonationCampaign;
            onDetail?.call(campaign);
            return Scaffold(body: Text('DETAIL ${campaign.title}'));
          },
        },
      );

  testWidgets(
      'dashboard loads verified campaigns and opens the matching detail',
      (tester) async {
    DonationCampaign? opened;
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await http.runWithClient(() async {
      await tester
          .pumpWidget(dashboard(onDetail: (campaign) => opened = campaign));
      await tester.pumpAndSettle();
      final title = find.text('Bantu Pendidikan Nusantara').first;
      expect(title, findsOneWidget);
      expect(find.text('Tidak Ada Kampanye'), findsNothing);
      await tester.ensureVisible(title);
      await tester.tap(title);
      await tester.pumpAndSettle();
      expect(find.text('DETAIL Bantu Pendidikan Nusantara'), findsOneWidget);
      expect(opened?.id, 27);
      expect(opened?.targetAmount, 10000000);
      expect(opened?.currentAmount, 50000);
    },
        () => MockClient((request) async {
              if (request.url.path.endsWith('/campaigns')) {
                // Reproduces Laravel: status=Active returns an empty list.
                return http.Response(
                    jsonEncode(campaigns(
                      empty:
                          request.url.queryParameters['status'] != 'verified',
                    )),
                    200);
              }
              return otherEndpoint(request);
            }));
  });

  testWidgets('empty verified campaign response shows the empty state',
      (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(dashboard());
      await tester.pumpAndSettle();
      expect(find.text('Tidak Ada Kampanye'), findsOneWidget);
      expect(find.text('Gagal Memuat Data'), findsNothing);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((request) async =>
            request.url.path.endsWith('/campaigns')
                ? http.Response(jsonEncode(campaigns(empty: true)), 200)
                : otherEndpoint(request)));
  });

  testWidgets('dashboard recovers campaign loading after retry',
      (tester) async {
    var attempts = 0;
    await http.runWithClient(() async {
      await tester.pumpWidget(dashboard());
      await tester.pumpAndSettle();
      expect(find.text('Gagal Memuat Data'), findsOneWidget);
      await tester.ensureVisible(find.text('Coba Lagi'));
      await tester.tap(find.text('Coba Lagi'));
      await tester.pumpAndSettle();
      expect(find.text('Bantu Pendidikan Nusantara'), findsWidgets);
      expect(find.text('Gagal Memuat Data'), findsNothing);
      expect(attempts, 2);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((request) async {
              if (request.url.path.endsWith('/campaigns')) {
                attempts++;
                expect(request.url.queryParameters['status'], 'verified');
                return attempts == 1
                    ? http.Response('{"message":"Unavailable"}', 500)
                    : http.Response(jsonEncode(campaigns()), 200);
              }
              return otherEndpoint(request);
            }));
  });
}
