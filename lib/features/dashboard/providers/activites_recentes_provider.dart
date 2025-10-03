import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/dashboard/models/activite_recente.dart';

final activitesRecentesProvider = FutureProvider<List<ActiviteRecente>>((
  ref,
) async {
  final supa = Supabase.instance.client;
  final now = DateTime.now().toUtc();
  final start = now.subtract(const Duration(hours: 24));
  String iso(DateTime d) => d.toUtc().toIso8601String().split('.').first + 'Z';

  final rows = await supa
      .from('logs')
      .select('id,created_at,module,action,niveau,user_id,details')
      .gte('created_at', iso(start))
      .order('created_at', ascending: false)
      .limit(50);

  return (rows as List)
      .map((row) => ActiviteRecente.fromMap(row as Map<String, dynamic>))
      .toList();
});
