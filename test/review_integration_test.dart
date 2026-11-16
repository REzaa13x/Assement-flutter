import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/pages/reviews_page.dart';
import 'package:flutter_application_1/repositories/review_repository.dart';

Map<String, dynamic> reviewResponse(String type) => {
      'data': [
        {
          'id': 1,
          'user_id': 2,
          'user_name': 'Sahabat DonGiv',
          'activity_type': type,
          'activity_id': 10,
          'campaign_title': 'Bantu Pendidikan',
          'rating': 5,
          'comment': 'Kegiatan berjalan dengan baik.',
          'is_verified': true,
          'is_anonymous': false,
        }
      ],
      'summary': {
        'total_reviews': 1,
        'average_rating': 5,
        'distribution': {'5': 1},
      }
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('review filters send the same activity categories used by the website',
      () async {
    for (final type in ['donation', 'volunteer']) {
      final result = await http.runWithClient(
        () => ReviewRepository.getReviewListResponse(activityType: type),
        () => MockClient((request) async {
          expect(request.url.path, '/api/v1/reviews');
          expect(request.url.queryParameters['activity_type'], type);
          return http.Response(jsonEncode(reviewResponse(type)), 200);
        }),
      );
      expect(result.reviews.single.activityType, type);
      expect(result.summary.totalReviews, 1);
      expect(result.summary.averageRating, 5);
    }
  });

  test(
      'failed review listing is reported instead of being shown as an empty list',
      () async {
    await http.runWithClient(
      () async {
        await expectLater(
            ReviewRepository.getReviewListResponse(), throwsException);
      },
      () => MockClient(
          (_) async => http.Response('{"message":"Unavailable"}', 500)),
    );
  });

  test('submitting a review includes reference, rating and anonymous choice',
      () async {
    final result = await http.runWithClient(
      () => ReviewRepository.submitReview(
        token: 'test-token',
        activityType: 'donation',
        activityId: 10,
        referenceId: 20,
        rating: 5,
        comment: '  Sangat membantu  ',
        isAnonymous: true,
      ),
      () => MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer test-token');
        final body = jsonDecode(request.body);
        expect(body['reference_id'], 20);
        expect(body['comment'], 'Sangat membantu');
        expect(body['is_anonymous'], true);
        return http.Response(
            '{"message":"Ulasan berhasil disimpan.","data":{"id":1}}', 201);
      }),
    );
    expect(result['success'], true);
  });

  test('invalid server response does not strand the review submission dialog',
      () async {
    final result = await http.runWithClient(
      () => ReviewRepository.submitReview(
        token: 'test',
        activityType: 'donation',
        activityId: 10,
        referenceId: 20,
        rating: 5,
        comment: 'Sangat membantu',
      ),
      () => MockClient((_) async => http.Response('<html>Error</html>', 502)),
    );
    expect(result['success'], false);
    expect(result['message'], contains('Muat ulang'));
  });

  testWidgets('review screen offers Semua Ulasan, Donasi, and Relawan filters',
      (tester) async {
    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: ReviewsPage()));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(ChoiceChip, 'Semua Ulasan'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Donasi'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Relawan'), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Relawan'));
      await tester.pumpAndSettle();
      expect(find.text('Relawan (1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
        () => MockClient((request) async => http.Response(
              jsonEncode(reviewResponse(
                  request.url.queryParameters['activity_type'] ?? 'donation')),
              200,
            )));
  });
}
