import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../data/datasources/stock_check_logs_datasource.dart';

Future<void> showStockCheckHistorySheet(
  BuildContext context, {
  required int quotationId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HistorySheet(quotationId: quotationId),
  );
}

class _HistorySheet extends StatefulWidget {
  final int quotationId;
  const _HistorySheet({required this.quotationId});

  @override
  State<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<_HistorySheet> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = StockCheckLogsDataSource(Supabase.instance.client)
        .fetchForQuotation(widget.quotationId);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Container(
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
        child: Column(
          children: [
            _SheetHeader(
              icon: Icons.history_rounded,
              title: l.historyTitle,
              subtitle: l.historySubtitle,
              onClose: () => Navigator.of(context).pop(),
            ),
            Divider(height: 1, color: AppConstants.goldBorder(context)),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (ctx, snap) {
                  final l2 = ctx.l10n;
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppConstants.primaryColor,
                        strokeWidth: 2.5,
                      ),
                    );
                  }
                  if (snap.hasError) {
                    return _CenteredMessage(
                      icon: Icons.error_outline_rounded,
                      color: AppConstants.dangerColor,
                      text: '${l2.historyFailedLoad}\n${snap.error}',
                    );
                  }
                  final logs = snap.data ?? const [];
                  if (logs.isEmpty) {
                    return _CenteredMessage(
                      icon: Icons.inbox_outlined,
                      color: AppConstants.textMuted(ctx),
                      text: l2.historyEmpty,
                    );
                  }
                  return ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    itemCount: logs.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.s10),
                    itemBuilder: (ctx2, i) =>
                        _HistoryRow(log: logs[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final Map<String, dynamic> log;
  const _HistoryRow({required this.log});

  @override
  Widget build(BuildContext context) {
    final l        = context.l10n;
    final product  = (log['product_name'] ?? '').toString();
    final supplier = (log['supplier_code'] ?? '').toString();
    final who      = (log['changed_by_name'] ?? '').toString().trim();
    final whenStr  = _formatWhen(log['changed_at']);
    final before   = (log['before_status'] ?? '').toString();
    final after    = (log['after_status'] ?? '').toString();
    final beforeQty = log['before_qty'];
    final afterQty  = log['after_qty'];
    final reason   = (log['shortage_reason'] ?? '').toString().trim();

    final afterColor  = _statusColor(after);
    final transition  = before.isEmpty
        ? _labelFor(after, l)
        : '${_labelFor(before, l)} → ${_labelFor(after, l)}';

    String? qtyLine;
    if (beforeQty != null || afterQty != null) {
      final b = beforeQty?.toString() ?? '—';
      final a = afterQty?.toString() ?? '—';
      qtyLine = 'Qty: $b → $a';
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppConstants.softSurface(context),
        borderRadius: BorderRadius.circular(AppSpacing.rMd),
        border: Border.all(color: AppConstants.softBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8, vertical: 3),
                decoration: BoxDecoration(
                  color: afterColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.rPill),
                  border: Border.all(color: afterColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  transition,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: afterColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                whenStr,
                style: TextStyle(
                  fontSize: 11,
                  color: AppConstants.textMuted(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            product.isNotEmpty ? product : supplier,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (supplier.isNotEmpty && product != supplier) ...[
            const SizedBox(height: 2),
            Text(
              supplier,
              style: TextStyle(
                fontSize: 11,
                color: AppConstants.textMuted(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (qtyLine != null) ...[
            const SizedBox(height: AppSpacing.s4),
            Text(qtyLine,
                style: TextStyle(
                  fontSize: 12,
                  color: AppConstants.textMuted(context),
                )),
          ],
          if (reason.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s4),
            Text('"$reason"',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppConstants.textMuted(context),
                )),
          ],
          if (who.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s6),
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 12, color: AppConstants.textFaint(context)),
                const SizedBox(width: 4),
                Text(who,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppConstants.textFaint(context),
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _formatWhen(dynamic raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return raw.toString();
    return DateFormat('dd MMM · HH:mm').format(dt);
  }

  static String _labelFor(String status, AppLocalizations l) => switch (status) {
        'available'    => l.statusAvailableLabel,
        'partial'      => l.statusPartialLabel,
        'out_of_stock' => l.statusOutOfStockLabel,
        'pending'      => l.statusPendingLabel,
        _              => status,
      };

  static Color _statusColor(String status) => switch (status) {
        'available'    => AppConstants.successColor,
        'partial'      => AppConstants.warningColor,
        'out_of_stock' => AppConstants.dangerColor,
        _              => AppConstants.primaryColor,
      };
}

class _SheetHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onClose;

  const _SheetHeader({
    required this.icon,
    required this.title,
    required this.onClose,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s20, AppSpacing.s14, AppSpacing.s8, AppSpacing.s8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppConstants.primaryColor),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    )),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConstants.textMuted(context),
                      )),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _CenteredMessage(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: AppSpacing.s10),
            Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppConstants.textMuted(context),
                )),
          ],
        ),
      ),
    );
  }
}
