import 'package:flutter/material.dart';
import '../../domain/entities/check_status.dart';
import '../../../../core/constants/app_constants.dart';

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
        CheckStatus.available   => AppConstants.successColor,
        CheckStatus.partial     => AppConstants.warningColor,
        CheckStatus.outOfStock  => AppConstants.dangerColor,
        CheckStatus.pending     => Colors.grey,
      };

  IconData _iconFor(CheckStatus s) => switch (s) {
        CheckStatus.available   => Icons.check_circle_rounded,
        CheckStatus.partial     => Icons.remove_circle_rounded,
        CheckStatus.outOfStock  => Icons.cancel_rounded,
        CheckStatus.pending     => Icons.radio_button_unchecked,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _statuses.map((s) {
        final isSelected = current == s;
        final color = _colorFor(s);
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => onChanged(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_iconFor(s),
                      size: 14,
                      color: isSelected ? color : Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    s.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? color : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
