import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../domain/entities/pending_quotation.dart';
import '../providers/pending_transfers_provider.dart';

class TodayStatsChip extends ConsumerWidget {
  const TodayStatsChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending     = ref.watch(pendingTransfersProvider).valueOrNull ?? const [];
    final transferred = ref.watch(transferredProvider).valueOrNull ?? const [];

    final todayPending     = pending.where(_isToday).length;
    final todayTransferred = transferred.where(_isToday).length;

    if (todayPending == 0 && todayTransferred == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.rPill),
          onTap: () => _showWeeklySheet(context, ref),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s10, vertical: AppSpacing.s4),
            decoration: BoxDecoration(
              color: AppConstants.softSurface(context),
              borderRadius: BorderRadius.circular(AppSpacing.rPill),
              border: Border.all(color: AppConstants.softBorder(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded,
                    size: 13, color: AppConstants.successColor),
                const SizedBox(width: 3),
                Text(
                  '$todayTransferred',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.successColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Icon(Icons.hourglass_top_rounded,
                    size: 13, color: AppConstants.warningColor),
                const SizedBox(width: 3),
                Text(
                  '$todayPending',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.warningColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _isToday(PendingQuotation q) {
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d     = q.createdAt;
    return DateTime(d.year, d.month, d.day) == today;
  }

  Future<void> _showWeeklySheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _WeeklySummarySheet(),
    );
  }
}

class _WeeklySummarySheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l           = context.l10n;
    final pending     = ref.watch(pendingTransfersProvider).valueOrNull ?? const [];
    final transferred = ref.watch(transferredProvider).valueOrNull ?? const [];

    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days  = List<DateTime>.generate(7, (i) => today.subtract(Duration(days: i)));

    int countOn(List<PendingQuotation> list, DateTime day) => list.where((q) {
          final d = q.createdAt;
          return DateTime(d.year, d.month, d.day) == day;
        }).length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.s20, AppSpacing.s4, AppSpacing.s20, AppSpacing.s20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s12),
              child: Row(
                children: [
                  Icon(Icons.insights_rounded,
                      size: 18, color: AppConstants.primaryColor),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    l.statsLast7Days,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s4, vertical: AppSpacing.s8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(l.statsDay, style: _hdr(context)),
                  ),
                  Expanded(
                    child: Text(l.statsPending,
                        textAlign: TextAlign.center, style: _hdr(context)),
                  ),
                  Expanded(
                    child: Text(l.statsTransferred,
                        textAlign: TextAlign.center, style: _hdr(context)),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppConstants.goldBorder(context)),
            ...days.map((day) {
              final isToday = day == today;
              final p = countOn(pending, day);
              final t = countOn(transferred, day);
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s4, vertical: AppSpacing.s10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        isToday ? l.statsToday : _formatDay(day, l),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                          color: isToday ? AppConstants.primaryColor : null,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '$p',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: p == 0
                              ? AppConstants.textFaint(context)
                              : AppConstants.warningColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '$t',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: t == 0
                              ? AppConstants.textFaint(context)
                              : AppConstants.successColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.s8),
            Center(
              child: Text(
                l.statsFooter,
                style: TextStyle(
                  fontSize: 11,
                  color: AppConstants.textFaint(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _hdr(BuildContext context) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
        color: AppConstants.textMuted(context),
      );

  String _formatDay(DateTime d, AppLocalizations l) {
    final now       = DateTime.now();
    final today     = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (d == yesterday) return l.statsYesterday;
    return '${l.weekdayAbbr(d.weekday)} ${d.day}';
  }
}
