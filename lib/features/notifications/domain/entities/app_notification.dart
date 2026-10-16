import 'package:equatable/equatable.dart';

enum NotificationCategory {
  overdue,
  dueSoon,
  payment,
  debt,
  legacy,
  system,
}

class AppNotification extends Equatable {
  final String id;
  final String title;
  final String message;
  final NotificationCategory category;
  final DateTime timestamp;
  final bool isRead;
  final String? actionRoute;
  final Map<String, dynamic>? actionData;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.actionRoute,
    this.actionData,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationCategory? category,
    DateTime? timestamp,
    bool? isRead,
    String? actionRoute,
    Map<String, dynamic>? actionData,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute ?? this.actionRoute,
      actionData: actionData ?? this.actionData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category.name,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'actionRoute': actionRoute,
      'actionData': actionData,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    NotificationCategory parseCategory(String? cat) {
      if (cat == null) return NotificationCategory.system;
      final clean = cat.replaceAll('_', '').toLowerCase();
      return NotificationCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == clean,
        orElse: () => NotificationCategory.system,
      );
    }

    final rawTime = map['created_at'] ?? map['timestamp'];
    final parsedTime = rawTime != null
        ? DateTime.tryParse(rawTime.toString()) ?? DateTime.now()
        : DateTime.now();

    final bool isRead = map['is_read'] == true ||
        map['is_read'] == 1 ||
        map['isRead'] == true ||
        map['read_at'] != null;

    final actionRoute = (map['action_route'] ?? map['actionRoute']) as String?;
    final rawData = map['action_data'] ?? map['actionData'];
    final actionData = rawData != null ? Map<String, dynamic>.from(rawData as Map) : null;

    return AppNotification(
      id: map['id']?.toString() ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      category: parseCategory(map['category'] as String?),
      timestamp: parsedTime,
      isRead: isRead,
      actionRoute: actionRoute,
      actionData: actionData,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        category,
        timestamp,
        isRead,
        actionRoute,
        actionData,
      ];
}
