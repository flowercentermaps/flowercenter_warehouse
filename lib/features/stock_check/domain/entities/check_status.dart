enum CheckStatus {
  pending,
  available,
  partial,
  outOfStock;

  String get dbValue => switch (this) {
        CheckStatus.pending     => 'pending',
        CheckStatus.available   => 'available',
        CheckStatus.partial     => 'partial',
        CheckStatus.outOfStock  => 'out_of_stock',
      };

  static CheckStatus fromDb(String? value) => switch (value) {
        'available'   => CheckStatus.available,
        'partial'     => CheckStatus.partial,
        'out_of_stock' => CheckStatus.outOfStock,
        _             => CheckStatus.pending,
      };

  String get label => switch (this) {
        CheckStatus.pending    => 'Pending',
        CheckStatus.available  => 'Available',
        CheckStatus.partial    => 'Partial',
        CheckStatus.outOfStock => 'Out of Stock',
      };
}
