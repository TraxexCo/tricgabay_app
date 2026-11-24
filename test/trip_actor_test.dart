import 'package:flutter_test/flutter_test.dart';
import 'package:tricgabay_app/l10n/app_localizations_en.dart';
import 'package:tricgabay_app/l10n/app_localizations_fil.dart';
import 'package:tricgabay_app/models/trip_record.dart';

void main() {
  group('TripEvent.actorFromRow', () {
    test('a null role is the system, not Unknown', () {
      expect(TripEvent.actorFromRow(role: null), TripActor.system);
      expect(
        TripEvent.actorFromRow(role: null, metadata: const <String, dynamic>{}),
        TripActor.system,
      );
    });

    test('an empty role is the system too', () {
      expect(TripEvent.actorFromRow(role: ''), TripActor.system);
    });

    test('metadata.actor names the system actor when there is no role', () {
      expect(
        TripEvent.actorFromRow(
          role: null,
          metadata: const {
            'actor': 'system',
            'reason': 'scheduled_start_passed',
          },
        ),
        TripActor.system,
      );
    });

    test('an unreadable metadata.actor still falls back to the system', () {
      expect(
        TripEvent.actorFromRow(role: null, metadata: const {'actor': 'robot'}),
        TripActor.system,
      );
      expect(
        TripEvent.actorFromRow(role: null, metadata: 'not a map'),
        TripActor.system,
      );
      expect(
        TripEvent.actorFromRow(role: null, metadata: const {'actor': 42}),
        TripActor.system,
      );
    });

    test(
      'a metadata.actor that is a known actor is used when there is no role',
      () {
        expect(
          TripEvent.actorFromRow(
            role: null,
            metadata: const {'actor': 'admin'},
          ),
          TripActor.admin,
        );
      },
    );

    test('a person role wins over metadata', () {
      expect(
        TripEvent.actorFromRow(
          role: 'driver',
          metadata: const {'actor': 'system'},
        ),
        TripActor.driver,
      );
      expect(TripEvent.actorFromRow(role: 'tourist'), TripActor.tourist);
      expect(TripEvent.actorFromRow(role: 'admin'), TripActor.admin);
    });

    test('a role this version does not know stays Unknown', () {
      expect(TripEvent.actorFromRow(role: 'inspector'), TripActor.unknown);
      expect(TripEvent.actorFromRow(role: 'unknown'), TripActor.unknown);
    });
  });

  test('the system actor is labelled System, not Unknown', () {
    expect(AppLocalizationsEn().actorSystem, 'System');
    expect(AppLocalizationsEn().unknown, 'Unknown');
    expect(
      AppLocalizationsFil().actorSystem,
      isNot(AppLocalizationsFil().unknown),
    );
  });
}
