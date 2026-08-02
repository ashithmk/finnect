import 'package:intl/intl.dart';

/// Formats numeric amounts as currency strings, respecting the user's
/// selected currency code/symbol (stored via `profile` feature +
/// `shared_preferences`).
class CurrencyFormatter {
  final String currencyCode;
  final String currencySymbol;
  final String locale;

  CurrencyFormatter({
    this.currencyCode = 'INR',
    this.currencySymbol = '₹',
    this.locale = 'en_IN',
  });

  NumberFormat _getFormat(int decimals) => NumberFormat.currency(
        locale: locale,
        symbol: currencySymbol,
        decimalDigits: decimals,
      );

  /// e.g. ₹830 (or ₹830.50 if amount has non-zero decimals)
  String format(num? amount) {
    if (amount == null) return '${currencySymbol}0';
    final bool isInteger = (amount % 1) == 0;
    return _getFormat(isInteger ? 0 : 2).format(amount);
  }

  /// e.g. ₹12,345 (no decimals — good for dashboard summary cards)
  String formatCompact(num? amount) {
    if (amount == null) return '${currencySymbol}0';
    try {
      final NumberFormat compact = NumberFormat.compactCurrency(
        locale: locale,
        symbol: currencySymbol,
        decimalDigits: (amount.abs() % 1 == 0) ? 0 : 1,
      );
      return compact.format(amount);
    } catch (_) {
      return format(amount);
    }
  }

  /// Format for transaction lists: ₹500 (clean positive value, no minus sign)
  String formatSigned(num? amount, {required bool isIncome}) {
    if (amount == null) return '${currencySymbol}0';
    final absAmount = amount.abs();
    final bool isInteger = (absAmount % 1) == 0;
    return _getFormat(isInteger ? 0 : 2).format(absAmount);
  }

  /// Parses a user-entered amount string, stripping symbols/commas.
  static double? tryParse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.\-]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}
