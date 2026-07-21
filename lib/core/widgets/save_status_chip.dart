import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import 'app_spacing.dart';

enum SaveStatus { idle, saving, saved, failed }

/// Small chip showing the current save status of edits on this screen.
///
/// `idle`   → empty (zero-sized) widget, nothing shown
/// `saving` → spinner + "Saving…"
/// `saved`  → check + "Saved"   (auto-fades after 2s — managed by parent)
/// `failed` → ✕ + "Save failed"  with optional retry tap
class SaveStatusChip extends StatelessWidget {
  final SaveStatus status;
  final VoidCallback? onRetry;

  const SaveStatusChip({
    super.key,
    required this.status,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case SaveStatus.idle:
        return const SizedBox.shrink();

      case SaveStatus.saving:
        return _buildChip(
          color: AppConstants.primaryColor,
          leading: const SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppConstants.primaryColor,
            ),
          ),
          label: 'Saving…',
        );

      case SaveStatus.saved:
        return _buildChip(
          color: AppConstants.successColor,
          leading: const Icon(Icons.check_rounded,
              size: 13, color: AppConstants.successColor),
          label: 'Saved',
        );

      case SaveStatus.failed:
        return GestureDetector(
          onTap: onRetry,
          child: _buildChip(
            color: AppConstants.dangerColor,
            leading: const Icon(Icons.refresh_rounded,
                size: 13, color: AppConstants.dangerColor),
            label: onRetry == null ? 'Save failed' : 'Retry save',
          ),
        );
    }
  }

  Widget _buildChip({
    required Color color,
    required Widget leading,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s10, vertical: AppSpacing.s4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.rPill),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: AppSpacing.s6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
