import 'package:intl/intl.dart';

final currencyFmt =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
final dateFmt = DateFormat('dd MMM yyyy');
final dateTimeFmt = DateFormat('dd MMM yyyy, hh:mm a');
