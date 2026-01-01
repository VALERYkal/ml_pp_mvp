import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/data/repositories/repositories.dart'
    show supabaseClientProvider;
import 'package:ml_pp_mvp/features/stocks_adjustments/data/stocks_adjustments_service.dart';

final stocksAdjustmentsServiceProvider =
    Provider<StocksAdjustmentsService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return StocksAdjustmentsService(client);
});

