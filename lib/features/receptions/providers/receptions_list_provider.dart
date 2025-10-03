import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/receptions/models/reception.dart';

final receptionsPageProvider = StateProvider<int>((ref) => 0);
final receptionsPageSizeProvider = StateProvider<int>((ref) => 25);

final receptionsListProvider = FutureProvider<List<Reception>>((ref) async {
  final int page = ref.watch(receptionsPageProvider);
  final int size = ref.watch(receptionsPageSizeProvider);
  final int start = page * size;
  final int end = start + size - 1;

  final res = await Supabase.instance.client
      .from('receptions')
      .select('*')
      .order('created_at', ascending: false)
      .range(start, end);

  return (res as List<dynamic>)
      .map((e) => Reception.fromJson(e as Map<String, dynamic>))
      .toList();
});
