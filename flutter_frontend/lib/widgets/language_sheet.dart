import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/language_provider.dart';

class LanguageSheet extends StatelessWidget {
  const LanguageSheet({super.key});
  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const LanguageSheet(),
  );
  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider?>();
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText('Language', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          RadioGroup<String>(
            groupValue: language?.choice ?? 'en',
            onChanged: (value) async {
              if (value == null || language == null) return;
              await language.setChoice(value);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Column(
              children: [
                RadioListTile(value: 'en', title: Text('English')),
                RadioListTile(value: 'fr', title: Text('Français')),
                RadioListTile(
                  value: 'system',
                  title: AppText('Use phone language'),
                ),
              ],
            ),
          ),
          const AppText(
            'English is used when your phone language is not supported.',
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
