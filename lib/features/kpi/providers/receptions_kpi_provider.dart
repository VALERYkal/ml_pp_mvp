// ?? DÉPRÉCIÉ - Utiliser kpiProvider à la place
// Ce fichier sera supprimé dans la prochaine version majeure
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/repositories.dart';
import '../models/kpi_models.dart';
import '../../profil/providers/profil_provider.dart';

/// Provider stable pour les paramètres "aujourd'hui" des réceptions
final receptionsTodayParamProvider =
    Provider<({String? depotId, String dayYmd})>((ref) {
      final profil = ref
          .watch(profilProvider)
          .maybeWhen(data: (p) => p, orElse: () => null);
      final depotId = profil?.depotId;
      final now = DateTime.now().toUtc();
      final y = now.year.toString().padLeft(4, '0');
      final m = now.month.toString().padLeft(2, '0');
      final d = now.day.toString().padLeft(2, '0');
      return (depotId: depotId, dayYmd: '$y-$m-$d');
    });

/// Provider KPI réceptions avec record value-type (égalité par valeur)
final receptionsKpiProvider =
    FutureProvider.family<ReceptionsStats, ({String? depotId, String dayYmd})>((
      ref,
      p,
    ) async {
      final repo = ref.watch(receptionsRepoProvider);
      // dayYmd est un 'YYYY-MM-DD' UTC
      final parts = p.dayYmd.split('-');
      final dayUtc = DateTime.utc(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );

      final r = await repo.statsJour(dayUtc: dayUtc, depotId: p.depotId);
      return ReceptionsStats(
        nbCamions: r.nbCamions,
        volAmbiant: r.volAmbiant,
        vol15c: r.vol15c,
      );
    });

