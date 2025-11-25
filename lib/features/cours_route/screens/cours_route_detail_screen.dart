// ?? Module : Cours de Route - Screens
// ?? Auteur : Valery Kalonga
// ?? Date : 2025-08-07
// ?? Description : Écran de détail d'un cours de route

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart'
    show refDataProvider, resolveName;
import 'package:ml_pp_mvp/shared/ui/format.dart';
import 'package:ml_pp_mvp/shared/ui/toast.dart';
import 'package:ml_pp_mvp/shared/ui/dialogs.dart';
import 'package:ml_pp_mvp/shared/ui/errors.dart';

// Nouveaux composants modernes
import 'package:ml_pp_mvp/shared/ui/modern_components/modern_detail_header.dart';
import 'package:ml_pp_mvp/shared/ui/modern_components/modern_status_timeline.dart';
import 'package:ml_pp_mvp/shared/ui/modern_components/modern_info_card.dart';
import 'package:ml_pp_mvp/shared/ui/modern_components/modern_action_card.dart';

/// Écran de détail d'un cours de route
///
/// Affiche toutes les informations d'un cours de route sélectionné.
/// Met l'accent sur la lisibilité et l'action (opérateur d'abord).
class CoursRouteDetailScreen extends ConsumerWidget {
  final String coursId;

