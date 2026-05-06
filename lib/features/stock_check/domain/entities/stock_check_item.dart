import 'check_status.dart';

class StockCheckItem {
  final int quotationItemId;
  final String productName;
  final String itemCode;
  final String supplierCode;
  final double quantityNeeded;

  // Mutable check fields
  CheckStatus status;
  double? quantityAvailable;
  String? shortageReason;
  String? suggestion;
  String? warehouseLocation;

  /// DB row ID in quotation_stock_checks (null if not yet saved)
  int? checkRowId;

  StockCheckItem({
    required this.quotationItemId,
    required this.productName,
    required this.itemCode,
    required this.supplierCode,
    required this.quantityNeeded,
    this.status = CheckStatus.pending,
    this.quantityAvailable,
    this.shortageReason,
    this.suggestion,
    this.warehouseLocation,
    this.checkRowId,
  });

  StockCheckItem copyWith({
    CheckStatus? status,
    double? quantityAvailable,
    String? shortageReason,
    String? suggestion,
    String? warehouseLocation,
    int? checkRowId,
    bool clearQuantityAvailable = false,
    bool clearShortageReason    = false,
    bool clearSuggestion        = false,
  }) =>
      StockCheckItem(
        quotationItemId:   quotationItemId,
        productName:       productName,
        itemCode:          itemCode,
        supplierCode:      supplierCode,
        quantityNeeded:    quantityNeeded,
        status:            status ?? this.status,
        quantityAvailable: clearQuantityAvailable ? null : (quantityAvailable ?? this.quantityAvailable),
        shortageReason:    clearShortageReason    ? null : (shortageReason    ?? this.shortageReason),
        suggestion:        clearSuggestion        ? null : (suggestion        ?? this.suggestion),
        warehouseLocation: warehouseLocation ?? this.warehouseLocation,
        checkRowId:        checkRowId ?? this.checkRowId,
      );

  bool get isChecked => status != CheckStatus.pending;
}
