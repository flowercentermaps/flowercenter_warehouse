import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../data/datasources/stock_check_logs_datasource.dart';
import '../../domain/entities/stock_check_item.dart';

Future<void> showShortageHistorySheet(
  BuildContext context, {
  required StockCheckItem item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShortageSheet(item: item),
  );
}

class _ShortageSheet extends StatefulWidget {
  final StockCheckItem item;
  const _ShortageSheet({required this.item});

  @override
  State<_ShortageSheet> createState() => _ShortageSheetState();
}

class _ShortageSheetState extends State<_ShortageSheet> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = StockCheckLogsDataSource(Supabase.instance.client)
        .fetchShortagesForSupplier(
      supplierCode: widget.item.supplierCode,
      days: 30,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.rLg)),
          border: Border(
            top:   BorderSide(color: AppConstants.goldBorder(context)),
            left:  BorderSide(color: AppConstants.goldBorder(context)),
            right: BorderSide(color: AppConstants.goldBorder(context)),
          ),
        ),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (ctx, snap) => Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s20, AppSpacing.s14,
                AppSpacing.s20, AppSpacing.s20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(l),
                const SizedBox(height: AppSpacing.s12),
                if (snap.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.s32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppConstants.primaryColor,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                else if (snap.hasError)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.s24),
                    child: Text(
                      'Failed to load history: ${snap.error}',
                      style: TextStyle(
                        color: AppConstants.dangerColor,
                        fontSize: 12,
                      ),
                    ),
                  )
                else
                  _buildContent(snap.data ?? const [], l),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations l) {
    final item     = widget.item;
    final title    = item.productName.isNotEmpty ? item.productName : item.itemCode;
    final subtitle = item.itemCode.isNotEmpty && item.itemCode != item.supplierCode
        ? '${item.itemCode} · ${item.supplierCode}'
        : item.supplierCode;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.trending_down_rounded,
            size: 20, color: AppConstants.warningColor),
        const SizedBox(width: AppSpacing.s10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.shortageTitle,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.textMuted(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppConstants.textFaint(context),
                  ),
                ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> logs, AppLocalizations l) {
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppConstants.successColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppSpacing.rMd),
          border: Border.all(
              color: AppConstants.successColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 22, color: AppConstants.successColor),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Text(
                l.shortageEmpty,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    final partial = logs.where((e) => e['after_status'] == 'partial').length;
    final oos     = logs.where((e) => e['after_status'] == 'out_of_stock').length;
    final recent  = logs.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.s8,
          children: [
            _statChip(
              icon: Icons.error_outline_rounded,
              color: AppConstants.dangerColor,
              label: l.oosCount(oos),
            ),
            _statChip(
              icon: Icons.remove_circle_outline_rounded,
              color: AppConstants.warningColor,
              label: l.partialCount(partial),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s14),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.s8),
          child: Text(
            recent.length == logs.length
                ? l.recentEvents
                : l.mostRecentOf(recent.length, logs.length),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: AppConstants.textMuted(context),
            ),
          ),
        ),
        ...recent.map((e) => _buildEventRow(e, l)),
      ],
    );
  }

  Widget _statChip({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s10, vertical: AppSpacing.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.rPill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: AppSpacing.s4),
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              )),
        ],
      ),
    );
  }

  Widget _buildEventRow(Map<String, dynamic> log, AppLocalizations l) {
    final status  = (log['after_status'] ?? '').toString();
    final reason  = (log['shortage_reason'] ?? '').toString().trim();
    final who     = (log['changed_by_name'] ?? '').toString().trim();
    final whenStr = _formatWhen(log['changed_at']);
    final color   = status == 'out_of_stock'
        ? AppConstants.dangerColor
        : AppConstants.warningColor;
    final label   = status == 'out_of_stock'
        ? l.statusOutOfStockLabel
        : l.statusPartialLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const Spacer(),
                    Text(whenStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppConstants.textMuted(context),
                        )),
                  ],
                ),
                if (reason.isNotEmpty)
                  Text('"$reason"',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppConstants.textMuted(context),
                      )),
                if (who.isNotEmpty)
                  Text(who,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppConstants.textFaint(context),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatWhen(dynamic raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return raw.toString();
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays >= 1)    return '${diff.inDays}d ago';
    if (diff.inHours >= 1)   return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return DateFormat('HH:mm').format(dt);
  }
}
