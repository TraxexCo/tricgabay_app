import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tricgabay_app/core/services/privacy_service.dart';
import 'package:tricgabay_app/core/theme/app_theme.dart';
import 'package:tricgabay_app/core/widgets/privacy_notice_view.dart';
import 'package:tricgabay_app/core/widgets/responsive_app_frame.dart';
import 'package:tricgabay_app/l10n/app_localizations.dart';

void main() {
  final notice = PrivacyNotice.fromMap(
    jsonDecode(File('test/fixtures/privacy_notice.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  for (final size in [
    const Size(320, 568),
    const Size(360, 640),
    const Size(412, 915),
    const Size(600, 960),
    const Size(960, 600),
    const Size(568, 320),
  ]) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final locale in ['en', 'fil']) {
        testWidgets(
          'privacy ${size.width}x${size.height} text=$scale $locale',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final key = GlobalKey();
            await tester.pumpWidget(
              RepaintBoundary(
                key: key,
                child: MaterialApp(
                  locale: Locale(locale),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  theme: AppTheme.lightTheme,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: ResponsiveAppFrame(child: child!),
                  ),
                  home: PrivacyNoticeView(
                    notice: notice,
                    checked: true,
                    telemetry: false,
                    saving: false,
                    onChecked: (_) {},
                    onTelemetry: (_) {},
                    onAccept: () {},
                    onRetry: () {},
                    onSignOut: () {},
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final semantics = tester.ensureSemantics();
            if (size == const Size(360, 640) && scale != 1.5) {
              for (final guideline in [
                androidTapTargetGuideline,
                labeledTapTargetGuideline,
                textContrastGuideline,
              ]) {
                await expectLater(tester, meetsGuideline(guideline));
              }
            }
            const previewDir = String.fromEnvironment('PRIVACY_PREVIEW_DIR');
            Future<void> preview(String viewport) async {
              if (previewDir.isEmpty ||
                  size != const Size(412, 915) ||
                  scale != 1 ||
                  locale != 'en') {
                return;
              }
              final boundary =
                  key.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              await tester.runAsync(() async {
                final image = await boundary.toImage(pixelRatio: 2);
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                final file = File('$previewDir/privacy-$viewport.png');
                await file.parent.create(recursive: true);
                await file.writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }

            await preview('top');
            final position = tester
                .state<ScrollableState>(find.byType(Scrollable).first)
                .position;
            position.jumpTo(position.maxScrollExtent);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (size == const Size(360, 640) && scale != 1.5) {
              for (final guideline in [
                androidTapTargetGuideline,
                labeledTapTargetGuideline,
                textContrastGuideline,
              ]) {
                await expectLater(tester, meetsGuideline(guideline));
              }
            }
            await preview('end');
            semantics.dispose();
          },
        );
      }
    }
  }
}
