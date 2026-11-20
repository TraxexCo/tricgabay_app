import 'package:flutter/widgets.dart';
import 'app_l10n.dart';

enum FeedbackCategory {
  bug('Bug Report'),
  suggestion('Suggestion'),
  driver('Driver Concern'),
  spot('Tourist Spot Issue'),
  other('Other');

  const FeedbackCategory(this.wireValue);

  /// Existing stored category identifiers; localization never changes payloads.
  final String wireValue;
  String label(BuildContext context) => switch (this) {
    bug => context.l10n.bugReport,
    suggestion => context.l10n.suggestion,
    driver => context.l10n.driverConcern,
    spot => context.l10n.touristSpotIssue,
    other => context.l10n.other,
  };
  static FeedbackCategory fromWire(String value) =>
      values.firstWhere((c) => c.wireValue == value, orElse: () => other);
}
