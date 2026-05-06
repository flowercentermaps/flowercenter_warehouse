class WarehouseUser {
  final String id;
  final String email;
  final String name;
  final String role;

  const WarehouseUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  bool get isWarehouseManager => role == 'warehouse_manager';
}
