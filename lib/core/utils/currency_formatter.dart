import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: 'KES ',
    decimalDigits: 0,
  );

  static String format(double amount) {
    return _formatter.format(amount);
  }
}