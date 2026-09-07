const _weekdays = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];

const _months = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
];

/// French date formatting, hand-rolled the way the tables mockup already did
/// it. The app ships a single locale, so pulling in `intl` for this would buy
/// nothing.
String formatSessionDate(DateTime date) {
  final weekday = _weekdays[date.weekday - 1];
  return '$weekday ${date.day} ${_months[date.month - 1]}, ${formatTime(date)}';
}

String formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${hour}h${minute == '00' ? '' : minute}';
}

String formatShortDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]}';

/// "il y a 3 h" and friends, for the notification list.
String formatRelative(DateTime date) {
  final elapsed = DateTime.now().difference(date);

  if (elapsed.inMinutes < 1) return "à l'instant";
  if (elapsed.inMinutes < 60) return 'il y a ${elapsed.inMinutes} min';
  if (elapsed.inHours < 24) return 'il y a ${elapsed.inHours} h';
  if (elapsed.inDays < 7) return 'il y a ${elapsed.inDays} j';
  return formatShortDate(date);
}