  const CoursRouteDetailScreen({super.key, required this.coursId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursAsync = ref.watch(coursDeRouteByIdProvider(coursId));
    final userRole = ref.watch(userRoleProvider);

    debugPrint('?? CoursRouteDetailScreen: userRole=$userRole');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du cours'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) =>
                _handleMenuAction(context, ref, value, userRole),
            itemBuilder: (context) => _buildMenuItems(context, ref, userRole),
          ),
        ],
      ),
      body: coursAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(context, ref, error),
        data: (cours) => cours == null
            ? _buildNotFound(context)
            : _buildDetail(context, cours, ref, userRole),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Erreur lors du chargement',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(coursDeRouteByIdProvider(coursId)),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Cours non trouvé',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Le cours de route demandé n\'existe pas ou a été supprimé.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Retour à la liste'),
          ),
        ],
      ),
    );
  }

  /// Contenu principal
  Widget _buildDetail(
    BuildContext context,
    CoursDeRoute c,
    WidgetRef ref,
    UserRole? userRole,
  ) {
    final refDataAsync = ref.watch(refDataProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header moderne avec informations principales
              refDataAsync.when(
                loading: () => _buildHeaderLoading(c),
                error: (e, _) => _buildHeaderError(c, e),
                data: (refData) {
                  final four = resolveName(
                    refData,
                    c.fournisseurId,
                    'fournisseur',
                  );
                  return ModernDetailHeader(
                    title: 'Cours #${c.id.substring(0, 8)}',
                    subtitle: 'Détail du cours de route',
                    accentColor: _getStatutColor(c.statut),
                    statusWidget: _ModernStatutChip(statut: c.statut),
                    infoPills: [
                      InfoPill(
                        icon: Icons.business,
                        label: 'Fournisseur',
                        value: four,
                        color: Colors.indigo,
                      ),
                      InfoPill(
                        icon: Icons.local_gas_station,
                        label: 'Volume',
                        value: fmtVolume(c.volume),
                        color: Colors.blue,
                      ),
                      InfoPill(
                        icon: Icons.event,
                        label: 'Date',
                        value: fmtDate(c.dateChargement),
                        color: Colors.green,
                      ),
                      InfoPill(
                        icon: Icons.badge,
                        label: 'Camion',
                        value: c.plaqueCamion ?? '',
                        color: Colors.orange,
                      ),
                      if ((c.plaqueRemorque ?? '').isNotEmpty)
                        InfoPill(
                          icon: Icons.badge_outlined,
                          label: 'Remorque',
                          value: c.plaqueRemorque!,
                          color: Colors.purple,
                        ),
                    ],
                  );
                },
              ),

              // Timeline moderne des statuts
              ModernStatusTimeline(
                currentStatus: c.statut.name,
                accentColor: _getStatutColor(c.statut),
                steps: [
                  StatusStep(
                    status: StatutCours.chargement.name,
                    label: 'Chargement',
                    icon: Icons.upload,
                  ),
                  StatusStep(
                    status: StatutCours.transit.name,
                    label: 'Transit',
                    icon: Icons.local_shipping,
                  ),
                  StatusStep(
                    status: StatutCours.frontiere.name,
                    label: 'Frontière',
                    icon: Icons.border_clear,
                  ),
                  StatusStep(
                    status: StatutCours.arrive.name,
                    label: 'Arrivé',
                    icon: Icons.location_on,
                  ),
                  StatusStep(
                    status: StatutCours.decharge.name,
                    label: 'Déchargé',
                    icon: Icons.check_circle,
                  ),
                ],
              ),

              // Cartes d'information modernes
              refDataAsync.when(
                loading: () => _buildLoadingCard(),
                error: (e, _) => _buildErrorCard('Erreur référentiels: $e'),
                data: (refData) {
                  final prod = resolveName(refData, c.produitId, 'produit');
                  final dep = refData.depots[c.depotDestinationId] ?? '';

                  return Column(
                    children: [
                      // Informations logistiques (sans fournisseur car déjà dans le header)
                      ModernInfoCard(
                        title: 'Informations logistiques',
                        subtitle: 'Produit et destination',
                        icon: Icons.inventory_2_outlined,
                        accentColor: Colors.blue,
                        entries: [
                          InfoEntry(label: 'Produit', value: prod),
                          InfoEntry(label: 'Dépôt destination', value: dep),
                        ],
                      ),

                      // Informations transport
                      ModernInfoCard(
                        title: 'Informations transport',
                        subtitle: 'Transporteur, chauffeur et véhicule',
                        icon: Icons.local_shipping_outlined,
                        accentColor: Colors.green,
                        entries: [
                          InfoEntry(
                            label: 'Transporteur',
                            value: c.transporteur ?? '',
                          ),
                          InfoEntry(
                            label: 'Chauffeur',
                            value: c.chauffeur ?? '',
                          ),
                          InfoEntry(
                            label: 'Plaque camion',
                            value: c.plaqueCamion ?? '',
                          ),
                          InfoEntry(
                            label: 'Plaque remorque',
                            value: c.plaqueRemorque ?? '',
                          ),
                          InfoEntry(label: 'Pays', value: c.pays ?? ''),
                          InfoEntry(
                            label: 'Date de chargement',
                            value: fmtDate(c.dateChargement),
                          ),
                          InfoEntry(
                            label: 'Volume',
                            value: fmtVolume(c.volume),
                          ),
                        ],
                      ),

                      // Actions principales
                      ModernActionCard(
                        title: 'Actions',
                        subtitle: c.statut == StatutCours.decharge
                            ? 'Cours déchargé - Actions limitées'
                            : 'Modifier ou supprimer le cours',
                        icon: Icons.settings,
                        accentColor: Colors.orange,
                        actions: _buildActionButtons(context, ref, c, userRole),
                      ),

                      // Message informatif pour les cours déchargés
                      if (c.statut == StatutCours.decharge &&
                          userRole?.isAdmin != true)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.amber.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Ce cours a été déchargé. Seul un administrateur peut le modifier ou le supprimer.',
                                  style: TextStyle(
                                    color: Colors.amber.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Note si présente
                      if ((c.note ?? '').trim().isNotEmpty)
                        ModernInfoCard(
                          title: 'Note',
                          subtitle: 'Informations complémentaires',
                          icon: Icons.note_outlined,
                          accentColor: Colors.purple,
                          entries: [
                            InfoEntry(
                              label: 'Commentaire',
                              value: c.note!.trim(),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget de chargement pour le header
  Widget _buildHeaderLoading(CoursDeRoute c) {
    return ModernDetailHeader(
      title: 'Cours #${c.id.substring(0, 8)}',
      subtitle: 'Détail du cours de route',
      accentColor: _getStatutColor(c.statut),
      statusWidget: _ModernStatutChip(statut: c.statut),
      infoPills: [
        InfoPill(
          icon: Icons.local_gas_station,
          label: 'Volume',
          value: fmtVolume(c.volume),
          color: Colors.blue,
        ),
        InfoPill(
          icon: Icons.event,
          label: 'Date',
          value: fmtDate(c.dateChargement),
          color: Colors.green,
        ),
        InfoPill(
          icon: Icons.badge,
          label: 'Camion',
          value: c.plaqueCamion ?? '',
          color: Colors.orange,
        ),
        if ((c.plaqueRemorque ?? '').isNotEmpty)
          InfoPill(
            icon: Icons.badge_outlined,
            label: 'Remorque',
            value: c.plaqueRemorque!,
            color: Colors.purple,
          ),
      ],
    );
  }

  /// Widget d'erreur pour le header
  Widget _buildHeaderError(CoursDeRoute c, Object error) {
    return ModernDetailHeader(
      title: 'Cours #${c.id.substring(0, 8)}',
      subtitle: 'Détail du cours de route',
      accentColor: _getStatutColor(c.statut),
      statusWidget: _ModernStatutChip(statut: c.statut),
      infoPills: [
        InfoPill(
          icon: Icons.business,
          label: 'Fournisseur',
          value: 'Erreur chargement',
          color: Colors.red,
        ),
        InfoPill(
          icon: Icons.local_gas_station,
          label: 'Volume',
          value: fmtVolume(c.volume),
          color: Colors.blue,
        ),
        InfoPill(
          icon: Icons.event,
          label: 'Date',
          value: fmtDate(c.dateChargement),
          color: Colors.green,
        ),
        InfoPill(
          icon: Icons.badge,
          label: 'Camion',
          value: c.plaqueCamion ?? '',
          color: Colors.orange,
        ),
        if ((c.plaqueRemorque ?? '').isNotEmpty)
          InfoPill(
            icon: Icons.badge_outlined,
            label: 'Remorque',
            value: c.plaqueRemorque!,
            color: Colors.purple,
          ),
      ],
    );
  }

  /// Widget de chargement
  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  /// Widget d'erreur
  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: TextStyle(color: Colors.red.shade700)),
          ),
        ],
      ),
    );
  }

  /// Obtient la couleur associée au statut
  Color _getStatutColor(StatutCours statut) {
    switch (statut) {
      case StatutCours.chargement:
        return Colors.blue;
      case StatutCours.transit:
        return Colors.indigo;
      case StatutCours.frontiere:
        return Colors.amber;
      case StatutCours.arrive:
        return Colors.teal;
      case StatutCours.decharge:
        return Colors.grey;
      case StatutCours.inconnu:
      default:
        return Colors.grey.shade400;
    }
  }

  /// Construit les éléments du menu en fonction des permissions
  List<PopupMenuEntry<String>> _buildMenuItems(
    BuildContext context,
    WidgetRef ref,
    UserRole? userRole,
  ) {
    final coursAsync = ref.watch(coursDeRouteByIdProvider(coursId));

    return coursAsync.when(
      data: (cours) {
        if (cours == null) return [];

        final canEdit = _canEditCours(cours, userRole);
        final canDelete = _canDeleteCours(cours, userRole);

        final items = <PopupMenuEntry<String>>[];

        if (canEdit) {
          items.add(
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
          );
        }

        if (canDelete) {
          items.add(
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Supprimer', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          );
        }

        return items;
      },
      loading: () => [],
      error: (_, __) => [],
    );
  }

  /// Construit les boutons d'action en fonction des permissions
  List<ModernActionButton> _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    CoursDeRoute cours,
    UserRole? userRole,
  ) {
    final canEdit = _canEditCours(cours, userRole);
    final canDelete = _canDeleteCours(cours, userRole);

    final actions = <ModernActionButton>[];

    if (canEdit) {
      actions.add(
        ModernActionButton(
          label: 'Modifier',
          icon: Icons.edit,
          accentColor: Colors.blue,
          onPressed: () => context.push('/cours/${cours.id}/edit'),
        ),
      );
    } else {
      // Bouton désactivé
      actions.add(
        ModernActionButton(
          label: 'Modifier',
          icon: Icons.edit,
          accentColor: Colors.grey,
          onPressed: null,
        ),
      );
    }

    if (canDelete) {
      actions.add(
        ModernActionButton(
          label: 'Supprimer',
          icon: Icons.delete,
          isDanger: true,
          onPressed: () => _confirmDelete(context, ref, cours.id),
        ),
      );
    } else {
      // Bouton désactivé
      actions.add(
        ModernActionButton(
          label: 'Supprimer',
          icon: Icons.delete,
          isDanger: true,
          onPressed: null,
        ),
      );
    }

    return actions;
  }

  /// Vérifie si l'utilisateur peut modifier le cours
  bool _canEditCours(CoursDeRoute cours, UserRole? userRole) {
    // Fallback temporaire si userRole est null (pendant le chargement)
    final effectiveRole = userRole ?? UserRole.lecture;

    debugPrint(
      '?? _canEditCours: statut=${cours.statut.name}, userRole=$userRole, effectiveRole=$effectiveRole, isAdmin=${effectiveRole.isAdmin}',
    );

    // Si le cours est déchargé, seul un admin peut le modifier
    if (cours.statut == StatutCours.decharge) {
      final canEdit = effectiveRole.isAdmin;
      debugPrint('?? _canEditCours: cours déchargé, canEdit=$canEdit');
      return canEdit;
    }

    // Pour les autres statuts, tous les utilisateurs authentifiés peuvent modifier
    final canEdit = userRole != null;
    debugPrint('?? _canEditCours: cours non déchargé, canEdit=$canEdit');
    return canEdit;
  }

  /// Vérifie si l'utilisateur peut supprimer le cours
  bool _canDeleteCours(CoursDeRoute cours, UserRole? userRole) {
    // Fallback temporaire si userRole est null (pendant le chargement)
    final effectiveRole = userRole ?? UserRole.lecture;

    debugPrint(
      '?? _canDeleteCours: statut=${cours.statut.name}, userRole=$userRole, effectiveRole=$effectiveRole, isAdmin=${effectiveRole.isAdmin}',
    );

    // Si le cours est déchargé, seul un admin peut le supprimer
    if (cours.statut == StatutCours.decharge) {
      final canDelete = effectiveRole.isAdmin;
      debugPrint('?? _canDeleteCours: cours déchargé, canDelete=$canDelete');
      return canDelete;
    }

    // Pour les autres statuts, tous les utilisateurs authentifiés peuvent supprimer
    final canDelete = userRole != null;
    debugPrint('?? _canDeleteCours: cours non déchargé, canDelete=$canDelete');
    return canDelete;
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    UserRole? userRole,
  ) {
    switch (action) {
      case 'edit':
        context.push('/cours/$coursId/edit');
        break;
      case 'delete':
        _confirmDelete(context, ref, coursId);
        break;
    }
  }
}

/// Widget moderne pour afficher le chip de statut
class _ModernStatutChip extends StatelessWidget {
  final StatutCours statut;
  const _ModernStatutChip({required this.statut});

  @override
  Widget build(BuildContext context) {
    final color = _getStatutColor(statut);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_shipping, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            statut.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatutColor(StatutCours statut) {
    switch (statut) {
      case StatutCours.chargement:
        return Colors.blue;
      case StatutCours.transit:
        return Colors.indigo;
      case StatutCours.frontiere:
        return Colors.amber;
      case StatutCours.arrive:
        return Colors.teal;
      case StatutCours.decharge:
        return Colors.grey;
      case StatutCours.inconnu:
      default:
        return Colors.grey.shade400;
    }
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  String id,
) async {
  final ok = await confirmAction(
    context,
    title: 'Supprimer le cours ?',
    message: 'Cette action est irréversible.',
    confirmLabel: 'Supprimer',
    danger: true,
  );
  if (!ok) return;
  try {
    await ref.read(coursDeRouteServiceProvider).delete(id);
    if (context.mounted) {
      showAppToast(context, 'Cours supprimé', type: ToastType.success);
      context.go('/cours');
    }
  } catch (e) {
    if (context.mounted) {
      showAppToast(context, humanizePostgrest(e), type: ToastType.error);
    }
  }
}

