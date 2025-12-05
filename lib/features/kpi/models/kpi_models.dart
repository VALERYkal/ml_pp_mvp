import 'package:meta/meta.dart';

// ============================================================================
// MODÈLES UNIFIÉS POUR LE SYSTÈME KPI CENTRALISÉ
// ============================================================================

/// Helper pour convertir les valeurs nullable en double safe
double _nz(num? v) => (v ?? 0).toDouble();

/// Modèle unifié pour les volumes avec compteurs
@immutable
class KpiNumberVolume {
  final int count;
  final double volume15c;
  final double volumeAmbient;
  
  const KpiNumberVolume({
    required this.count, 
    required this.volume15c, 
    required this.volumeAmbient
  });

  /// Constructeur factory pour valeurs nullable depuis Supabase
  factory KpiNumberVolume.fromNullable({
    int? count,
    num? volume15c,
    num? volumeAmbient,
  }) {
    return KpiNumberVolume(
      count: count ?? 0,
      volume15c: _nz(volume15c),
      volumeAmbient: _nz(volumeAmbient),
    );
  }

  /// Instance vide pour les cas d'erreur
  static const zero = KpiNumberVolume(count: 0, volume15c: 0, volumeAmbient: 0);
}

/// Modèle dédié pour les KPI Réceptions avec distinction propriétaires
/// 
/// Étend KpiNumberVolume avec des compteurs par type de propriétaire
/// (MONALUXE vs PARTENAIRE) pour permettre des analyses plus fines.
@immutable
class KpiReceptions {
  final int count;
  final double volumeAmbient;
  final double volume15c;
  final int countMonaluxe;
  final int countPartenaire;

  const KpiReceptions({
    required this.count,
    required this.volumeAmbient,
    required this.volume15c,
    this.countMonaluxe = 0,
    this.countPartenaire = 0,
  });

  /// Conversion vers KpiNumberVolume pour compatibilité
  KpiNumberVolume toKpiNumberVolume() {
    return KpiNumberVolume(
      count: count,
      volume15c: volume15c,
      volumeAmbient: volumeAmbient,
    );
  }

  /// Constructeur depuis KpiNumberVolume (pour migration progressive)
  factory KpiReceptions.fromKpiNumberVolume(KpiNumberVolume volume) {
    return KpiReceptions(
      count: volume.count,
      volume15c: volume.volume15c,
      volumeAmbient: volume.volumeAmbient,
      countMonaluxe: 0,
      countPartenaire: 0,
    );
  }

  KpiReceptions copyWith({
    int? count,
    double? volumeAmbient,
    double? volume15c,
    int? countMonaluxe,
    int? countPartenaire,
  }) {
    return KpiReceptions(
      count: count ?? this.count,
      volumeAmbient: volumeAmbient ?? this.volumeAmbient,
      volume15c: volume15c ?? this.volume15c,
      countMonaluxe: countMonaluxe ?? this.countMonaluxe,
      countPartenaire: countPartenaire ?? this.countPartenaire,
    );
  }

  /// Instance vide pour les cas d'erreur
  static const zero = KpiReceptions(
    count: 0,
    volumeAmbient: 0,
    volume15c: 0,
    countMonaluxe: 0,
    countPartenaire: 0,
  );
}

/// Modèle dédié pour les KPI Sorties avec distinction propriétaires
/// 
/// Étend KpiNumberVolume avec des compteurs par type de propriétaire
/// (MONALUXE vs PARTENAIRE) pour permettre des analyses plus fines.
@immutable
class KpiSorties {
  final int count;
  final double volumeAmbient;
  final double volume15c;
  final int countMonaluxe;
  final int countPartenaire;

  const KpiSorties({
    required this.count,
    required this.volumeAmbient,
    required this.volume15c,
    this.countMonaluxe = 0,
    this.countPartenaire = 0,
  });

  /// Conversion vers KpiNumberVolume pour compatibilité
  KpiNumberVolume toKpiNumberVolume() {
    return KpiNumberVolume(
      count: count,
      volume15c: volume15c,
      volumeAmbient: volumeAmbient,
    );
  }

  /// Constructeur depuis KpiNumberVolume (pour migration progressive)
  factory KpiSorties.fromKpiNumberVolume(KpiNumberVolume volume) {
    return KpiSorties(
      count: volume.count,
      volume15c: volume.volume15c,
      volumeAmbient: volume.volumeAmbient,
      countMonaluxe: 0,
      countPartenaire: 0,
    );
  }

