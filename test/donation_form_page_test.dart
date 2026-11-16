import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/models/donation_campaign.dart';
import 'package:flutter_application_1/pages/donation_form_page.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final width in [280.0, 320.0, 412.0]) {
    testWidgets('form fits mobile width $width and updates donation amount',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final campaign = DonationCampaign(
          id: 1,
          title: 'Bantu pendidikan',
          description: '',
          imageUrl: '',
          targetAmount: 1000000,
          currentAmount: 0,
          category: 'Pendidikan');
      await tester.pumpWidget(MaterialApp(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
                settings: RouteSettings(arguments: campaign),
                builder: (_) => const DonationFormPage(),
              )));
      await tester.pumpAndSettle();
      for (final amount in [
        'Rp 50.000',
        'Rp 100.000',
        'Rp 200.000',
        'Rp 500.000'
      ]) {
        expect(find.text(amount).hitTestable(), findsOneWidget);
      }
      await tester.tap(find.text('Rp 100.000'));
      await tester.pump();
      expect(find.text('Donasi Sekarang · Rp 100.000'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '75000');
      await tester.pump();
      expect(find.text('Donasi Sekarang · Rp 75.000'), findsOneWidget);
      await tester.tap(find.text('Donasi Sekarang · Rp 75.000'));
      await tester.pump();
      expect(find.text('Isi nama lengkap Anda'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -1200));
      await tester.pumpAndSettle();
      expect(find.text('LinkAja'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
