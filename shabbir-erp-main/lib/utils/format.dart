import 'package:intl/intl.dart';

String formatCurrency(double value) {
  final abs = value.abs();
  final formatted = NumberFormat('#,##,##0.00', 'en_IN').format(abs);
  return 'Rs. $formatted';
}

String formatNumber(double value) {
  return NumberFormat('#,##,##0.##', 'en_IN').format(value);
}

String formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = date.year.toString();
  return '$d-$m-$y';
}

DateTime parseDate(String s) {
  try {
    final parts = s.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
  } catch (_) {
    return DateTime.now();
  }
}

String formatDateDisplay(String s) {
  try {
    final d = parseDate(s);
    return DateFormat('dd MMM yyyy').format(d);
  } catch (_) {
    return s;
  }
}

class BalanceMeta {
  final String label;
  final String tone;
  const BalanceMeta({required this.label, required this.tone});
}

BalanceMeta balanceLabel(double balance, String partyType) {
  if (balance == 0) return const BalanceMeta(label: 'Settled', tone: 'neutral');
  if (partyType == 'Customer') {
    return balance > 0
        ? const BalanceMeta(label: 'Receivable', tone: 'receivable')
        : const BalanceMeta(label: 'Advance', tone: 'advance');
  }
  return balance < 0
      ? const BalanceMeta(label: 'Payable', tone: 'payable')
      : const BalanceMeta(label: 'Advance', tone: 'advance');
}
