// 📌 Shared Constants - Cours Status (enum-based)
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';

/// Flux canonique des statuts (logique, pas d'accents côté DB)
const List<StatutCours> kCoursFlowEnum = <StatutCours>[
  StatutCours.chargement,
  StatutCours.transit,
  StatutCours.frontiere,
  StatutCours.arrive,
  StatutCours.decharge,
];

/// Libellés UI (avec accents) dérivés de l'enum.
String cdrUiLabel(StatutCours s) {
  switch (s) {
    case StatutCours.chargement:
      return 'chargement';
    case StatutCours.transit:
      return 'transit';
    case StatutCours.frontiere:
      return 'frontière';
    case StatutCours.arrive:
      return 'arrivé';
    case StatutCours.decharge:
      return 'déchargé';
  }
}

/// Nom d'icône Material (UI) dérivé de l'enum (string pour compat étendue).
String cdrIconName(StatutCours s) {
  switch (s) {
    case StatutCours.chargement:
      return 'local_shipping';
    case StatutCours.transit:
      return 'directions_car';
    case StatutCours.frontiere:
      return 'border_crossing';
    case StatutCours.arrive:
      return 'location_on';
    case StatutCours.decharge:
      return 'check_circle';
  }
}

/// Liste des libellés (UI) – compat éventuelle si du code attendait des List<String>.
final List<String> kCoursFlowLabels =
    kCoursFlowEnum.map(cdrUiLabel).toList(growable: false);
