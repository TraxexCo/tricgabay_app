import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/services/image_upload_validator.dart';
import 'package:tricgabay_app/core/services/spot_image_material.dart';
import 'package:tricgabay_app/core/widgets/emergency_contacts_view.dart';
import 'package:tricgabay_app/l10n/app_localizations.dart';

void main() {
  final jpeg = Uint8List.fromList([255, 216, 255, 217]);
  final png = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
  test('upload magic bytes, MIME and canonical extension agree', () {
    expect(
      ImageUploadValidator.validateForObject(
        jpeg,
        path: 'license.jpg',
        contentType: 'image/jpeg',
        jpegOnly: true,
      ),
      'image/jpeg',
    );
    for (final pair in [
      ('license.png', 'image/jpeg'),
      ('license.jpg', 'image/png'),
      ('license.jpeg', 'image/jpeg'),
    ]) {
      expect(
        () => ImageUploadValidator.validateForObject(
          jpeg,
          path: pair.$1,
          contentType: pair.$2,
        ),
        throwsStateError,
      );
    }
    expect(
      () => ImageUploadValidator.validateForObject(
        png,
        path: 'license.png',
        contentType: 'image/png',
        jpegOnly: true,
      ),
      throwsStateError,
    );
    expect(
      () => ImageUploadValidator.validateForObject(
        Uint8List(5242881),
        path: 'image.jpg',
        contentType: 'image/jpeg',
      ),
      throwsStateError,
    );
  });
  test('each spot replacement has a new URL and immutable cache policy', () {
    final first = SpotImageMaterial.create('spot-a', jpeg),
        second = SpotImageMaterial.create('spot-a', jpeg);
    expect(first.path, isNot(second.path));
    expect(first.contentType, 'image/jpeg');
    expect(SpotImageMaterial.create('spot-a', png).path, endsWith('.png'));
    expect(SpotImageMaterial.cacheControl, '31536000');
    expect(() => SpotImageMaterial.create('../unsafe', jpeg), throwsStateError);
  });
  for (final language in ['en', 'fil']) {
    testWidgets(
      'emergency placeholders cannot dial and verified number opens dialer ($language)',
      (tester) async {
        final calls = <Uri>[];
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: EmergencyContactsView(
              loader: () async => [
                {
                  'name_en': 'Agency placeholder',
                  'name_fil': 'Placeholder na ahensiya',
                  'phone': null,
                  'is_placeholder': true,
                },
                {
                  'name_en': 'National hotline',
                  'name_fil': 'Pambansang hotline',
                  'phone': '911',
                  'is_placeholder': false,
                },
              ],
              dialer: (uri) async {
                calls.add(uri);
                return true;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final buttons = tester
            .widgetList<IconButton>(find.byType(IconButton))
            .toList();
        expect(buttons[0].onPressed, isNull);
        expect(buttons[1].onPressed, isNotNull);
        expect(
          find.text(
            language == 'fil' ? 'Pambansang hotline' : 'National hotline',
          ),
          findsOneWidget,
        );
        await tester.tap(find.byIcon(Icons.call_rounded).last);
        await tester.pumpAndSettle();
        // The confirm button in the dialog (the page also has Call 911).
        await tester.tap(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(FilledButton),
          ),
        );
        await tester.pumpAndSettle();
        expect(calls, [Uri(scheme: 'tel', path: '911')]);
      },
    );
  }
}
