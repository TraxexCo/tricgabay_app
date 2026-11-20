import 'package:flutter/material.dart';
import '../l10n/app_l10n.dart';
import '../l10n/locale_controller.dart';

class LanguageSelection extends StatelessWidget {
  const LanguageSelection({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final choice in AppLanguage.values)
            ListTile(
              selected: LocaleController.selection == choice,
              title: Text(switch (choice) {
                AppLanguage.device => context.l10n.useDeviceLanguage,
                AppLanguage.english => context.l10n.english,
                AppLanguage.filipino => context.l10n.filipino,
              }),
              trailing: LocaleController.selection == choice
                  ? const Icon(Icons.check)
                  : null,
              onTap: () async {
                await LocaleController.choose(choice);
                if (context.mounted) Navigator.pop(context);
              },
            ),
        ],
      ),
    ),
  );
}
