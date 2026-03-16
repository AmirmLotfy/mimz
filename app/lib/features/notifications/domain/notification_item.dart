enum NotificationType { event, reward, squad, system }

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? route;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.route,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      type: type,
      isRead: isRead ?? this.isRead,
      route: route,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] as String? ?? 'system').toLowerCase();
    final type = NotificationType.values.firstWhere(
      (value) => value.name == rawType,
      orElse: () => NotificationType.system,
    );
    final createdAt = json['createdAt'] as String?;
    return NotificationItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Notification',
      message: json['body'] as String? ?? json['message'] as String? ?? '',
      timestamp: DateTime.tryParse(createdAt ?? '') ?? DateTime.now(),
      type: type,
      isRead: json['read'] == true || json['isRead'] == true,
      route: switch (type) {
        NotificationType.event => '/events',
        NotificationType.reward => '/rewards',
        NotificationType.squad => '/squad',
        NotificationType.system => null,
      },
    );
  }
}
