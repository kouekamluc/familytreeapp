import '../l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../providers/tree_provider.dart';
import 'monogram_medallion.dart';
import 'kkevo_ui.dart';

class PersonSummaryPanel extends StatelessWidget {
  final Person person;
  final VoidCallback? onClose;
  final Function(Person)? onNavigateToPerson,
      onOpenKinship,
      onOpenPersonDetail,
      onCenter;
  const PersonSummaryPanel({
    super.key,
    required this.person,
    this.onClose,
    this.onNavigateToPerson,
    this.onOpenKinship,
    this.onOpenPersonDetail,
    this.onCenter,
  });
  @override
  Widget build(BuildContext context) {
    final tree = context.watch<TreeProvider>();
    final current = tree.people.where((p) => p.id == person.id).firstOrNull;
    if (current == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: AppText(
            'This person is no longer available in the selected family.',
          ),
        ),
      );
    }
    final parents = tree.getParentsOf(current.id),
        partners = tree.getSpousesOf(current.id),
        children = tree.getChildrenOf(current.id),
        siblings = tree.getSiblingsOf(current.id);
    final mobile = MediaQuery.sizeOf(context).shortestSide < 600;
    Widget actions() => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onOpenPersonDetail != null)
          KkevoButton(
            label: 'View full profile',
            icon: Icons.person_outline,
            onPressed: () => onOpenPersonDetail!(current),
          ),
        if (onOpenKinship != null) ...[
          const SizedBox(height: 10),
          KkevoButton(
            label: 'Explore relationship',
            icon: Icons.hub_outlined,
            secondary: true,
            onPressed: () => onOpenKinship!(current),
          ),
        ],
        if (onCenter != null)
          TextButton.icon(
            onPressed: () => onCenter!(current),
            icon: const Icon(Icons.center_focus_strong),
            label: const AppText('Centre in tree'),
          ),
      ],
    );
    Widget family(String title, List<Person> people) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        AppText(
          '$title (${people.length})',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (people.isEmpty) const AppText('Not provided'),
        for (final p in people)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: MonogramMedallion(person: p, size: 32),
            title: Text(p.fullName),
            onTap: onNavigateToPerson == null
                ? null
                : () => onNavigateToPerson!(p),
          ),
      ],
    );
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppText(
                    'Person’s profile',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    tooltip: context.tr('Close profile'),
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (mobile) ...[
              Center(child: MonogramMedallion(person: current, size: 80)),
              const SizedBox(height: 12),
              Text(
                current.fullName,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (current.traditionalName?.isNotEmpty == true)
                Text(current.traditionalName!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
            ] else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: MonogramMedallion(person: current, size: 52),
                title: Text(
                  current.fullName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                subtitle: current.traditionalName?.isNotEmpty == true
                    ? Text(current.traditionalName!)
                    : null,
              ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(label: AppText('Generation ${current.generationTier}')),
                Chip(label: AppText(current.isLiving ? 'Living' : 'Deceased')),
              ],
            ),
            if (current.lifespanText.isNotEmpty) AppText(current.lifespanText),
            if (current.villageOfOrigin?.isNotEmpty == true)
              AppText('Village: ${current.villageOfOrigin}'),
            if (current.clanTotem?.isNotEmpty == true)
              AppText('Totem: ${current.clanTotem}'),
            if (current.biography?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(current.biography!),
              ),
            if (mobile) ...[const SizedBox(height: 18), actions()],
            family('Parents', parents),
            family('Current spouses / partners', partners),
            family('Children', children),
            family('Siblings', siblings),
            const SizedBox(height: 16),
            if (!mobile)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onOpenPersonDetail != null)
                    FilledButton.icon(
                      onPressed: () => onOpenPersonDetail!(current),
                      icon: const Icon(Icons.person_outline),
                      label: const AppText('View full profile'),
                    ),
                  if (onOpenKinship != null)
                    OutlinedButton.icon(
                      onPressed: () => onOpenKinship!(current),
                      icon: const Icon(Icons.hub_outlined),
                      label: const AppText('Explore relationship'),
                    ),
                  if (onCenter != null)
                    TextButton.icon(
                      onPressed: () => onCenter!(current),
                      icon: const Icon(Icons.center_focus_strong),
                      label: const AppText('Centre in tree'),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
