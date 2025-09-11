import 'package:flutter/material.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';

// Liste centralisée des rôles opérationnels (tous sauf admin et pca)
const kOpsRoles = <UserRole>[
  UserRole.admin,
  UserRole.directeur, // <- AJOUT
  UserRole.gerant,
  UserRole.operateur,
  UserRole.lecture,
];

// Liste de tous les rôles
const kAllRoles = <UserRole>[
  UserRole.admin,
  UserRole.directeur,
  UserRole.gerant,
  UserRole.operateur,
  UserRole.pca,       // <- AJOUT
  UserRole.lecture,   // <- déjà présent mais on centralise
];

class NavItem {
  final String id;
  final String title;
  final String path;           // chemin "générique"
  final IconData icon;
  final List<UserRole> allowedRoles;
  final int order;
  final bool isDashboard;      // si true, le chemin effectif dépend du rôle

  const NavItem({
    required this.id,
    required this.title,
    required this.path,
    required this.icon,
    this.allowedRoles = const [],
    this.order = 0,
    this.isDashboard = false,
  });

  bool isAllowedFor(UserRole? role) =>
      allowedRoles.isEmpty || (role != null && allowedRoles.contains(role));
}

/// Résout le chemin "effectif" (ex. /dashboard/admin) pour un item
String effectivePath(NavItem it, UserRole? role) =>
    it.isDashboard && role != null ? role.dashboardPath : it.path;

class NavConfig {
  static const List<NavItem> _allItems = [
    NavItem(
      id: 'dashboard',
      title: 'Tableau de bord',
      path: '/dashboard',                 // remplacé dynamiquement selon le rôle
      icon: Icons.space_dashboard_outlined,
      isDashboard: true,
      order: 0,
    ),
    NavItem(
      id: 'receptions',
      title: 'Réceptions',
      path: '/receptions',
      icon: Icons.move_to_inbox_outlined,
      allowedRoles: kAllRoles,
      order: 1,
    ),
    NavItem(
      id: 'sorties',
      title: 'Sorties',
      path: '/sorties',
      icon: Icons.outbox_outlined,
      allowedRoles: kAllRoles,
      order: 2,
    ),
    NavItem(
      id: 'stocks',
      title: 'Stocks',
      path: '/stocks',
      icon: Icons.inventory_2_outlined,
      allowedRoles: kAllRoles,
      order: 3,
    ),
    NavItem(
      id: 'citernes',
      title: 'Citernes',
      path: '/citernes',
      icon: Icons.local_gas_station_outlined,
      allowedRoles: kAllRoles,
      order: 4,
    ),
    NavItem(
      id: 'cours',
      title: 'Cours de route',
      path: '/cours',
      icon: Icons.local_shipping_outlined,
      allowedRoles: kAllRoles,
      order: 5,
    ),
    NavItem(
      id: 'logs',
      title: 'Logs / Audit',
      path: '/logs',
      icon: Icons.list_alt_outlined,
      allowedRoles: kAllRoles,
      order: 6,
    ),
  ];

  static List<NavItem> getItemsForRole(UserRole? role) {
    final items = _allItems.where((i) => i.isAllowedFor(role)).toList();
    items.sort((a, b) => a.order.compareTo(b.order));
    return items;
  }

  static String getPageTitle(String location, UserRole? role) {
    for (final item in _allItems) {
      final p = effectivePath(item, role);
      if (location.startsWith(p)) return item.title;
    }
    return 'Tableau de bord';
  }
}