  KpiSorties copyWith({
    int? count,
    double? volumeAmbient,
    double? volume15c,
    int? countMonaluxe,
    int? countPartenaire,
  }) {
    return KpiSorties(
      count: count ?? this.count,
      volumeAmbient: volumeAmbient ?? this.volumeAmbient,
      volume15c: volume15c ?? this.volume15c,
      countMonaluxe: countMonaluxe ?? this.countMonaluxe,
      countPartenaire: countPartenaire ?? this.countPartenaire,
    );
  }

  /// Instance vide pour les cas d'erreur
  static const zero = KpiSorties(
    count: 0,
    volumeAmbient: 0,
    volume15c: 0,
    countMonaluxe: 0,
    countPartenaire: 0,
  );
}

/// Modèle unifié pour les stocks avec capacité
@immutable
class KpiStocks {
  final double totalAmbient;
  final double total15c;
  final double capacityTotal;
  
  const KpiStocks({
    required this.totalAmbient, 
    required this.total15c, 
    required this.capacityTotal
  });

  /// Constructeur factory pour valeurs nullable depuis Supabase
  factory KpiStocks.fromNullable({
    num? totalAmbient,
    num? total15c,
    num? capacityTotal,
  }) {
    return KpiStocks(
      totalAmbient: _nz(totalAmbient),
      total15c: _nz(total15c),
      capacityTotal: _nz(capacityTotal),
    );
  }
  
  /// Ratio d'utilisation (0.0 à 1.0)
  double get utilizationRatio => capacityTotal == 0 ? 0 : (total15c / capacityTotal);

  /// Instance vide pour les cas d'erreur
  static const zero = KpiStocks(totalAmbient: 0, total15c: 0, capacityTotal: 0);
}

/// Modèle unifié pour la balance du jour
@immutable
class KpiBalanceToday {
  final double receptions15c;
  final double sorties15c;
  final double receptionsAmbient;
  final double sortiesAmbient;
  
  const KpiBalanceToday({
    required this.receptions15c, 
    required this.sorties15c,
    required this.receptionsAmbient,
    required this.sortiesAmbient,
  });

  /// Constructeur factory pour valeurs nullable depuis Supabase
  factory KpiBalanceToday.fromNullable({
    num? receptions15c,
    num? sorties15c,
    num? receptionsAmbient,
    num? sortiesAmbient,
  }) {
    return KpiBalanceToday(
      receptions15c: _nz(receptions15c),
      sorties15c: _nz(sorties15c),
      receptionsAmbient: _nz(receptionsAmbient),
      sortiesAmbient: _nz(sortiesAmbient),
    );
  }
  
  /// Delta calculé (réceptions - sorties) à 15°C
  double get delta15c => receptions15c - sorties15c;
  
  /// Delta calculé (réceptions - sorties) ambiant
  double get deltaAmbient => receptionsAmbient - sortiesAmbient;

  /// Instance vide pour les cas d'erreur
  static const zero = KpiBalanceToday(
    receptions15c: 0, 
    sorties15c: 0, 
    receptionsAmbient: 0, 
    sortiesAmbient: 0
  );
}

/// Modèle unifié pour les alertes de citernes
@immutable
class KpiCiterneAlerte {
  final String citerneId;
  final String libelle;
  final double stock15c;
  final double capacity;
  
  const KpiCiterneAlerte({
    required this.citerneId, 
    required this.libelle, 
    required this.stock15c, 
    required this.capacity
  });

  /// Constructeur factory pour valeurs nullable depuis Supabase
  factory KpiCiterneAlerte.fromNullable({
    String? citerneId,
    String? libelle,
    num? stock15c,
    num? capacity,
  }) {
    return KpiCiterneAlerte(
      citerneId: citerneId ?? '',
      libelle: libelle ?? 'Citerne inconnue',
      stock15c: _nz(stock15c),
      capacity: _nz(capacity),
    );
  }
}

/// Modèle unifié pour les points de tendance
@immutable
class KpiTrendPoint {
  final DateTime day;
  final double receptions15c;
  final double sorties15c;
  
