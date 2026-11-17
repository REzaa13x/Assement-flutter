import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/pages/home_page.dart';
import 'package:flutter_application_1/pages/login_page.dart';
import 'package:flutter_application_1/pages/splash_page.dart';
import 'package:flutter_application_1/services/auth_service.dart';

void main() {
  for (final savedToken in [null, 'previous-login-token']) {
    testWidgets('startup opens login with saved token: ${savedToken != null}',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        if (savedToken != null) 'auth_token': savedToken,
      });
      await tester.pumpWidget(const MyApp());
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(HomePage, skipOffstage: false), findsNothing);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Selamat Datang Kembali'), findsOneWidget);
      expect(find.byType(HomePage, skipOffstage: false), findsNothing);
      expect(Navigator.of(tester.element(find.byType(LoginPage))).canPop(),
          isFalse);
      expect(await AuthService.getToken(), savedToken);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('leaving splash early cancels the scheduled navigation',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyApp());
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
