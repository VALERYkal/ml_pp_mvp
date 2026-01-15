// 📌 Provider pour résoudre les références (produits/citernes) en batch pour les logs
// Rôle: Charger uniquement les IDs nécessaires pour la page actuelle (batch IN)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'logs_providers.dart';

/// Utilité pour obtenir un ID court (8 caractères)
String shortId(String id) => id.length >= 8 ? id.substring(0, 8) : id;

/// Requête pour résoudre les références
class LogsRefsRequest {
  final Set<String> produitIds;
  final Set<String> citerneIds;

  const LogsRefsRequest({
    required this.produitIds,
    required this.citerneIds,
  });

  /// Créer un LogsRefsRequest depuis une liste de LogEntryView
  /// Nécessite l'import de LogEntryView
  static LogsRefsRequest fromLogEntryViews(List<LogEntryView> logs) {
    final produitIds = <String>{};
    final citerneIds = <String>{};

    for (final log in logs) {
      if (log.produitId != null && log.produitId!.isNotEmpty) {
        produitIds.add(log.produitId!);
      }
      if (log.citerneId != null && log.citerneId!.isNotEmpty) {
        citerneIds.add(log.citerneId!);
      }
    }

    return LogsRefsRequest(
      produitIds: produitIds,
      citerneIds: citerneIds,
    );
  }

  /// Clé stable pour le cache (basée sur les IDs triés)
  String get cacheKey {
    final prodList = produitIds.toList()..sort();
    final citList = citerneIds.toList()..sort();
    return 'prod:${prodList.join(',')}|cit:${citList.join(',')}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LogsRefsRequest &&
        other.produitIds.length == produitIds.length &&
        other.citerneIds.length == citerneIds.length &&
        other.produitIds.every((id) => produitIds.contains(id)) &&
        other.citerneIds.every((id) => citerneIds.contains(id));
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(produitIds.toList()..sort()),
        Object.hashAll(citerneIds.toList()..sort()),
      );
}

/// Résultat de la résolution des références
class LogsRefs {
  final Map<String, String> produitsLabelById;
  final Map<String, String> citernesLabelById;

  const LogsRefs({
    required this.produitsLabelById,
    required this.citernesLabelById,
  });

  /// Obtenir le label d'un produit (fallback: shortId)
  String getProduitLabel(String? id) {
    if (id == null || id.isEmpty) return '-';
    return produitsLabelById[id] ?? shortId(id);
  }

  /// Obtenir le label d'une citerne (fallback: shortId)
  String getCiterneLabel(String? id) {
    if (id == null || id.isEmpty) return '-';
    return citernesLabelById[id] ?? shortId(id);
  }
}

/// Provider pour résoudre les références en batch
final logsRefsProvider =
    FutureProvider.family<LogsRefs, LogsRefsRequest>((ref, request) async {
  final client = Supabase.instance.client;
  final produitsLabelById = <String, String>{};
  final citernesLabelById = <String, String>{};

  // Résoudre les produits (batch)
  if (request.produitIds.isNotEmpty) {
    final produitIdsList = request.produitIds.toList();
    final rows = await client
        .from('produits')
        .select<List<Map<String, dynamic>>>('id, code, nom')
        .in_('id', produitIdsList);

    for (final row in rows) {
      final id = row['id']?.toString();
      if (id == null || id.isEmpty) continue;

      final codeStr = row['code']?.toString();
      final code = codeStr != null ? codeStr.trim() : null;
      final nomStr = row['nom']?.toString();
      final nom = nomStr != null ? nomStr.trim() : '';
      
      // Label produit: si code non null/non vide => "$code — $nom" sinon "$nom"
      final label = (code != null && code.isNotEmpty) ? '$code — $nom' : nom;
      produitsLabelById[id] = label.isNotEmpty ? label : shortId(id);
    }
  }

  // Résoudre les citernes (batch)
  if (request.citerneIds.isNotEmpty) {
    final citerneIdsList = request.citerneIds.toList();
    final rows = await client
        .from('citernes')
        .select<List<Map<String, dynamic>>>('id, nom')
        .in_('id', citerneIdsList);

    for (final row in rows) {
      final id = row['id']?.toString();
      if (id == null || id.isEmpty) continue;

      final nomStr = row['nom']?.toString();
      final nom = nomStr != null ? nomStr.trim() : '';
      citernesLabelById[id] = nom.isNotEmpty ? nom : shortId(id);
    }
  }

  return LogsRefs(
    produitsLabelById: produitsLabelById,
    citernesLabelById: citernesLabelById,
  );
});
