import 'package:flutter/material.dart';
import '../prototype/prototype_session.dart';

class AppTranslations {
  static String tr(String english, String filipino) {
    return PrototypeSession.isFilipino.value ? filipino : english;
  }
}

extension TranslationExt on BuildContext {
  String tr(String english, String filipino) =>
      AppTranslations.tr(english, filipino);
}
