import 'language_manager.dart';

String formatRelativeTime(DateTime time, AppLocalizations loc) {
  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inMinutes < 1) {
    return loc.relativeJustNow;
  }

  if (diff.inMinutes < 60) {
    return loc.relativeMinutes(diff.inMinutes);
  }

  if (diff.inHours < 24) {
    return loc.relativeHours(diff.inHours);
  }

  if (diff.inDays < 7) {
    return loc.relativeDays(diff.inDays);
  }

  final localTime = time.toLocal();
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final formatted =
      '${twoDigits(localTime.day)}.${twoDigits(localTime.month)}.${localTime.year} ${twoDigits(localTime.hour)}:${twoDigits(localTime.minute)}';
  return loc.relativeDate(formatted);
}
