// 📌 Module : Cours de Route - Tests Widget Liste (Simplifié)
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Test widget simplifié pour l'écran de liste CDR avec filtres par statut

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';

/// Widget de test simple pour vérifier l'affichage de la liste CDR
class SimpleCdrListWidget extends StatefulWidget {
  final List<CoursDeRoute> cours;
  final StatutCours? filterStatut;

  const SimpleCdrListWidget({
    super.key,
    required this.cours,
    this.filterStatut,
  });

  @override
  State<SimpleCdrListWidget> createState() => _SimpleCdrListWidgetState();
}

class _SimpleCdrListWidgetState extends State<SimpleCdrListWidget> {
  StatutCours? _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.filterStatut;
  }

  List<CoursDeRoute> get _filteredCours {
    if (_currentFilter == null) return widget.cours;
    return widget.cours.where((c) => c.statut == _currentFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Liste CDR'),
          actions: [
            // Bouton de filtre pour déchargé
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                setState(() {
                  _currentFilter = _currentFilter == StatutCours.decharge
                      ? null
                      : StatutCours.decharge;
                });
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Indicateur de filtre actif
            if (_currentFilter != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue.withOpacity(0.1),
                child: Text(
                  'Filtre actif: ${_currentFilter!.label}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            // Liste des cours
            Expanded(
              child: _filteredCours.isEmpty
                  ? const Center(child: Text('Aucun cours trouvé'))
                  : ListView.builder(
                      itemCount: _filteredCours.length,
                      itemBuilder: (context, index) {
                        final cours = _filteredCours[index];
                        return Card(
                          margin: const EdgeInsets.all(8),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatutColor(
                                  cours.statut,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatutColor(
                                    cours.statut,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                cours.statut.label,
                                style: TextStyle(
                                  color: _getStatutColor(cours.statut),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            title: Text(
                              '${cours.transporteur ?? '—'} - ${cours.plaqueCamion ?? '—'}',
                            ),
                            subtitle: Text(
                              '${cours.chauffeur ?? '—'} - ${cours.volume ?? '—'} L',
                            ),
                            trailing: Text(
                              cours.id.length > 8
                                  ? cours.id.substring(0, 8)
                                  : cours.id,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatutColor(StatutCours statut) {
    switch (statut) {
      case StatutCours.chargement:
        return Colors.blue;
      case StatutCours.transit:
        return Colors.indigo;
      case StatutCours.frontiere:
        return Colors.amber;
      case StatutCours.arrive:
        return Colors.teal;
      case StatutCours.decharge:
        return Colors.grey;
    }
  }
}

void main() {
  group('CDR List Widget Tests (Simplifié)', () {
    late List<CoursDeRoute> coursList;

    setUp(() {
      coursList = [
        CoursDeRoute(
          id: 'cdr-1',
          fournisseurId: 'fournisseur-1',
          produitId: 'produit-1',
          depotDestinationId: 'depot-1',
          transporteur: 'Transport Express',
          plaqueCamion: 'ABC123',
          chauffeur: 'Jean Dupont',
          volume: 50000.0,
          statut: StatutCours.chargement,
        ),
        CoursDeRoute(
          id: 'cdr-2',
          fournisseurId: 'fournisseur-2',
          produitId: 'produit-2',
          depotDestinationId: 'depot-1',
          transporteur: 'Transport Rapide',
          plaqueCamion: 'DEF456',
          chauffeur: 'Marie Martin',
          volume: 30000.0,
          statut: StatutCours.transit,
        ),
        CoursDeRoute(
          id: 'cdr-3',
          fournisseurId: 'fournisseur-1',
          produitId: 'produit-1',
          depotDestinationId: 'depot-2',
          transporteur: 'Transport Express',
          plaqueCamion: 'GHI789',
          chauffeur: 'Pierre Durand',
          volume: 45000.0,
          statut: StatutCours.decharge, // ✅ Cours déchargé pour le test
        ),
        CoursDeRoute(
          id: 'cdr-4',
          fournisseurId: 'fournisseur-3',
          produitId: 'produit-3',
          depotDestinationId: 'depot-1',
          transporteur: 'Transport Pro',
          plaqueCamion: 'JKL012',
          chauffeur: 'Sophie Bernard',
          volume: 60000.0,
          statut: StatutCours.frontiere,
        ),
      ];
    });

    testWidgets('should render list screen without exceptions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: SimpleCdrListWidget(cours: coursList)),
      );

      // Vérifier qu'il n'y a pas d'exception de rendu
      expect(tester.takeException(), isNull);

      // Attendre que le widget soit construit
      await tester.pumpAndSettle();

      // Vérifier qu'il n'y a toujours pas d'exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display all courses by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: SimpleCdrListWidget(cours: coursList)),
      );

      await tester.pumpAndSettle();

      // Vérifier que tous les cours sont affichés
      expect(find.text('ABC123'), findsOneWidget); // cdr-1
      expect(find.text('DEF456'), findsOneWidget); // cdr-2
      expect(find.text('GHI789'), findsOneWidget); // cdr-3 (déchargé)
      expect(find.text('JKL012'), findsOneWidget); // cdr-4
    });

    testWidgets('should filter by déchargé status', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: SimpleCdrListWidget(cours: coursList)),
      );

      await tester.pumpAndSettle();

      // Cliquer sur le bouton de filtre pour activer le filtre déchargé
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Vérifier que seul le cours déchargé est affiché
      expect(find.text('GHI789'), findsOneWidget); // cdr-3 (déchargé)

      // Vérifier que les autres cours ne sont pas affichés
      expect(find.text('ABC123'), findsNothing); // cdr-1
      expect(find.text('DEF456'), findsNothing); // cdr-2
      expect(find.text('JKL012'), findsNothing); // cdr-4

      // Vérifier que l'indicateur de filtre est affiché
      expect(find.text('Filtre actif: Déchargé'), findsOneWidget);
    });

    testWidgets('should toggle filter off', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: SimpleCdrListWidget(cours: coursList)),
      );

      await tester.pumpAndSettle();

      // Activer le filtre déchargé
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Vérifier que seul le cours déchargé est affiché
      expect(find.text('GHI789'), findsOneWidget);

      // Désactiver le filtre
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Vérifier que tous les cours sont à nouveau affichés
      expect(find.text('ABC123'), findsOneWidget);
      expect(find.text('DEF456'), findsOneWidget);
      expect(find.text('GHI789'), findsOneWidget);
      expect(find.text('JKL012'), findsOneWidget);

      // Vérifier que l'indicateur de filtre n'est plus affiché
      expect(find.text('Filtre actif: Déchargé'), findsNothing);
    });

    testWidgets('should display status chips correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: SimpleCdrListWidget(cours: coursList)),
      );

      await tester.pumpAndSettle();

      // Vérifier que les chips de statut sont affichés
      expect(find.text('Chargement'), findsOneWidget);
      expect(find.text('Transit'), findsOneWidget);
      expect(find.text('Déchargé'), findsOneWidget);
      expect(find.text('Frontière'), findsOneWidget);
    });

    testWidgets('should handle empty list', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(child: SimpleCdrListWidget(cours: [])),
      );

      await tester.pumpAndSettle();

      // Vérifier qu'un message approprié est affiché pour la liste vide
      expect(find.text('Aucun cours trouvé'), findsOneWidget);
    });

    testWidgets('should display course information correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: SimpleCdrListWidget(cours: coursList)),
      );

      await tester.pumpAndSettle();

      // Vérifier les informations des cours
      expect(
        find.text('Transport Express'),
        findsNWidgets(2),
      ); // cdr-1 et cdr-3
      expect(find.text('Transport Rapide'), findsOneWidget); // cdr-2
      expect(find.text('Transport Pro'), findsOneWidget); // cdr-4

      expect(find.text('Jean Dupont'), findsOneWidget);
      expect(find.text('Marie Martin'), findsOneWidget);
      expect(find.text('Pierre Durand'), findsOneWidget);
      expect(find.text('Sophie Bernard'), findsOneWidget);
    });
  });
}
