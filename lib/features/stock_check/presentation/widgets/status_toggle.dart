import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_spacing.dart';
import '../../domain/entities/check_status.dart';

class StatusToggle extends StatelessWidget {
  final CheckStatus current;
  final ValueChanged<CheckStatus> onChanged;

  const StatusToggle({
    super.key,
    required this.current,
    required this.onChanged,
  });

  static const _statuses = [
    CheckStatus.available,
    CheckStatus.partial,
    CheckStatus.outOfStock,
  ];

  Color _colorFor(CheckStatus s) => switch (s) {
        CheckStatus.available  => AppConstants.successColor,
        CheckStatus.partial    => AppConstants.warningColor,
        CheckStatus.outOfStock => AppConstants.dangerColor,
        CheckStatus.pending    => Colors.grey,
      };

  IconData _iconFor(CheckStatus s) => switch (s) {
        CheckStatus.available  => Icons.check_circle_rounded,
        CheckStatus.partial    => Icons.remove_circle_rounded,
        CheckStatus.outOfStock => Icons.cancel_rounded,
        CheckStatus.pending    => Icons.radio_button_unchecked,
      };

  String _subtitleFor(CheckStatus s, AppLocalizations l) => switch (s) {
        CheckStatus.available  => l.statusAvailable,
        CheckStatus.partial    => l.statusPartial,
        CheckStatus.outOfStock => l.statusOutOfStock,
        CheckStatus.pending    => '',
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      children: _statuses.map((s) {
        final isSelected  = current == s;
        final color       = _colorFor(s);
        final isLast      = s == _statuses.last;
        final unselectedFg = AppConstants.textFaint(context);
        final label       = s.localizedLabel(l);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.s8),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: '$label, ${_subtitleFor(s, l)}',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.rMd),
                  onTap: () {
                    if (!isSelected) {
                      HapticFeedback.selectionClick();
                      onChanged(s);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    constraints: const BoxConstraints(minHeight: 32),
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: AppSpacing.s4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(
                              alpha: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? 0.2
                                  : 0.12)
                          : AppConstants.softSurface(context),
                      borderRadius: BorderRadius.circular(AppSpacing.rMd),
                      border: Border.all(
                        color: isSelected
                            ? color.withValues(alpha: 0.6)
                            : AppConstants.softBorder(context),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _iconFor(s),
                          size: 14,
                          color: isSelected ? color : unselectedFg,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelected ? color : unselectedFg,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