  const KpiTrendPoint({
    required this.day, 
    required this.receptions15c, 
    required this.sorties15c
  });

  /// Constructeur factory pour valeurs nullable depuis Supabase
  factory KpiTrendPoint.fromNullable({
    DateTime? day,
    num? receptions15c,
    num? sorties15c,
  }) {
    return KpiTrendPoint(
      day: day ?? DateTime.now(),
      receptions15c: _nz(receptions15c),
      sorties15c: _nz(sorties15c),
    );
  }
}

/// Modèle unifié pour les camions à suivre
/// 
/// RÈGLE MÉTIER CDR (Cours de Route) :
/// - trucksLoading (Au chargement) = CHARGEMENT
/// - trucksOnRoute (En route) = TRANSIT + FRONTIERE
/// - trucksArrived (Arrivés) = ARRIVE
/// - DECHARGE = EXCLU (déjà pris en charge dans Réceptions/Stocks)
@immutable
class KpiTrucksToFollow {
  /// Nombre total de camions à suivre (non déchargés)
  final int totalTrucks;
  /// Volume total prévu en litres
  final double totalPlannedVolume;
  /// Camions au chargement (chez le fournisseur)
  final int trucksLoading;
  /// Camions en route (TRANSIT + FRONTIERE)
  final int trucksOnRoute;
  /// Camions arrivés (au dépôt mais pas encore déchargés)
  final int trucksArrived;
  /// Volume des camions au chargement
  final double volumeLoading;
  /// Volume des camions en route
  final double volumeOnRoute;
  /// Volume des camions arrivés
  final double volumeArrived;
  
  const KpiTrucksToFollow({
    required this.totalTrucks,
    required this.totalPlannedVolume,
    required this.trucksLoading,
    required this.trucksOnRoute,
    required this.trucksArrived,
    required this.volumeLoading,
    required this.volumeOnRoute,
    required this.volumeArrived,
  });

  /// Constructeur factory pour valeurs nullable depuis Supabase
  factory KpiTrucksToFollow.fromNullable({
    int? totalTrucks,
    num? totalPlannedVolume,
    int? trucksLoading,
    int? trucksOnRoute,
    int? trucksArrived,
    num? volumeLoading,
    num? volumeOnRoute,
    num? volumeArrived,
  }) {
    return KpiTrucksToFollow(
      totalTrucks: totalTrucks ?? 0,
      totalPlannedVolume: _nz(totalPlannedVolume),
      trucksLoading: trucksLoading ?? 0,
      trucksOnRoute: trucksOnRoute ?? 0,
      trucksArrived: trucksArrived ?? 0,
      volumeLoading: _nz(volumeLoading),
      volumeOnRoute: _nz(volumeOnRoute),
      volumeArrived: _nz(volumeArrived),
    );
  }

  /// Instance vide pour les cas d'erreur
  static const zero = KpiTrucksToFollow(
    totalTrucks: 0,
    totalPlannedVolume: 0,
    trucksLoading: 0,
    trucksOnRoute: 0,
    trucksArrived: 0,
    volumeLoading: 0,
    volumeOnRoute: 0,
    volumeArrived: 0,
  );
}

/// SNAPSHOT UNIFIÉ - Point d'entrée unique pour tous les KPIs
@immutable
class KpiSnapshot {
  final KpiNumberVolume receptionsToday;
  final KpiNumberVolume sortiesToday;
  final KpiStocks stocks;
  final KpiBalanceToday balanceToday;
  final KpiTrucksToFollow trucksToFollow;
  final List<KpiTrendPoint> trend7d;
  
  const KpiSnapshot({
    required this.receptionsToday,
    required this.sortiesToday,
    required this.stocks,
    required this.balanceToday,
    required this.trucksToFollow,
    required this.trend7d,
  });

  /// Instance vide pour les cas d'erreur ou de chargement
  static const empty = KpiSnapshot(
    receptionsToday: KpiNumberVolume.zero,
    sortiesToday: KpiNumberVolume.zero,
    stocks: KpiStocks.zero,
    balanceToday: KpiBalanceToday.zero,
    trucksToFollow: KpiTrucksToFollow.zero,
    trend7d: [],
  );
}

// ============================================================================
// MODÈLES LEGACY (À DÉPRÉCIER PROGRESSIVEMENT)
// ============================================================================

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
