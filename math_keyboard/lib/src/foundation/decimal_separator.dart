import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:intl/number_symbols_data.dart';

/// A decimal separator a math field can display.
///
/// These are the two decimal markers SI and ISO recognize. The separator only
/// affects what a field displays and announces; the TeX a field reports always
/// uses the canonical `.`.
enum DecimalSeparator {
  /// The dot used by e.g. `en`, and the canonical separator in TeX values.
  dot('.'),

  /// The comma used by e.g. `de`.
  comma(',');

  const DecimalSeparator(this.symbol);

  /// The character that is displayed.
  final String symbol;

  /// The separator of the current locale, or [dot] if it uses neither of these.
  ///
  /// The [context] is used for a dependency on [Localizations]. See
  /// [fromLocale] for the mapping.
  static DecimalSeparator of(BuildContext context) =>
      fromLocale(Localizations.localeOf(context));

  /// The separator of [locale], or [dot] if it uses neither of these.
  ///
  /// Note that a handful of locales (`ar_EG`, `fa`, `ps`) use the Arabic
  /// decimal separator, and fall back to [dot] here.
  static DecimalSeparator fromLocale(Locale locale) {
    final symbol =
        numberFormatSymbols[Intl.verifiedLocale(
              '${locale.languageCode}_${locale.countryCode}',
              NumberFormat.localeExists,
              // Intl throws for locales it does not know unless we opt out.
              onFailure: (_) => null,
            )]
            ?.DECIMAL_SEP;

    return values.firstWhere(
      (value) => value.symbol == symbol,
      orElse: () => dot,
    );
  }

  /// Rewrites the canonical `.` decimal separators in [tex] to this separator.
  ///
  /// The separator is wrapped in a TeX group (`{,}`) because a bare comma is
  /// spaced as if it separated a list, which would put a gap after it.
  String applyTo(String tex) =>
      this == dot ? tex : tex.replaceAll('.', '{$symbol}');
}
