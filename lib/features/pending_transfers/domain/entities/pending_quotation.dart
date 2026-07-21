enum DeliveryType {
  inside,
  outside,
  none;

  static DeliveryType fromDb(String? value) => switch (value) {
        'inside'  => DeliveryType.inside,
        'outside' => DeliveryType.outside,
        _         => DeliveryType.none,
      };

  String get dbValue => switch (this) {
        DeliveryType.inside  => 'inside',
        DeliveryType.outside => 'outside',
        DeliveryType.none    => 'none',
      };

  String get label => switch (this) {
        DeliveryType.inside  => 'Inside Delivery',
        DeliveryType.outside => 'Outside Delivery',
        DeliveryType.none    => 'No Delivery',
      };
}

class PendingQuotation {
  final int id;
  final String quoteNo;
  final String customerName;
  final String companyName;
  final String customerPhone;
  final String salespersonName;
  final double netTotal;
  final DateTime createdAt;
  final int itemCount;
  final DeliveryType deliveryType;
  /// Marked urgent by the salesperson when sending — red badge, listed first.
  final bool urgent;

  const PendingQuotation({
    required this.id,
    required this.quoteNo,
    required this.customerName,
    required this.companyName,
    required this.customerPhone,
    required this.salespersonName,
    required this.netTotal,
    required this.createdAt,
    required this.itemCount,
    this.deliveryType = DeliveryType.none,
    this.urgent = false,
  });

  factory PendingQuotation.fromMap(Map<String, dynamic> map) {
    final items = map['quotation_items'] as List? ?? [];
    return PendingQuotation(
      id: (map['id'] as num).toInt(),
      quoteNo: map['quote_no'] as String? ?? '',
      customerName: map['customer_name'] as String? ?? '',
      companyName: map['company_name'] as String? ?? '',
      customerPhone: map['customer_phone'] as String? ?? '',
      salespersonName: map['salesperson_name'] as String? ?? '',
      netTotal: double.tryParse(map['net_total']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      itemCount: items.length,
      deliveryType: DeliveryType.fromDb(map['delivery_type'] as String?),
      urgent: map['transfer_urgent'] == true,
    );
  }
}
