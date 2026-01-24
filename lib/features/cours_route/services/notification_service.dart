// 📌 Module : Cours de Route - Services
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Service de notifications pour les cours de route

import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';

/// Types de notifications
enum NotificationType {
  statusChange,
  newCours,
  overdueCours,
  volumeAlert,
  systemAlert,
}

/// Priorité des notifications
enum NotificationPriority { low, medium, high, critical }

/// Modèle de notification
class CoursNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final String? coursId;
  final Map<String, dynamic>? data;
  final bool isRead;

  const CoursNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.timestamp,
    this.coursId,
    this.data,
    this.isRead = false,
  });

  CoursNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? timestamp,
    String? coursId,
    Map<String, dynamic>? data,
    bool? isRead,
  }) {
    return CoursNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      coursId: coursId ?? this.coursId,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Service de notifications
class CoursNotificationService {
  static final List<CoursNotification> _notifications = [];
  static final List<Function(CoursNotification)> _listeners = [];

  /// Ajouter un listener pour les nouvelles notifications
  static void addListener(Function(CoursNotification) listener) {
    _listeners.add(listener);
  }

  /// Supprimer un listener
  static void removeListener(Function(CoursNotification) listener) {
    _listeners.remove(listener);
  }

  /// Créer une notification
  static CoursNotification createNotification({
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.medium,
    String? coursId,
    Map<String, dynamic>? data,
  }) {
    final notification = CoursNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      priority: priority,
      timestamp: DateTime.now(),
      coursId: coursId,
      data: data,
    );

    _notifications.insert(0, notification);
    _notifyListeners(notification);
    return notification;
  }

  /// Notifier les listeners
  static void _notifyListeners(CoursNotification notification) {
    for (final listener in _listeners) {
      listener(notification);
    }
  }

  /// Marquer une notification comme lue
  static void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  /// Marquer toutes les notifications comme lues
  static void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  /// Supprimer une notification
  static void removeNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
  }

  /// Supprimer toutes les notifications
  static void clearAllNotifications() {
    _notifications.clear();
  }

  /// Obtenir toutes les notifications
  static List<CoursNotification> getAllNotifications() {
    return List.unmodifiable(_notifications);
  }

  /// Obtenir les notifications non lues
  static List<CoursNotification> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  /// Obtenir le nombre de notifications non lues
  static int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  /// Créer une notification de changement de statut
  static CoursNotification createStatusChangeNotification({
    required CoursDeRoute cours,
    required StatutCours oldStatus,
    required StatutCours newStatus,
  }) {
    return createNotification(
      title: 'Statut mis à jour',
      message:
          'Le cours ${cours.id} est passé de ${oldStatus.label} à ${newStatus.label}',
      type: NotificationType.statusChange,
      priority: NotificationPriority.medium,
      coursId: cours.id,
      data: {
        'oldStatus': oldStatus.name,
        'newStatus': newStatus.name,
        'coursId': cours.id,
      },
    );
  }

  /// Créer une notification de nouveau cours
  static CoursNotification createNewCoursNotification({
    required CoursDeRoute cours,
  }) {
    return createNotification(
      title: 'Nouveau cours de route',
      message: 'Un nouveau cours a été créé pour ${cours.fournisseurId}',
      type: NotificationType.newCours,
      priority: NotificationPriority.high,
      coursId: cours.id,
      data: {
        'coursId': cours.id,
        'fournisseurId': cours.fournisseurId,
        'volume': cours.volume,
      },
    );
  }

  /// Créer une notification de cours en retard
  static CoursNotification createOverdueCoursNotification({
    required CoursDeRoute cours,
    required int daysOverdue,
  }) {
    return createNotification(
      title: 'Cours en retard',
      message: 'Le cours ${cours.id} est en retard de $daysOverdue jours',
      type: NotificationType.overdueCours,
      priority: NotificationPriority.critical,
      coursId: cours.id,
      data: {
        'coursId': cours.id,
        'daysOverdue': daysOverdue,
        'statut': cours.statut.name,
      },
    );
  }

  /// Créer une notification d'alerte de volume
  static CoursNotification createVolumeAlertNotification({
    required CoursDeRoute cours,
    required double threshold,
  }) {
    return createNotification(
      title: 'Alerte de volume',
      message: 'Le cours ${cours.id} dépasse le seuil de ${threshold}L',
      type: NotificationType.volumeAlert,
      priority: NotificationPriority.medium,
      coursId: cours.id,
      data: {
        'coursId': cours.id,
        'volume': cours.volume,
        'threshold': threshold,
      },
    );
  }

  /// Créer une notification système
  static CoursNotification createSystemNotification({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.low,
  }) {
    return createNotification(
      title: title,
      message: message,
      type: NotificationType.systemAlert,
      priority: priority,
    );
  }
}

/// Widget de notification
class NotificationWidget extends StatelessWidget {
  const NotificationWidget({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  final CoursNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final color = _getNotificationColor(notification.priority);
    final icon = _getNotificationIcon(notification.type);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          notification.title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              iconSize: 16,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getNotificationColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.medium:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.critical:
        return Colors.red;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.statusChange:
        return Icons.swap_horiz;
      case NotificationType.newCours:
        return Icons.add_circle;
      case NotificationType.overdueCours:
        return Icons.warning;
      case NotificationType.volumeAlert:
        return Icons.local_shipping;
      case NotificationType.systemAlert:
        return Icons.info;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }
}
