import 'package:meta/meta.dart';

@immutable
class KpiLabelValue {
  final String label;
  final String value;
  const KpiLabelValue(this.label, this.value);
}

@immutable
class CamionsFilter {
  final String? depotId; // null = tous dépôts
  const CamionsFilter({this.depotId});
}

@immutable
class CamionsASuivreData {
  final int enRoute;
  final int enAttente;
  const CamionsASuivreData({required this.enRoute, required this.enAttente});
  int get total => enRoute + enAttente;
}

@immutable
class ReceptionsFilter {
  /// Jour en UTC (hh:mm:ss ignorés). Null => aujourd'hui (UTC).
  final DateTime? dayUtc;
  /// Filtre optionnel par dépôt (via citernes.depot_id)
  final String? depotId;
  const ReceptionsFilter({this.dayUtc, this.depotId});

  DateTime effectiveDayUtc() {
    final now = DateTime.now().toUtc();
    final d = dayUtc ?? now;
    return DateTime.utc(d.year, d.month, d.day);
  }
}

@immutable
class ReceptionsStats {
  final int nbCamions;           // nb réceptions validées
  final double volAmbiant;       // Σ volume_ambiant
  final double vol15c;           // Σ volume_corrige_15c (null => 0)
  const ReceptionsStats({
    required this.nbCamions,
    required this.volAmbiant,
    required this.vol15c,
  });
}

@immutable
class CoursCounts {
  final int enRoute;             // CHARGEMENT + TRANSIT + FRONTIERE
  final int attente;             // ARRIVE
  final double enRouteLitres;    // somme(volume) pour enRoute
  final double attenteLitres;    // somme(volume) pour attente
  const CoursCounts({
    required this.enRoute,
    required this.attente,
    required this.enRouteLitres,
    required this.attenteLitres,
  });
}
