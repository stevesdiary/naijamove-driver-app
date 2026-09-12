import 'package:intl/intl.dart';

/// "₦ 1,350" — the spec always writes the naira sign with a thin space.
String naira(int amount, {bool signed = false}) {
  final f = NumberFormat('#,###', 'en_NG');
  final abs = f.format(amount.abs());
  if (signed) return amount < 0 ? '−₦ $abs' : '+₦ $abs';
  return '${amount < 0 ? '−' : ''}₦ $abs';
}

String nairaRange(int min, int max) {
  final f = NumberFormat('#,###', 'en_NG');
  return '₦ ${f.format(min)}–${f.format(max)}';
}

String timeOf(DateTime d) => DateFormat('h:mm a').format(d);
String dayMonth(DateTime d) => DateFormat('d MMM').format(d);
String dayMonthTime(DateTime d) => DateFormat('d MMM · h:mm a').format(d);
String fullDate(DateTime d) => DateFormat('EEE, d MMM yyyy · h:mm a').format(d);
String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);

String relative(DateTime d, {DateTime? now}) {
  final n = now ?? DateTime(2026, 9, 11, 17, 42);
  final diff = n.difference(d);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) {
    return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
  }
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays} days ago';
  if (diff.inDays < 14) return '1 week ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
  return dayMonth(d);
}

String dayLabel(DateTime d, {DateTime? now}) {
  final n = now ?? DateTime(2026, 9, 11);
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(d.year, d.month, d.day);
  if (day == today) return 'Today';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return DateFormat('EEEE, d MMM').format(d);
}

String maskPhone(String phone) {
  // "+234 803 123 4567" -> "+234 803 XXX XXXX"
  final parts = phone.split(' ');
  if (parts.length < 4) return phone;
  return '${parts[0]} ${parts[1]} XXX XXXX';
}
