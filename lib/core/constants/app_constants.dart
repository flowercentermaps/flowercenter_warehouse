import 'dart:ui';

class AppConstants {
  static const Color primaryColor = Color(0xFFD49D37);
  static const Color dangerColor  = Color(0xFFEF5350);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor    = Color(0xFF2196F3);

  static const String supabaseUrl  = 'https://egfntxfseqtoxpnzxsfj.supabase.co';
  static const String supabaseKey  = 'sb_publishable_dcn9fuKgb4sWRxhrCWlUNA_2VaqIL6x';

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
