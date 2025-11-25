import 'package:supabase_flutter/supabase_flutter.dart';

class DepotsRepository {
  final SupabaseClient _supa;
  DepotsRepository(this._supa);

  Future<String?> getDepotNameById(String id) async {
    if (id.isEmpty) return null;
    final rows = await _supa.from('depots').select('nom').eq('id', id).limit(1);
    if (rows is List && rows.isNotEmpty) {
      return rows.first['nom'] as String?;
    }
    return null;
  }
}




