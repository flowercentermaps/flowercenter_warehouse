class PendingQuotation {
  final int id;
  final String quoteNo;
  final String customerName;
  final String companyName;
  final double netTotal;
  final DateTime createdAt;
  final int itemCount;

  const PendingQuotation({
    required this.id,
    required this.quoteNo,
    required this.customerName,
    required this.companyName,
    required this.netTotal,
    required this.createdAt,
    required this.itemCount,
  });

  factory PendingQuotation.fromMap(Map<String, dynamic> map) {
    final items = map['quotation_items'] as List? ?? [];
    return PendingQuotation(
      id: (map['id'] as num).toInt(),
      quoteNo: map['quote_no'] as String? ?? '',
      customerName: map['customer_name'] as String? ?? '',
      companyName: map['company_name'] as String? ?? '',
      netTotal: double.tryParse(map['net_total']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      itemCount: items.length,
    );
  }
}
