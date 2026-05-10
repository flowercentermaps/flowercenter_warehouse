import 'package:local_notifier/local_notifier.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  Future<void> init() async {
    await localNotifier.setup(
      appName: 'Flower Center Warehouse',
    );
  }

  Future<void> showNewRequestNotification({
    required int id,
    required String quoteNo,
    String? customerName,
  }) async {
    final body = [
      'Quotation $quoteNo',
      if (customerName != null && customerName.isNotEmpty) customerName,
      'requires stock verification.',
    ].join(' — ');

    final notification = LocalNotification(
      identifier: 'quotation_$id',
      title: 'New Stock Check Request',
      body: body,
    );
    await notification.show();
  }
}
