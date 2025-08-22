// 📌 Providers pour consultation des logs (log_actions)

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show DateTimeRange; // for DateTimeRange filter state
import 'package:flutter_riverpod/flutter_riverpod.dart' as Riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';

class LogEntryView {
  final String id;
  final DateTime createdAt;
  final String module;
  final String action;
  final String niveau;
  final String? userId;
  final Map<String, dynamic>? details;

  const LogEntryView({
    required this.id,
    required this.createdAt,
    required this.module,
    required this.action,
    required this.niveau,
    required this.userId,
    required this.details,
  });
}

// Filtres
final logsDateRangeProvider = Riverpod.StateProvider<DateTimeRange?>((ref) => null);
final logsModuleProvider = Riverpod.StateProvider<String?>((ref) => null);
final logsActionContainsProvider = Riverpod.StateProvider<String?>((ref) => null);
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

final logsUsersRefProvider = Riverpod.FutureProvider<List<Map<String, String>>>((ref) async {
  final res = await Supabase.instance.client.from('profils').select('user_id, nom_complet, email').order('nom_complet');
  return (res as List<dynamic>).map((e) {
    final m = e as Map<String, dynamic>;
    return {
      'id': (m['user_id']?.toString() ?? ''),
      'label': (m['nom_complet']?.toString() ?? m['email']?.toString() ?? ''),
    };
  }).toList();
});

final logsListProvider = Riverpod.FutureProvider<List<LogEntryView>>((ref) async {
  final client = Supabase.instance.client;
  final range = ref.watch(logsDateRangeProvider);
  final module = ref.watch(logsModuleProvider);
  final actionContains = ref.watch(logsActionContainsProvider);
  final niveau = ref.watch(logsLevelProvider);
  final userId = ref.watch(logsUserIdProvider);
  final page = ref.watch(logsPageProvider);
  final pageSize = ref.watch(logsPageSizeProvider);

  try {
    var query = client
        .from('log_actions')
        .select('id, created_at, module, action, niveau, user_id, details');

    if (range != null) {
      final start = DateTime(range.start.year, range.start.month, range.start.day).toIso8601String();
      final end = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59, 999).toIso8601String();
      query = query.gte('created_at', start).lte('created_at', end);
    }
    if (module != null && module.isNotEmpty) {
      query = query.eq('module', module);
    }
    if (niveau != null && niveau.isNotEmpty) {
      query = query.eq('niveau', niveau);
    }
    if (userId != null && userId.isNotEmpty) {
      query = query.eq('user_id', userId);
    }
    if (actionContains != null && actionContains.isNotEmpty) {
      final term = actionContains.replaceAll('%', '');
      query = query.ilike('action', '%$term%');
    }

    final startIdx = page * pageSize;
    final endIdx = startIdx + pageSize - 1;
    final res = await query.order('created_at', ascending: false).range(startIdx, endIdx);
    return (res as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return LogEntryView(
        id: m['id'] as String,
        createdAt: DateTime.parse(m['created_at'] as String),
        module: m['module']?.toString() ?? '',
        action: m['action']?.toString() ?? '',
        niveau: m['niveau']?.toString() ?? 'INFO',
        userId: m['user_id']?.toString(),
        details: (m['details'] as Map?)?.cast<String, dynamic>(),
      );
    }).toList();
  } on PostgrestException catch (e) {
    debugPrint('❌ logsListProvider: ${e.message}');
    rethrow;
  }
});

final logsExportProvider = Riverpod.FutureProvider<String>((ref) async {
  final data = await ref.watch(logsListProvider.future);
  final b = StringBuffer('created_at,module,action,niveau,user_id,details\n');
  for (final r in data) {
    final details = r.details == null ? '' : _escapeCsv(r.details.toString());
    b.writeln('${r.createdAt.toIso8601String()},${_escapeCsv(r.module)},${_escapeCsv(r.action)},${r.niveau},${r.userId ?? ''},$details');
  }
  return b.toString();
});

String _escapeCsv(String input) {
  final needs = input.contains(',') || input.contains('"') || input.contains('\n');
  final s = input.replaceAll('"', '""');
  return needs ? '"$s"' : s;
}

