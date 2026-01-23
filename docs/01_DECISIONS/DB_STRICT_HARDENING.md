# Guide Hardening & Observabilité — DB-STRICT

**Phase** : Phase 4  
**Statut** : ⚪ À faire  
**Objectif** : Finaliser la robustesse et la traçabilité

---

## Vue d'ensemble

Cette phase consiste à **finaliser** l'implémentation DB-STRICT en ajoutant :
1. Codes d'erreur DB stables (pour mapping UI)
2. Documentation mise à jour
3. Changelog
4. Optionnel : endpoints admin UI pour compensation

---

## 1. Codes d'erreur DB stables

### Mapping des erreurs SQL → Messages UI

**Fichier** : `lib/core/errors/db_strict_errors.dart`

```dart
/// Codes d'erreur DB-STRICT standardisés
class DbStrictErrorCodes {
  // Immutabilité
  static const String immutableTransaction = 'IMMUTABLE_TRANSACTION';
  static const String unauthorized = 'UNAUTHORIZED';
  static const String authRequired = 'AUTH_REQUIRED';
  
  // Compensation
  static const String invalidReason = 'INVALID_REASON';
  static const String receptionNotFound = 'RECEPTION_NOT_FOUND';
  static const String sortieNotFound = 'SORTIE_NOT_FOUND';
  static const String invalidStatus = 'INVALID_STATUS';
  static const String invalidVolume = 'INVALID_VOLUME';
  static const String invalidVolume15c = 'INVALID_VOLUME_15C';
}

/// Mapper les erreurs SQL vers des messages utilisateur
String mapDbStrictErrorToUserMessage(String? errorMessage) {
  if (errorMessage == null) {
    return 'Erreur lors de l\'opération';
  }

  if (errorMessage.contains('IMMUTABLE_TRANSACTION')) {
    return 'Cette transaction ne peut pas être modifiée. Utilisez une compensation administrative.';
  } else if (errorMessage.contains('UNAUTHORIZED')) {
    return 'Vous n\'êtes pas autorisé à effectuer cette opération.';
  } else if (errorMessage.contains('AUTH_REQUIRED')) {
    return 'Authentification requise pour cette opération.';
  } else if (errorMessage.contains('INVALID_REASON')) {
    return 'La raison doit contenir au moins 10 caractères.';
  } else if (errorMessage.contains('RECEPTION_NOT_FOUND')) {
    return 'Réception introuvable.';
  } else if (errorMessage.contains('SORTIE_NOT_FOUND')) {
    return 'Sortie introuvable.';
  } else if (errorMessage.contains('INVALID_STATUS')) {
    return 'Seules les transactions validées peuvent être compensées.';
  } else if (errorMessage.contains('INVALID_VOLUME')) {
    return 'Le volume de la transaction est invalide.';
  } else if (errorMessage.contains('INVALID_VOLUME_15C')) {
    return 'Le volume à 15°C est invalide.';
  }

  return errorMessage;
}
```

---

## 2. Documentation mise à jour

### Mettre à jour les fichiers suivants

- [ ] `docs/db/receptions.md` → Ajouter section DB-STRICT
- [ ] `docs/db/sorties_mvp.md` → Ajouter section DB-STRICT
- [ ] `docs/architecture.md` → Ajouter section DB-STRICT
- [ ] `README.md` → Mentionner le paradigme DB-STRICT

**Exemple pour `docs/db/receptions.md`** :

```markdown
## DB-STRICT (depuis 2025-12-21)

Les réceptions sont **immuables** une fois créées :
- ✅ INSERT = validation automatique (pas de brouillon)
- ❌ UPDATE/DELETE bloqués par trigger
- ✅ Corrections uniquement via `stock_adjustments`

Voir [Transaction Contract](../../TRANSACTION_CONTRACT.md) pour les détails.
```

---

## 3. Changelog

**Fichier** : `CHANGELOG.md`

Ajouter une entrée :

