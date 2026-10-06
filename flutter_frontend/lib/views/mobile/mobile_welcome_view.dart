import '../../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import '../../config/royal_theme.dart';
import '../../widgets/kkevo_ui.dart';
import '../../widgets/kkevo_brand.dart';
import '../../widgets/language_sheet.dart';

class MobileWelcomeView extends StatelessWidget {
  final VoidCallback onExplore, onSignIn;
  final VoidCallback? onStart;
  const MobileWelcomeView({
    super.key,
    required this.onExplore,
    required this.onSignIn,
    this.onStart,
  });
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (ctx, box) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(child: KkevoBrand()),
                      IconButton(
                        tooltip: context.tr('Language'),
                        onPressed: () => LanguageSheet.show(ctx),
                        icon: const Icon(Icons.language_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (box.maxWidth >= 800)
                    Row(
                      children: [
                        const Expanded(
                          child: Center(child: FamilyGrove(size: 360)),
                        ),
                        Expanded(child: _message(ctx)),
                      ],
                    )
                  else ...[
                    Center(
                      child: FamilyGrove(size: box.maxHeight < 730 ? 170 : 210),
                    ),
                    const SizedBox(height: 16),
                    _message(ctx),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 14,
                    children: [
                      _reason(
                        ctx,
                        Icons.favorite_rounded,
                        'Your stories',
                        RoyalTheme.coral,
                      ),
                      _reason(
                        ctx,
                        Icons.account_tree_rounded,
                        'Your roots',
                        RoyalTheme.green,
                      ),
                      _reason(
                        ctx,
                        Icons.verified_user_rounded,
                        'Your pace',
                        RoyalTheme.blue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppText(
                    'Your own account. Family-confirmed connections.\nYour family stays in control of access.',
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Widget _message(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppText(
        'Your family.\nOne story.',
        style: Theme.of(context).textTheme.headlineLarge,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      AppText(
        'Build your family, one connection at a time.',
        style: Theme.of(context).textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 28),
      KkevoButton(
        label: 'Start my story',
        icon: Icons.arrow_forward_rounded,
        onPressed: onStart ?? onSignIn,
      ),
      const SizedBox(height: 12),
      KkevoButton(label: 'Sign in', secondary: true, onPressed: onSignIn),
      TextButton(
        onPressed: onExplore,
        child: const AppText('Explore an example family'),
      ),
    ],
  );
  Widget _reason(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 8),
      AppText(label, style: Theme.of(context).textTheme.labelLarge),
    ],
  );
}
