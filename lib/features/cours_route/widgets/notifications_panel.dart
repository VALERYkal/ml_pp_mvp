// 📌 Module : Cours de Route - Widgets
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Panneau de notifications pour les cours de route

import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/features/cours_route/services/notification_service.dart';

/// Panneau de notifications
class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel({super.key});

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  List<CoursNotification> _notifications = [];
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    CoursNotificationService.addListener(_onNotificationAdded);
  }

  @override
  void dispose() {
    CoursNotificationService.removeListener(_onNotificationAdded);
    super.dispose();
  }

  void _loadNotifications() {
    setState(() {
      _notifications = _showUnreadOnly
          ? CoursNotificationService.getUnreadNotifications()
          : CoursNotificationService.getAllNotifications();
    });
  }

  void _onNotificationAdded(CoursNotification notification) {
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = CoursNotificationService.getUnreadCount();

    return Column(
      children: [
        // En-tête
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.notifications,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Notifications',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              // Filtre
              IconButton(
                onPressed: () {
                  setState(() {
                    _showUnreadOnly = !_showUnreadOnly;
                  });
                  _loadNotifications();
                },
                icon: Icon(
                  _showUnreadOnly ? Icons.visibility : Icons.visibility_off,
                ),
                tooltip: _showUnreadOnly
                    ? 'Voir toutes'
                    : 'Voir non lues seulement',
              ),
              // Actions
              PopupMenuButton<String>(
                onSelected: _handleAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mark_all_read',
                    child: ListTile(
                      leading: Icon(Icons.done_all),
                      title: Text('Marquer tout comme lu'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: ListTile(
                      leading: Icon(Icons.clear_all),
                      title: Text('Supprimer toutes'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const Divider(height: 1),

        // Liste des notifications
        Expanded(
          child: _notifications.isEmpty
              ? _EmptyState(showUnreadOnly: _showUnreadOnly)
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return NotificationWidget(
                      notification: notification,
                      onTap: () => _handleNotificationTap(notification),
                      onDismiss: () => _handleNotificationDismiss(notification),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _handleAction(String action) {
    switch (action) {
      case 'mark_all_read':
        CoursNotificationService.markAllAsRead();
        _loadNotifications();
        break;
      case 'clear_all':
        _showClearConfirmation();
        break;
    }
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer toutes les notifications'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer toutes les notifications ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              CoursNotificationService.clearAllNotifications();
              _loadNotifications();
              Navigator.of(context).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(CoursNotification notification) {
    if (!notification.isRead) {
      CoursNotificationService.markAsRead(notification.id);
      _loadNotifications();
    }

    // Navigation vers le cours si applicable
    if (notification.coursId != null) {
      // context.go('/cours/${notification.coursId}');
    }
  }

  void _handleNotificationDismiss(CoursNotification notification) {
    CoursNotificationService.removeNotification(notification.id);
    _loadNotifications();
  }
}

/// État vide
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.showUnreadOnly});

  final bool showUnreadOnly;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            showUnreadOnly ? Icons.mark_email_read : Icons.notifications_none,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            showUnreadOnly
                ? 'Aucune notification non lue'
                : 'Aucune notification',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            showUnreadOnly
                ? 'Toutes vos notifications ont été lues'
                : 'Vous n\'avez pas encore de notifications',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Bouton de notification avec badge
class NotificationButton extends StatefulWidget {
  const NotificationButton({super.key});

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _updateUnreadCount();
    CoursNotificationService.addListener(_onNotificationAdded);
  }

  @override
  void dispose() {
    CoursNotificationService.removeListener(_onNotificationAdded);
    super.dispose();
  }

  void _updateUnreadCount() {
    setState(() {
      _unreadCount = CoursNotificationService.getUnreadCount();
    });
  }

  void _onNotificationAdded(CoursNotification notification) {
    _updateUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: () => _showNotificationsPanel(context),
          icon: const Icon(Icons.notifications),
          tooltip: 'Notifications',
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onError,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  void _showNotificationsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: const NotificationsPanel(),
      ),
    );
  }
}
