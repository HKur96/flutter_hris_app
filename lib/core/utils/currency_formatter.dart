import 'package:intl/intl.dart';

/// Helper format mata uang Rupiah (IDR) sesuai kaidah penulisan standar Indonesia.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Format angka menjadi format Rupiah, contoh: 1500000 -> "Rp 1.500.000"
  static String format(num amount) {
    return _formatter.format(amount).replaceAll(',00', '');
  }

  /// Format angka menjadi format ringkas (K, M, Jt), misal untuk grafik/metrik sempit
  static String formatCompact(num amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)} M';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)} Jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)} Rb';
    }
    return format(amount);
  }
}
