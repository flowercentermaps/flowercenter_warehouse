import 'check_status.dart';
import 'store_allocation.dart';

class StockCheckItem {
  final int quotationItemId;
  final String productName;
  final String itemCode;
  final String supplierCode;
  final double quantityNeeded;

  /// True when product_type == 'tree'. Trees appear in the stock check but
  /// can be marked available without a store location.
  final bool isTree;

  /// Article code from price_list_items.article_code_id
  final String? articleCodeId;

  final String? imageUrl;
  final String? barcode;

  // Mutable check fields
  CheckStatus status;
  double? quantityAvailable;
  String? shortageReason;
  String? suggestion;
  List<StoreAllocation> storeAllocations;

  /// DB row ID in quotation_stock_checks (null if not yet saved)
  int? checkRowId;

  StockCheckItem({
    required this.quotationItemId,
    required this.productName,
    required this.itemCode,
    required this.supplierCode,
    required this.quantityNeeded,
    this.isTree = false,
    this.articleCodeId,
    this.imageUrl,
    this.barcode,
    this.status = CheckStatus.pending,
    this.quantityAvailable,
    this.shortageReason,
    this.suggestion,
    this.storeAllocations = const [],
    this.checkRowId,
  });

  /// Sum of all allocation quantities.
  double get totalAllocated =>
      storeAllocations.fold(0.0, (s, a) => s + a.qty);

  /// Derived display string for warehouse/store location.
  /// Returns null when no allocations exist.
  String? get warehouseLocation {
    if (storeAllocations.isEmpty) return null;
    return storeAllocations
        .map((a) => '${a.storeName} (${a.qty == a.qty.roundToDouble() ? a.qty.toInt() : a.qty.toStringAsFixed(1)})')
        .join('\n');
  }

  StockCheckItem copyWith({
    CheckStatus? status,
    double? quantityAvailable,
    String? shortageReason,
    String? suggestion,
    List<StoreAllocation>? storeAllocations,
    int? checkRowId,
    bool clearQuantityAvailable = false,
    bool clearShortageReason    = false,
    bool clearSuggestion        = false,
    bool clearStoreAllocations  = false,
  }) =>
      StockCheckItem(
        quotationItemId:   quotationItemId,
        productName:       productName,
        itemCode:          itemCode,
        supplierCode:      supplierCode,
        quantityNeeded:    quantityNeeded,
        isTree:            isTree,
        articleCodeId:     articleCodeId,
        imageUrl:          imageUrl,
        barcode:           barcode,
        status:            status ?? this.status,
        quantityAvailable: clearQuantityAvailable ? null : (quantityAvailable ?? this.quantityAvailable),
        shortageReason:    clearShortageReason    ? null : (shortageReason    ?? this.shortageReason),
        suggestion:        clearSuggestion        ? null : (suggestion        ?? this.suggestion),
        storeAllocations:  clearStoreAllocations  ? const [] : (storeAllocations ?? this.storeAllocations),
        checkRowId:        checkRowId ?? this.checkRowId,
      );

  bool get isChecked => status != CheckStatus.pending;

  Map<String, dynamic> toMap() {
    return {
      'quotationItemId': quotationItemId,
      'productName': productName,
      'itemCode': itemCode,
      'supplierCode': supplierCode,
      'articleCodeId': articleCodeId,
      'quantityNeeded': quantityNeeded,
      'status': status.name,
      'quantityAvailable': quantityAvailable,
      'shortageReason': shortageReason,
      'suggestion': suggestion,
      'storeAllocations': storeAllocations.map((a) => a.toJson()).toList(),
      'warehouseLocation': warehouseLocation,
      'checkRowId': checkRowId,
      'isChecked': isChecked,
    };
  }

  void printDetails() {
    toMap().forEach((key, value) {
      print('$key: $value');
    });
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
