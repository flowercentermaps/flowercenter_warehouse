class StoreAllocation {
  final String storeName;
  final double qty;

  const StoreAllocation({required this.storeName, required this.qty});

  StoreAllocation copyWith({String? storeName, double? qty}) => StoreAllocation(
        storeName: storeName ?? this.storeName,
        qty: qty ?? this.qty,
      );

  Map<String, dynamic> toJson() => {'store': storeName, 'qty': qty};

  factory StoreAllocation.fromJson(Map<String, dynamic> json) => StoreAllocation(
        storeName: (json['store'] ?? '').toString(),
        qty: (json['qty'] as num?)?.toDouble() ?? 0,
      );
}
