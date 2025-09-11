// 📌 Providers pour consultation des logs (log_actions)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange; // for DateTimeRange filter state
import 'package:flutter_riverpod/flutter_riverpod.dart' as Riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';

// Utils pour les dates
String _fmtYmd(DateTime d) => '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

String _iso(DateTime d) => d.toIso8601String().split('.').first + 'Z';

/// Modèle "vue" enrichi avec parsing des détails JSONB
class LogEntryView {
  final String id;
  final DateTime createdAt;
  final String module;
  final String action;
  final String niveau;
  final String? userId;

  // Champs parsés depuis `details`
  final String? receptionId;
  final String? citerneId;
  final String? produitId;
  final double? volAmb;
  final double? vol15c;
  final DateTime? dateOp;
  final Map<String, dynamic>? rawDetails;

  LogEntryView({
    required this.id,
    required this.createdAt,
    required this.module,
    required this.action,
    required this.niveau,
    required this.userId,
    required this.rawDetails,
    this.receptionId,
    this.citerneId,
    this.produitId,
    this.volAmb,
    this.vol15c,
    this.dateOp,
  });
}

/// Utilitaires de parsing pour les détails JSONB
T? _as<T>(Object? v) => v is T ? v : null;

double? _asNum(Object? v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  final s = v.toString();
  return double.tryParse(s);
}

DateTime? _asDate(Object? v) {
  if (v == null) return null;
  // accepte "YYYY-MM-DD" ou ISO
  final s = v.toString();
  try {
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s)) {
      final p = s.split('-').map(int.parse).toList();
      return DateTime(p[0], p[1], p[2]);
    }
    return DateTime.parse(s);
  } catch (_) { return null; }
}

// Filtres
final logsDateRangeProvider = Riverpod.StateProvider<DateTimeRange?>((ref) => null);
final logsModuleProvider = Riverpod.StateProvider<String?>((ref) => null);
final logsSearchTextProvider = Riverpod.StateProvider<String?>((ref) => null);
final logsLevelProvider = Riverpod.StateProvider<String?>((ref) => null);
final logsUserIdProvider = Riverpod.StateProvider<String?>((ref) => null);
final logsPageProvider = Riverpod.StateProvider<int>((ref) => 0);
final logsPageSizeProvider = Riverpod.StateProvider<int>((ref) => 50);

// Référentiels simples
const List<String> logsModules = <String>[
  'receptions',
  'sorties_produit',
  'cours_de_route',
  'stocks_journaliers',
  'citernes',
  'auth',
];

const List<String> logsLevels = <String>['INFO', 'WARNING', 'CRITICAL'];

final logsUsersProvider = Riverpod.FutureProvider<List<Map<String,String>>>((ref) async {
  // affiche "user readable" : profils.nom_complet si dispo sinon uuid
  final rows = await Supabase.instance.client
      .from('profils')
      .select<List<Map<String, dynamic>>>('user_id, nom_complet')
      .order('nom_complet')
      .limit(2000);
  return rows.map((e) => {
    'id': e['user_id']?.toString() ?? '',
    'label': (e['nom_complet']?.toString() ?? '').isEmpty ? (e['user_id']?.toString().substring(0,8) ?? '') : e['nom_complet'].toString(),
  }).toList();
});

