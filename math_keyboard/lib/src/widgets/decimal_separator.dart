import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:intl/number_symbols.dart';
import 'package:intl/number_symbols_data.dart';

/// Returns the appropriate decimal separator for the current locale.
///
/// The [context] is used for a dependency on [Localizations].
///
/// Defaults to `.` as a decimal separator if none is found in
/// [numberFormatSymbols] for the current locale.
String decimalSeparator(BuildContext context) {
  final locale = Localizations.localeOf(context);
  final numberFormatVerifiedLocale = Intl.verifiedLocale(
    '${locale.languageCode}_${locale.countryCode}',
    NumberFormat.localeExists,
  );

  final symbols = numberFormatSymbols[numberFormatVerifiedLocale];
  if (symbols is NumberSymbols) {
    return symbols.DECIMAL_SEP;
  }
  return '.';
}
