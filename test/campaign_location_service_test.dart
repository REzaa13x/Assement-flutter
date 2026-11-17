import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/services/campaign_location_service.dart';

void main() {
  setUp(() =>
      SharedPreferences.setMockInitialValues({'auth_token': 'test-token'}));
  test('reverse uses correct authenticated endpoint and preserves query',
      () async {
    await http.runWithClient(() async {
      final result =
          await CampaignLocationService().reverse(const LatLng(-6.9, 107.6));
      expect(result.latitude, -6.9);
    },
        () => MockClient((request) async {
              expect(request.url.path, '/api/v1/locations/reverse');
              expect(request.url.queryParameters['latitude'], '-6.9000000');
              expect(request.headers['Authorization'], 'Bearer test-token');
              return http.Response(
                  '{"data":{"latitude":-6.9,"longitude":107.6,"address":"Bandung"}}',
                  200);
            }));
  });
  test('missing route and non JSON error give actionable messages', () async {
    for (final status in [404, 502]) {
      await http.runWithClient(() async {
        await expectLater(
            CampaignLocationService().reverse(const LatLng(-6.9, 107.6)),
            throwsA(predicate((e) =>
                !e.toString().contains('FormatException') &&
                !e.toString().contains('could not be found'))));
      },
          () => MockClient(
              (_) async => http.Response('<html>Error</html>', status)));
    }
  });
}
