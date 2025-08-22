import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as Riverpod;
import 'package:ml_pp_mvp/core/models/user_role.dart';

class MenuDestination {
  final String label;
  final IconData icon;
  final String route;
  final List<UserRole> visibleForRoles;
  final int order;

  const MenuDestination({
    required this.label,
    required this.icon,
    required this.route,
    required this.visibleForRoles,
    required this.order,
  });
}

const List<MenuDestination> _allDestinations = [
  MenuDestination(
    label: 'Admin',
    icon: Icons.dashboard,
    route: '/dashboard/admin',
    visibleForRoles: [UserRole.admin],
    order: 0,
  ),
  MenuDestination(
    label: 'Directeur',
    icon: Icons.leaderboard,
    route: '/dashboard/directeur',
    visibleForRoles: [UserRole.directeur],
    order: 0,
  ),
  MenuDestination(
    label: 'Gérant',
    icon: Icons.manage_accounts,
    route: '/dashboard/gerant',
    visibleForRoles: [UserRole.gerant],
    order: 0,
  ),
  MenuDestination(
    label: 'Opérateur',
    icon: Icons.build,
    route: '/dashboard/operateur',
    visibleForRoles: [UserRole.operateur],
    order: 0,
  ),
  MenuDestination(
    label: 'Lecture',
    icon: Icons.visibility,
    route: '/dashboard/lecture',
    visibleForRoles: [UserRole.lecture],
    order: 0,
  ),
  MenuDestination(
    label: 'PCA',
    icon: Icons.account_balance,
    route: '/dashboard/pca',
    visibleForRoles: [UserRole.pca],
    order: 0,
  ),
  MenuDestination(
    label: 'Cours',
    icon: Icons.local_shipping,
    route: '/cours',
    visibleForRoles: [UserRole.admin, UserRole.directeur, UserRole.gerant, UserRole.operateur, UserRole.lecture, UserRole.pca],
    order: 9,
  ),
  // Commun modules
  MenuDestination(
    label: 'Stocks',
    icon: Icons.inventory_2,
    route: '/stocks',
    visibleForRoles: [UserRole.admin, UserRole.directeur, UserRole.gerant, UserRole.operateur, UserRole.lecture, UserRole.pca],
    order: 10,
  ),
  MenuDestination(
    label: 'Citernes',
    icon: Icons.local_gas_station,
    route: '/citernes',
    visibleForRoles: [UserRole.admin, UserRole.gerant, UserRole.operateur, UserRole.lecture],
    order: 11,
  ),
  MenuDestination(
    label: 'Réceptions',
    icon: Icons.call_received,
    route: '/receptions',
    visibleForRoles: [UserRole.admin, UserRole.gerant, UserRole.operateur, UserRole.lecture],
    order: 12,
  ),
  MenuDestination(
    label: 'Sorties',
    icon: Icons.call_made,
    route: '/sorties',
    visibleForRoles: [UserRole.admin, UserRole.gerant, UserRole.operateur, UserRole.lecture],
    order: 13,
  ),
  MenuDestination(
    label: 'Logs',
    icon: Icons.list_alt,
    route: '/logs',
    visibleForRoles: [UserRole.admin, UserRole.directeur, UserRole.pca],
    order: 20,
  ),
];

final menuDestinationsForRoleProvider = Riverpod.Provider.family<List<MenuDestination>, UserRole?>((ref, role) {
  if (role == null) {
    return const [];
  }
  final list = _allDestinations.where((d) => d.visibleForRoles.contains(role)).toList();
  list.sort((a, b) => a.order.compareTo(b.order));
  return list;
});

