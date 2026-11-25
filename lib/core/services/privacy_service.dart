import '../config/backend_config.dart';

class PrivacyNotice {
  final String version, english, filipino;
  final String? shownLanguage;
  const PrivacyNotice(
    this.version,
    this.english,
    this.filipino, {
    this.shownLanguage,
  });
  PrivacyNotice inLanguage(String language) => PrivacyNotice(
    version,
    english,
    filipino,
    shownLanguage: language == 'fil' ? 'fil' : 'en',
  );
  factory PrivacyNotice.fromMap(Map<String, dynamic> row) => PrivacyNotice(
    row['version'] as String,
    row['english'] as String,
    row['filipino'] as String,
  );
  String text(String language) => language == 'fil' ? filipino : english;
}

class PrivacyState {
  final PrivacyNotice notice;
  final bool accepted;
  const PrivacyState(this.notice, this.accepted);
}

class PrivacyService {
  static Future<PrivacyNotice> notice() async => PrivacyNotice.fromMap(
    Map<String, dynamic>.from(
      await BackendConfig.client.rpc('get_privacy_notice'),
    ),
  );
  static Future<PrivacyState> status() async {
    final row = Map<String, dynamic>.from(
      await BackendConfig.client.rpc('get_privacy_consent_status'),
    );
    return PrivacyState(PrivacyNotice.fromMap(row), row['accepted'] == true);
  }

  static Future<void> accept(
    String shownVersion, {
    required String language,
  }) async {
    await BackendConfig.client.rpc(
      'record_own_privacy_consent_with_language',
      params: {
        'p_version': shownVersion,
        'p_language': language == 'fil' ? 'fil' : 'en',
      },
    );
  }
}
