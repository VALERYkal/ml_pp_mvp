// 📌 Module : Cours de Route - Services
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Service de statistiques pour les cours de route

import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';

/// Modèle de statistiques pour les cours de route
class CoursStatistics {
  final int totalCours;
  final int coursChargement;
  final int coursTransit;
  final int coursFrontiere;
  final int coursArrive;
  final int coursDecharge;
  final double totalVolume;
  final double volumeMoyen;
  final Map<String, int> coursParFournisseur;
  final Map<String, int> coursParProduit;
  final Map<String, double> volumeParProduit;
  final Map<String, int> coursParDepot;
  final Map<String, int> coursParTransporteur;
  final Map<String, int> coursParChauffeur;
  final Map<String, int> coursParMois;
  final Map<String, int> coursParSemaine;
  final double tauxCompletion;
  final double dureeMoyenneTransit;
  final DateTime? dateDebut;
  final DateTime? dateFin;

  const CoursStatistics({
    required this.totalCours,
    required this.coursChargement,
    required this.coursTransit,
    required this.coursFrontiere,
    required this.coursArrive,
    required this.coursDecharge,
    required this.totalVolume,
    required this.volumeMoyen,
    required this.coursParFournisseur,
    required this.coursParProduit,
    required this.volumeParProduit,
    required this.coursParDepot,
    required this.coursParTransporteur,
    required this.coursParChauffeur,
    required this.coursParMois,
    required this.coursParSemaine,
    required this.tauxCompletion,
    required this.dureeMoyenneTransit,
    this.dateDebut,
    this.dateFin,
  });

  /// Statistiques par statut
  Map<StatutCours, int> get coursParStatut => {
    StatutCours.chargement: coursChargement,
    StatutCours.transit: coursTransit,
    StatutCours.frontiere: coursFrontiere,
    StatutCours.arrive: coursArrive,
    StatutCours.decharge: coursDecharge,
  };