final logsListProvider = Riverpod.FutureProvider.autoDispose<List<LogEntryView>>((ref) async {
  final client = Supabase.instance.client;

  // états UI
  final range = ref.watch(logsDateRangeProvider);          // DateTimeRange?
  final module = ref.watch(logsModuleProvider);            // String? (ex: 'receptions') ou null = Tous
  final level  = ref.watch(logsLevelProvider);             // String? (INFO/WARNING/CRITICAL)
  final userId = ref.watch(logsUserIdProvider);            // String? (uuid)
  final search = ref.watch(logsSearchTextProvider);        // String? (recherche dans "action" + "details")
  final page   = ref.watch(logsPageProvider);
  final size   = ref.watch(logsPageSizeProvider);

  // base query
  var q = client.from('log_actions').select<List<Map<String, dynamic>>>(
    'id, created_at, module, action, niveau, user_id, details',
  );

  // période: si non définie, prendre les 7 derniers jours
  DateTime start;
  DateTime end;
  if (range != null) {
    start = DateTime(range.start.year, range.start.month, range.start.day);
    end   = DateTime(range.end.year,   range.end.month,   range.end.day).add(const Duration(days: 1));
  } else {
    final today = DateTime.now();
    start = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 7));
    end   = DateTime(today.year, today.month, today.day).add(const Duration(days: 1));
  }
  // filtre intervalle (en string ISO sans millis)
  q = q.gte('created_at', _iso(start)).lt('created_at', _iso(end));

  if (module != null) q = q.eq('module', module);
  if (level  != null) q = q.eq('niveau', level);
  if (userId != null) q = q.eq('user_id', userId);
  
  // Recherche étendue : action + details JSONB
  if (search != null && search.trim().isNotEmpty) {
    final s = search.trim();
    q = q.or('action.ilike.%$s%,details::text.ilike.%$s%'); // PostgREST or-filter
  }

  // tri + pagination
  final from = page * size;
  final to   = from + size - 1;
  final rows = await q.order('created_at', ascending: false).range(from, to);

  return rows.map((m) {
    final detailsMap = (m['details'] is Map)
        ? (m['details'] as Map).cast<String, dynamic>()
        : null;

    final citerneId   = detailsMap?['citerne_id']?.toString();
    final produitId   = detailsMap?['produit_id']?.toString();
    final receptionId = detailsMap?['reception_id']?.toString();
    final volAmb      = _asNum(detailsMap?['volume_ambiant']);
    final vol15c      = _asNum(detailsMap?['volume_15c']);
    final dateOp      = _asDate(detailsMap?['date_reception']) ?? _asDate(detailsMap?['date_sortie']);

    return LogEntryView(
      id:        m['id'] as String,
      createdAt: DateTime.parse(m['created_at'] as String),
      module:    m['module']?.toString() ?? '',
      action:    m['action']?.toString() ?? '',
      niveau:    m['niveau']?.toString() ?? 'INFO',
      userId:    m['user_id']?.toString(),
      rawDetails: detailsMap,
      citerneId: citerneId,
      produitId: produitId,
      receptionId: receptionId,
      volAmb: volAmb,
      vol15c: vol15c,
      dateOp: dateOp,
    );
  }).toList();
});

// pour les listes de filtres:
final logsModulesProvider = Riverpod.FutureProvider<List<String>>((ref) async {
  final rows = await Supabase.instance.client
      .from('log_actions')
      .select<List<Map<String, dynamic>>>('module')
      .order('module')
      .limit(2000);
  return rows.map((e) => e['module']?.toString()).whereType<String>().toSet().toList()..sort();
});

/// Provider de lookup pour les citernes (ID → nom)
final citerneLookupProvider = Riverpod.FutureProvider<Map<String,String>>((ref) async {
  final rows = await Supabase.instance.client
      .from('citernes')
      .select<List<Map<String, dynamic>>>('id, nom')
      .limit(5000);
  return {for (final r in rows) r['id'] as String : r['nom'] as String};
});

/// Provider de lookup pour les produits (ID → nom)
final produitLookupProvider = Riverpod.FutureProvider<Map<String,String>>((ref) async {
  final rows = await Supabase.instance.client
      .from('produits')
      .select<List<Map<String, dynamic>>>('id, nom')
      .limit(5000);
  return {for (final r in rows) r['id'] as String : r['nom'] as String};
});

/// Provider de lookup pour les utilisateurs (ID → nom complet)
final usersLookupProvider = Riverpod.FutureProvider<Map<String, String>>((ref) async {
  final rows = await Supabase.instance.client
      .from('profils')
      .select<List<Map<String, dynamic>>>('user_id, nom_complet, email')
      .limit(5000);

  final map = <String, String>{};
  for (final r in rows) {
    final id = (r['user_id'] ?? '').toString();
    final name = (r['nom_complet'] ?? '').toString().trim();
    final email = (r['email'] ?? '').toString().trim();
    if (id.isEmpty) continue;
    map[id] = name.isNotEmpty ? name : (email.isNotEmpty ? email : id.substring(0, 8));
  }
  return map;
});

String _escapeCsv(String input) {
  final needs = input.contains(',') || input.contains('"') || input.contains('\n');
  final s = input.replaceAll('"', '""');
  return needs ? '"$s"' : s;
}

