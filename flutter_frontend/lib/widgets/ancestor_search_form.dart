import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

/// Two known, consecutive ancestors; no missing generation is inferred.
class AncestorSearchForm extends StatelessWidget {
  final Map<String, dynamic> facts;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final bool enabled;
  const AncestorSearchForm({
    super.key,
    required this.facts,
    required this.onChanged,
    this.enabled = true,
  });

  static Map<String, dynamic> payload(Map<String, dynamic> facts) => {
    for (final entry in facts.entries)
      if (entry.value != null && entry.value != '') entry.key: entry.value,
  };

  static String? validate(Map<String, dynamic> facts) {
    for (final key in ['parent_name', 'grandparent_name']) {
      if ((facts[key] as String? ?? '').trim().length < 3) {
        return 'Enter the full names of two consecutive ancestors.';
      }
    }
    for (final key in ['parent_birth_date', 'grandparent_birth_date']) {
      final value = facts[key] as String? ?? '';
      if (value.isEmpty) continue;
      final date = DateTime.tryParse(value);
      if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value) ||
          date == null ||
          date.toIso8601String().substring(0, 10) != value ||
          date.isAfter(DateTime.now())) {
        return 'Use a valid birth date: YYYY-MM-DD.';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final level = facts['ancestor_level'] as int? ?? 1;
    final younger = level == 1
        ? 'Parent’s full name'
        : level == 2
        ? 'Grandparent’s full name'
        : 'Great-grandparent’s full name';
    final older = level == 1
        ? 'Their parent’s full name (your grandparent)'
        : level == 2
        ? 'Their parent’s full name (your great-grandparent)'
        : 'Their parent’s full name';
    Widget field(String key, String label, {bool date = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: ValueKey(date ? '$key:${facts[key]}' : key),
        initialValue: facts[key] as String? ?? '',
        enabled: enabled,
        maxLength: 200,
        keyboardType: date ? TextInputType.datetime : TextInputType.text,
        readOnly: date,
        textCapitalization: date
            ? TextCapitalization.none
            : TextCapitalization.words,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: context.tr(label),
          counterText: '',
          hintText: date ? 'YYYY-MM-DD' : null,
          suffixIcon: date && (facts[key] as String? ?? '').isNotEmpty
              ? IconButton(
                  tooltip: context.tr('Clear'),
                  icon: const Icon(Icons.clear),
                  onPressed: !enabled
                      ? null
                      : () => onChanged({...facts, key: ''}),
                )
              : date
              ? const Icon(Icons.calendar_today_outlined)
              : null,
        ),
        onTap: !date || !enabled
            ? null
            : () async {
                final selected = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.tryParse(facts[key] as String? ?? '') ??
                      DateTime(1950),
                  firstDate: DateTime(1000),
                  lastDate: DateTime.now(),
                );
                if (selected != null && context.mounted) {
                  onChanged({
                    ...facts,
                    key: selected.toIso8601String().substring(0, 10),
                  });
                }
              },
        onChanged: (value) => onChanged({...facts, key: value.trim()}),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          initialValue: level,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.tr('Ancestors you know'),
          ),
          items: const [
            DropdownMenuItem(
              value: 1,
              child: AppText(
                'Parent and grandparent',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 2,
              child: AppText(
                'Grandparent and great-grandparent',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            DropdownMenuItem(
              value: 3,
              child: AppText(
                'Great-grandparent and their parent',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          onChanged: !enabled
              ? null
              : (value) => onChanged({...facts, 'ancestor_level': value!}),
        ),
        const SizedBox(height: 16),
        field('parent_name', younger),
        field('grandparent_name', older),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const AppText('Birth details improve matching'),
          children: [
            const AppText(
              'Only enter facts you know. Unknown details do not count as matching evidence.',
            ),
            const SizedBox(height: 12),
            field('parent_birth_place', 'Younger ancestor’s birthplace'),
            field(
              'parent_birth_date',
              'Younger ancestor’s birth date',
              date: true,
            ),
            field('grandparent_birth_place', 'Older ancestor’s birthplace'),
            field(
              'grandparent_birth_date',
              'Older ancestor’s birth date',
              date: true,
            ),
          ],
        ),
      ],
    );
  }
}
