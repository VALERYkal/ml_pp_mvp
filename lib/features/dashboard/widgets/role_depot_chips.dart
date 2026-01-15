import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/core/config/app_env.dart';

/// Widget responsive affichant les chips ENV, Rôle et Dépôt
/// 
/// Utilise Wrap pour éviter les overflows sur mobile
/// et permettre le retour à la ligne automatique
class RoleDepotChips extends ConsumerWidget {
  final UserRole role;
  final String depotName;

  const RoleDepotChips({
    super.key,
    required this.role,
    required this.depotName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appEnv = ref.watch(appEnvSyncProvider);
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Badge ENV (PROD/STAGING/DEV)
        _buildEnvBadge(context, appEnv.envName),
        
        // Chip Rôle
        Chip(
          label: Text(role.value),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        
        // Chip Dépôt
        InputChip(
          label: Text(depotName),
          avatar: const Icon(Icons.home_work, size: 18),
        ),
      ],
    );
  }
  
  /// Badge ENV avec couleur selon environnement
  Widget _buildEnvBadge(BuildContext context, String envName) {
    Color backgroundColor;
    Color textColor;
    
    switch (envName) {
      case 'PROD':
        backgroundColor = Colors.red;
        textColor = Colors.white;
        break;
      case 'STAGING':
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        break;
      case 'DEV':
      default:
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        envName,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