```markdown
## [2.1.0] - 2025-12-21

### 🚀 DB-STRICT Migration

#### Réceptions & Sorties
- ✅ **Immutabilité absolue** : UPDATE/DELETE bloqués par trigger
- ✅ **Compensation administrative** : table `stock_adjustments` pour corrections
- ✅ **Sécurité renforcée** : RLS + SECURITY DEFINER maîtrisé
- ✅ **Traçabilité totale** : logs CRITICAL pour toutes compensations

#### Breaking Changes
- ❌ Suppression de `createDraft()` et `validate()` (réceptions)
- ❌ Suppression de `SortieDraftService`
- ❌ Suppression des RPC `validate_reception` et `validate_sortie`

#### Migration
- Les réceptions et sorties sont maintenant **immuables** une fois créées
- Les corrections se font via `admin_compensate_reception()` et `admin_compensate_sortie()`
- Voir [Transaction Contract](docs/TRANSACTION_CONTRACT.md) pour les détails

#### Documentation
- [Transaction Contract](docs/TRANSACTION_CONTRACT.md)
- [Guide Migration SQL](docs/db/DB_STRICT_MIGRATION_SQL.md)
- [Guide Nettoyage Code](docs/DB_STRICT_CLEANUP_CODE.md)
```

---

## 4. Endpoints admin UI pour compensation (optionnel)

**Fichier** : `lib/features/admin/services/compensation_service.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class CompensationService {
  final SupabaseClient client;

  CompensationService(this.client);

  /// Compenser une réception erronée
  Future<String> compensateReception({
    required String receptionId,
    required String reason,
  }) async {
    try {
      final result = await client.rpc(
        'admin_compensate_reception',
        params: {
          'p_reception_id': receptionId,
          'p_reason': reason,
        },
      );
      
      return result as String; // adjustment_id
    } on PostgrestException catch (e) {
      throw CompensationException(
        mapDbStrictErrorToUserMessage(e.message),
        code: e.code,
      );
    }
  }

  /// Compenser une sortie erronée
  Future<String> compensateSortie({
    required String sortieId,
    required String reason,
  }) async {
    try {
      final result = await client.rpc(
        'admin_compensate_sortie',
        params: {
          'p_sortie_id': sortieId,
          'p_reason': reason,
        },
      );
      
      return result as String; // adjustment_id
    } on PostgrestException catch (e) {
      throw CompensationException(
        mapDbStrictErrorToUserMessage(e.message),
        code: e.code,
      );
    }
  }
}
```

**Écran UI** : `lib/features/admin/screens/compensation_screen.dart`

```dart
class CompensationScreen extends StatelessWidget {
  final String transactionId;
  final String transactionType; // 'reception' ou 'sortie'

  Future<void> _compensate(BuildContext context) async {
    final reason = _reasonController.text;
    
    if (reason.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La raison doit contenir au moins 10 caractères')),
      );
      return;
    }

    try {
      final service = CompensationService(Supabase.instance.client);
      
      if (transactionType == 'reception') {
        await service.compensateReception(
          receptionId: transactionId,
          reason: reason,
        );
      } else {
        await service.compensateSortie(
          sortieId: transactionId,
          reason: reason,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compensation effectuée avec succès')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }
}
```

---

## Checklist de validation

- [ ] Codes d'erreur DB documentés et mappés
- [ ] Documentation mise à jour (receptions.md, sorties_mvp.md, architecture.md)
- [ ] Changelog mis à jour
- [ ] README mentionne DB-STRICT
- [ ] Optionnel : endpoints admin UI pour compensation
- [ ] Optionnel : écran UI pour compensation
- [ ] Tests de mapping d'erreurs ajoutés

---

## Notes importantes

- **Priorité** : Les codes d'erreur et la documentation sont **obligatoires**. Les endpoints UI sont **optionnels**.
- **Cohérence** : S'assurer que tous les messages d'erreur sont cohérents entre DB et UI.
- **Traçabilité** : Documenter tous les changements dans le changelog.

---

**Dernière mise à jour** : 2025-12-21