  /// Top 5 fournisseurs
  List<MapEntry<String, int>> get topFournisseurs {
    final entries = coursParFournisseur.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  /// Top 5 produits
  List<MapEntry<String, int>> get topProduits {
    final entries = coursParProduit.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  /// Top 5 transporteurs
  List<MapEntry<String, int>> get topTransporteurs {
    final entries = coursParTransporteur.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  /// Top 5 chauffeurs
  List<MapEntry<String, int>> get topChauffeurs {
    final entries = coursParChauffeur.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }

  /// Top 5 dépôts
  List<MapEntry<String, int>> get topDepots {
    final entries = coursParDepot.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).toList();
  }
}

/// Service de calcul des statistiques
class CoursStatisticsService {
  /// Calcule les statistiques pour une liste de cours de route
  static CoursStatistics calculateStatistics(List<CoursDeRoute> cours) {
    if (cours.isEmpty) {
      return const CoursStatistics(
        totalCours: 0,
        coursChargement: 0,
        coursTransit: 0,
        coursFrontiere: 0,
        coursArrive: 0,
        coursDecharge: 0,
        totalVolume: 0,
        volumeMoyen: 0,
        coursParFournisseur: {},
        coursParProduit: {},
        volumeParProduit: {},
        coursParDepot: {},
        coursParTransporteur: {},
        coursParChauffeur: {},
        coursParMois: {},
        coursParSemaine: {},
        tauxCompletion: 0,
        dureeMoyenneTransit: 0,
      );
    }

    // Compteurs par statut
    int coursChargement = 0;
    int coursTransit = 0;
    int coursFrontiere = 0;
    int coursArrive = 0;
    int coursDecharge = 0;

    // Volumes
    double totalVolume = 0;
    int coursAvecVolume = 0;

    // Compteurs par catégorie
    final Map<String, int> coursParFournisseur = {};
    final Map<String, int> coursParProduit = {};
    final Map<String, double> volumeParProduit = {};
    final Map<String, int> coursParDepot = {};
    final Map<String, int> coursParTransporteur = {};
    final Map<String, int> coursParChauffeur = {};
    final Map<String, int> coursParMois = {};
    final Map<String, int> coursParSemaine = {};

    // Dates
    DateTime? dateDebut;
    DateTime? dateFin;

    // Durées de transit
    double totalDureeTransit = 0;
    int coursAvecDureeTransit = 0;

    for (final c in cours) {
      // Statuts
      switch (c.statut) {
        case StatutCours.chargement:
          coursChargement++;
          break;
        case StatutCours.transit:
          coursTransit++;
          break;
        case StatutCours.frontiere:
          coursFrontiere++;
          break;
        case StatutCours.arrive:
          coursArrive++;
          break;
        case StatutCours.decharge:
          coursDecharge++;
          break;
      }

      // Volumes
      if (c.volume != null) {
        totalVolume += c.volume!;
        coursAvecVolume++;

        // Volume par produit
        final produitKey = c.produitId;
        volumeParProduit[produitKey] =
            (volumeParProduit[produitKey] ?? 0) + c.volume!;
      }

      // Compteurs par catégorie
      coursParFournisseur[c.fournisseurId] =
          (coursParFournisseur[c.fournisseurId] ?? 0) + 1;
      coursParProduit[c.produitId] = (coursParProduit[c.produitId] ?? 0) + 1;
      coursParDepot[c.depotDestinationId] =
          (coursParDepot[c.depotDestinationId] ?? 0) + 1;

      if (c.transporteur != null && c.transporteur!.isNotEmpty) {
        coursParTransporteur[c.transporteur!] =
            (coursParTransporteur[c.transporteur!] ?? 0) + 1;
      }

      if (c.chauffeur != null && c.chauffeur!.isNotEmpty) {
        coursParChauffeur[c.chauffeur!] =
            (coursParChauffeur[c.chauffeur!] ?? 0) + 1;
      }

      // Dates
      if (c.dateChargement != null) {
        final date = c.dateChargement!;
        if (dateDebut == null || date.isBefore(dateDebut)) {
          dateDebut = date;
        }
        if (dateFin == null || date.isAfter(dateFin)) {
          dateFin = date;
        }

        // Par mois
        final moisKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        coursParMois[moisKey] = (coursParMois[moisKey] ?? 0) + 1;

        // Par semaine
        final semaineKey = '${date.year}-W${_getWeekNumber(date)}';
        coursParSemaine[semaineKey] = (coursParSemaine[semaineKey] ?? 0) + 1;
      }

      // Durée de transit (simplifiée)
      if (c.statut == StatutCours.decharge && c.dateChargement != null) {
        // Estimation basée sur le statut
        final dureeEstimee = _estimateTransitDuration(c.statut);
        totalDureeTransit += dureeEstimee;
        coursAvecDureeTransit++;
      }
    }

    // Calculs finaux
    final volumeMoyen = coursAvecVolume > 0
        ? totalVolume / coursAvecVolume
        : 0.0;
    final tauxCompletion = cours.isNotEmpty
        ? (coursDecharge / cours.length) * 100
        : 0.0;
    final dureeMoyenneTransit = coursAvecDureeTransit > 0
        ? totalDureeTransit / coursAvecDureeTransit
        : 0.0;

    return CoursStatistics(
      totalCours: cours.length,
      coursChargement: coursChargement,
      coursTransit: coursTransit,
      coursFrontiere: coursFrontiere,
      coursArrive: coursArrive,
      coursDecharge: coursDecharge,
      totalVolume: totalVolume,
      volumeMoyen: volumeMoyen.toDouble(),
      coursParFournisseur: coursParFournisseur,
      coursParProduit: coursParProduit,
      volumeParProduit: volumeParProduit,
      coursParDepot: coursParDepot,
      coursParTransporteur: coursParTransporteur,
      coursParChauffeur: coursParChauffeur,
      coursParMois: coursParMois,
      coursParSemaine: coursParSemaine,
      tauxCompletion: tauxCompletion.toDouble(),
      dureeMoyenneTransit: dureeMoyenneTransit.toDouble(),
      dateDebut: dateDebut,
      dateFin: dateFin,
    );
  }

  /// Calcule le numéro de semaine ISO
  static int _getWeekNumber(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  /// Estime la durée de transit basée sur le statut
  static double _estimateTransitDuration(StatutCours statut) {
    switch (statut) {
      case StatutCours.chargement:
        return 1.0; // 1 jour
      case StatutCours.transit:
        return 2.0; // 2 jours
      case StatutCours.frontiere:
        return 3.0; // 3 jours
      case StatutCours.arrive:
        return 4.0; // 4 jours
      case StatutCours.decharge:
        return 5.0; // 5 jours
    }
  }
}
