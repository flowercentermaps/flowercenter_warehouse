import '../l10n/app_localizations.dart';

String formatRelative(DateTime dt, {AppLocalizations? l10n}) {
  final now   = DateTime.now();
  final local = dt.toLocal();
  final diff  = now.difference(dt);

  if (diff.inSeconds < 60) return l10n?.timeJustNow ?? 'Just now';
  if (diff.inMinutes < 60) return l10n?.timeMinutesAgo(diff.inMinutes) ?? '${diff.inMinutes}m ago';
  if (diff.inHours < 24 && _sameDay(local, now)) return l10n?.timeHoursAgo(diff.inHours) ?? '${diff.inHours}h ago';

  final todayMidnight = DateTime(now.year, now.month, now.day);
  final localMidnight = DateTime(local.year, local.month, local.day);
  final calendarDays  = todayMidnight.difference(localMidnight).inDays;

  if (calendarDays == 1) return l10n?.timeYesterday ?? 'Yesterday';
  if (calendarDays < 7)  return l10n?.timeDaysAgo(calendarDays) ?? '${calendarDays}d ago';

  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  if (local.year == now.year) return '${local.day} ${months[local.month - 1]}';
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
