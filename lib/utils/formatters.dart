import 'package:intl/intl.dart';

extension NumberFormatting on num {
  String toPriceString([int fractionDigits = 2]) {
    String pattern = '#,##0';
    if (fractionDigits > 0) {
      pattern += '.${'0' * fractionDigits}';
    }
    return NumberFormat(pattern, 'tr_TR').format(this);
  }
}
