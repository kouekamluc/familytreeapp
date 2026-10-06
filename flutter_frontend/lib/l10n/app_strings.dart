import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'catalog.dart';

/// Presentation-only translations. Never pass family data through this API.
class AppStrings {
  final Locale locale;
  const AppStrings(this.locale);
  static const supportedLocales = [Locale('en'), Locale('fr')];
  static const delegate = _StringsDelegate();
  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings) ??
      const AppStrings(Locale('en'));

  String text(String source) {
    final french = locale.languageCode == 'fr';
    final direct = french ? englishToFrench[source] : frenchToEnglish[source];
    if (direct != null) return direct;
    for (final template in _templates) {
      final match = (french ? template.englishPattern : template.frenchPattern)
          .firstMatch(source);
      if (match == null) continue;
      final result = french ? template.french : template.english;
      return result.replaceAllMapped(RegExp(r'\{(\d+)\}'), (slot) {
        final index = int.parse(slot.group(1)!);
        final value = match.group(index + 1)!;
        return template.translatedArguments.contains(index)
            ? text(value)
            : value;
      });
    }
    if (source.contains('\n')) {
      return source.split('\n').map(text).join('\n');
    }
    return source;
  }
}

final frenchToEnglish = {
  for (final entry in englishToFrench.entries) entry.value: entry.key,
};
final _templates = [for (final entry in messageTemplates) _Template(entry)];

class _Template {
  final String english, french;
  final Set<int> translatedArguments;
  late final RegExp englishPattern = _pattern(english);
  late final RegExp frenchPattern = _pattern(french);
  _Template((String, String, Set<int>) entry)
    : english = entry.$1,
      french = entry.$2,
      translatedArguments = entry.$3;
  static RegExp _pattern(String template) {
    final pieces = template.split(RegExp(r'\{\d+\}'));
    return RegExp('^${pieces.map(RegExp.escape).join('([\\s\\S]*?)')}\$');
  }
}

class _StringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _StringsDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'fr'].contains(locale.languageCode);
  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings(locale));
  @override
  bool shouldReload(_StringsDelegate old) => false;
}

extension LocalizedContext on BuildContext {
  String tr(String source) => AppStrings.of(this).text(source);
}

FormFieldValidator<T>? localizeValidator<T>(
  BuildContext context,
  FormFieldValidator<T>? validator,
) => validator == null
    ? null
    : (value) {
        final error = validator(value);
        return error == null ? null : context.tr(error);
      };

/// This wrapper keeps const layouts while rebuilding translated copy on locale
/// changes. Names, stories, notes and other user content use ordinary Text.
class AppText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final bool? softWrap;
  final TextOverflow? overflow;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final TextScaler? textScaler;
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.textScaler,
  });
  @override
  Widget build(BuildContext context) => Text(
    context.tr(data),
    style: style,
    textAlign: textAlign,
    textDirection: textDirection,
    softWrap: softWrap,
    overflow: overflow,
    maxLines: maxLines,
    semanticsLabel: semanticsLabel == null ? null : context.tr(semanticsLabel!),
    textWidthBasis: textWidthBasis,
    textHeightBehavior: textHeightBehavior,
    textScaler: textScaler,
  );
}
