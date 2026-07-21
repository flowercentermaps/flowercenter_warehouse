import 'package:flutter/material.dart';

class AppConstants {
  static const Color primaryColor = Color(0xFFD49D37);
  static const Color dangerColor  = Color(0xFFEF5350);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor    = Color(0xFF2196F3);

  // ── Theme-aware palette helpers ────────────────────────────────────────
  // Centralised so screens don't hard-code `Color(0xFF...)` literals.

  /// Card/surface background.
  static Color cardBg(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? const Color(0xFF141414)
          : Colors.white;

  /// Gold-tinted border used for cards and dividers.
  static Color goldBorder(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? const Color(0xFF3A2F0B)
          : const Color(0xFFE8D5A0);

  /// Cream/very-dark surface for unselected toggles and chips.
  static Color softSurface(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? const Color(0xFF181818)
          : const Color(0xFFFFF8E7);

  /// Darker gold border for unselected toggle outlines.
  static Color softBorder(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? const Color(0xFF4A3B12)
          : const Color(0xFFE8D5A0);

  /// Muted body text (secondary information).
  static Color textMuted(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? const Color(0xFFBFA75A)
          : const Color(0xFF8E8E93);

  /// Very muted hint text (lowest priority labels).
  static Color textFaint(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? const Color(0xFF666666)
          : const Color(0xFFAAAAAA);

  /// Disabled button background.
  static Color disabledBg(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? const Color(0xFF2A2A2A)
          : const Color(0xFFEEEEEE);

  /// Disabled button foreground.
  static Color disabledFg(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark
          ? const Color(0xFF555555)
          : const Color(0xFFBBBBBB);

  static const String supabaseUrl  = 'https://egfntxfseqtoxpnzxsfj.supabase.co';
  static const String supabaseKey  = 'sb_publishable_dcn9fuKgb4sWRxhrCWlUNA_2VaqIL6x';

  /// When true, "Mark as Transferred" also queues the Al-Khazen
  /// transfer-voucher + sales-invoice job (queue_uae_transfer_sale RPC).
  /// Flip to false to fully disable the auto flow without removing code.
  static const bool enableUaeAutoTransferSale = true;

  /// Warehouse/store locations — update to match your actual store names.
  /// These come from the sync data in the main CRM app.
  static const List<String> warehouseLocations = [
    'Main Warehouse',
    'Warehouse 2',
    'Warehouse 3',
    'Store Room A',
    'Store Room B',
  ];
}
