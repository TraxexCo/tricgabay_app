enum NotificationType { booking, driver, promo, system }

class NotificationItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime time;
  final NotificationType type;
  bool isRead;
  final String? routePath;

  NotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    this.isRead = false,
    this.routePath,
  });
}
