import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import 'package:tricgabay_app/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/core/utils/validators.dart';

void main() {
  String repeated(int length) => List.filled(length, 'A').join();

  group('bounded form validation', () {
    test('accepts valid identity and driver values', () {
      expect(Validators.email('tourist@example.com'), isNull);
      expect(Validators.fullName('Maria Clara'), isNull);
      expect(Validators.phoneNumber('09123456789'), isNull);
      expect(Validators.plateNumber('ABC 1234'), isNull);
      expect(Validators.franchiseNumber('FR-12345'), isNull);
    });

    test('rejects values beyond the documented client bounds', () {
      expect(
        Validators.email('${repeated(250)}@mail.test'),
        predicate<String?>(
          (code) =>
              code != null &&
              code.startsWith('@l10n/') &&
              resolveMessage(
                AppLocalizationsEn(),
                code,
              ).contains('must not exceed'),
        ),
      );
      expect(
        Validators.password('A1${repeated(127)}'),
        predicate<String?>(
          (code) =>
              code != null &&
              code.startsWith('@l10n/') &&
              resolveMessage(
                AppLocalizationsEn(),
                code,
              ).contains('must not exceed'),
        ),
      );
      expect(
        Validators.fullName(repeated(Validators.fullNameMaxLength + 1)),
        predicate<String?>(
          (code) =>
              code != null &&
              code.startsWith('@l10n/') &&
              resolveMessage(
                AppLocalizationsEn(),
                code,
              ).contains('must not exceed'),
        ),
      );
      expect(
        Validators.plateNumber(repeated(Validators.plateNumberMaxLength + 1)),
        predicate<String?>(
          (code) =>
              code != null &&
              code.startsWith('@l10n/') &&
              resolveMessage(
                AppLocalizationsEn(),
                code,
              ).contains('must not exceed'),
        ),
      );
      expect(
        Validators.franchiseNumber(
          repeated(Validators.franchiseNumberMaxLength + 1),
        ),
        predicate<String?>(
          (code) =>
              code != null &&
              code.startsWith('@l10n/') &&
              resolveMessage(
                AppLocalizationsEn(),
                code,
              ).contains('must not exceed'),
        ),
      );
    });
  });
}
