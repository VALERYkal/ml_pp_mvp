import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as Riverpod;

class LogsService {
  String _isoUtc(DateTime d) =>
      d.toUtc().toIso8601String().split('.').first + 'Z';

  String _escapeCsv(String input) {
    final needs =
        input.contains(',') || input.contains('"') || input.contains('\n');
    if (!needs) return input;
    return '"${input.replaceAll('"', '""')}"';
  }

  Future<List<Map<String, dynamic>>> fetch({
    required DateTime startUtc,
    required DateTime endUtc,
    String? module,
    String? level,
    String? userId,
    String? search,
    int limit = 200,
  }) async {
    final supa = Supabase.instance.client;

    // Construire la requête de base
    final query = supa
        .from('logs') // vue de compatibilité créée côté DB
        .select('created_at,module,action,niveau,user_id,details')
        .gte('created_at', _isoUtc(startUtc))
        .lt('created_at', _isoUtc(endUtc))
        .order('created_at', ascending: false)
        .limit(limit);

    final rows = await query;
    final allRows = (rows as List).cast<Map<String, dynamic>>();

    // Appliquer les filtres côté client (plus simple et fiable)
    var filteredRows = allRows;

    if (module != null && module.isNotEmpty) {
      filteredRows = filteredRows
          .where(
            (row) =>
                row['module']?.toString().toLowerCase().contains(
                  module.toLowerCase(),
                ) ??
                false,
          )
          .toList();
    }

    if (level != null && level.isNotEmpty) {
      filteredRows = filteredRows
          .where(
            (row) =>
                row['niveau']?.toString().toLowerCase() == level.toLowerCase(),
          )
          .toList();
    }

    if (userId != null && userId.isNotEmpty) {
      filteredRows = filteredRows
          .where((row) => row['user_id']?.toString() == userId)
          .toList();
    }

    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      filteredRows = filteredRows.where((row) {
        final action = row['action']?.toString().toLowerCase() ?? '';
        final module = row['module']?.toString().toLowerCase() ?? '';
        return action.contains(searchLower) || module.contains(searchLower);
      }).toList();
    }

    return filteredRows;
  }

  Future<String> exportCsv({
    required DateTime startUtc,
    required DateTime endUtc,
    String? module,
    String? level,
    String? userId,
    String? search,
  }) async {
    final rows = await fetch(
      startUtc: startUtc,
      endUtc: endUtc,
      module: module,
      level: level,
      userId: userId,
      search: search,
      limit: 2000,
    );

    final b = StringBuffer('created_at,module,action,niveau,user_id,details\n');
    for (final m in rows) {
      final createdAt = (m['created_at'] ?? '').toString();
      final module = _escapeCsv((m['module'] ?? '').toString());
      final action = _escapeCsv((m['action'] ?? '').toString());
      final niveau = (m['niveau'] ?? '').toString();
      final user = (m['user_id'] ?? '').toString();
      final details = m['details'] == null
          ? ''
          : _escapeCsv(m['details'].toString());
      b.writeln('$createdAt,$module,$action,$niveau,$user,$details');
    }
    return b.toString();
  }
}

final logsServiceProvider = Riverpod.Provider<LogsService>(
  (ref) => LogsService(),
);
