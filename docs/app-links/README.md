# Android password-reset App Links

This checkout uses HTTPS reset links and has an `autoVerify` intent filter.
**It is not domain-verified yet:** a domain and signing fingerprint must be supplied.
No association file was published and no hosted Auth setting was changed.

1. Choose a domain you control. Build with
   `flutter build apk --debug --dart-define=AUTH_APP_LINK_HOST=YOUR_DOMAIN`.
   The same define feeds Dart and the Android manifest, avoiding mismatched hosts.
   Without it, password-reset initiation fails closed and the manifest uses
   `unconfigured.invalid`; it does not fall back to the custom reset scheme.
2. Replace the fingerprint in `assetlinks.json` with your **Play App Signing**
   SHA-256 certificate fingerprint. Confirm the package is `com.tricgabay.app`.
   For a debug-only association, use that debug certificate in a separate test domain.
3. Publish the JSON at `https://YOUR_DOMAIN/.well-known/assetlinks.json`, HTTPS,
   application/json, without redirects. Do not publish the placeholder unchanged.
4. Add the exact `https://YOUR_DOMAIN/auth/reset-password` URL to the intended
   Supabase Auth redirect allow-list. This must be done separately by the owner;
   no hosted project was altered here. Serve a useful web fallback at that URL.
5. On an Android device with this build installed, run:
   `adb shell pm verify-app-links --re-verify com.tricgabay.app`
   and `adb shell pm get-app-links com.tricgabay.app`.
   Then test an actual password recovery email, cold start and warm start.

The Flutter framework handler is disabled for Android because Supabase Flutter
already uses app_links to process the recovery session. The existing
AuthChangeEvent.passwordRecovery listener opens the reset-password screen.
The PayMongo payment-return scheme is separate and is retained.

Sources: [Android associations](https://developer.android.com/training/app-links/about),
[verification](https://developer.android.com/training/app-links/verify-applinks),
[Flutter plugin handling](https://docs.flutter.dev/cookbook/navigation/set-up-app-links).
