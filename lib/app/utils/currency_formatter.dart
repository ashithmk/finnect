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

  NumberFormat get _format => NumberFormat.currency(
        locale: locale,
        symbol: currencySymbol,
        decimalDigits: 2,
      );

  /// e.g. ₹12,345.67
  String format(num? amount) {
    if (amount == null) return '$currencySymbol 0.00';
    return _format.format(amount);
  }

  /// e.g. ₹12,345 (no decimals — good for dashboard summary cards)
  String formatCompact(num? amount) {
    if (amount == null) return '$currencySymbol 0';
    try {
      final NumberFormat compact = NumberFormat.compactCurrency(
        locale: locale,
        symbol: currencySymbol,
        decimalDigits: amount.abs() >= 1000 ? 1 : 0,
      );
      return compact.format(amount);
    } catch (_) {
      return format(amount);
    }
  }

  /// Format for transaction lists: ₹500.00 (clean positive value, no minus sign)
  String formatSigned(num? amount, {required bool isIncome}) {
    if (amount == null) return '$currencySymbol 0.00';
    return _format.format(amount.abs());
  }

  /// Parses a user-entered amount string, stripping symbols/commas.
  static double? tryParse(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.\-]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }
}
