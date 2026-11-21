import 'package:intl/intl.dart';

class DateFormatter {
  /// Function untuk mengubah DateTime to String dengan format SQL.
  static String dateTimeToString(
    DateTime dateTime, [
    String format = 'yyyy-MM-dd HH:mm:ss',
    String locale = 'ID',
  ]) {
    return DateFormat(format, locale).format(dateTime);
  }

  /// Function untuk mengubah format sebuah tanggal.
  static String formatDate(
    String date, [
    String format = 'dd MMMM y',
    String locale = 'ID',
  ]) {
    if (date.contains('T') || date.contains('Z')) {
      date = '${date.substring(0, 10)} ${date.substring(11, 23)}';
    }
    DateTime tempDate = stringToDate(date);
    return DateFormat(format, locale).format(tempDate);
  }

  /// Function untuk mengubah String menjadi DateTime
  static DateTime stringToDate(
    String date, [
    String format = 'yyyy-MM-dd HH:mm:ss',
    String locale = 'ID',
  ]) {
    if (date.contains('T') || date.contains('Z')) {
      date = '${date.substring(0, 10)} ${date.substring(11, 23)}';
    }
    return DateFormat(format, locale).parse(date);
  }
}
