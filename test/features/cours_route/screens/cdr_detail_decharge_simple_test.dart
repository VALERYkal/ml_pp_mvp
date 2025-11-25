// ð Module : Cours de Route - Tests Widget DÃ©tail DÃ©chargÃ© (SimplifiÃ©)
// ð§ Auteur : Valery Kalonga
// ð Date : 2025-01-27
// ð§­ Description : Test widget simplifiÃ© pour l'Ã©cran de dÃ©tail CDR avec statut "dÃ©chargÃ©"

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';

/// Widget de test simple pour vÃ©rifier l'affichage du statut dÃ©chargÃ©
class SimpleCdrDetailWidget extends StatelessWidget {
  final CoursDeRoute cours;

  const SimpleCdrDetailWidget({super.key, required this.cours});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('DÃ©tail CDR')),
        body: Column(
          children: [
            // Affichage du statut
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Statut: '),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Text(
                      cours.statut.label,
                      style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            // Informations du cours
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ID: ${cours.id}'),
                  Text('Transporteur: ${cours.transporteur ?? 'â'}'),
                  Text('Plaque: ${cours.plaqueCamion ?? 'â'}'),
                  Text('Chauffeur: ${cours.chauffeur ?? 'â'}'),
                  Text('Volume: ${cours.volume ?? 'â'} L'),
                ],
              ),
            ),
            // Message informatif pour les cours dÃ©chargÃ©s
            if (cours.statut == StatutCours.decharge)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ce cours a Ã©tÃ© dÃ©chargÃ©. Seul un administrateur peut le modifier ou le supprimer.',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('CDR Detail Widget - DÃ©chargÃ© Status Tests (SimplifiÃ©)', () {
    late CoursDeRoute coursDecharge;

    setUp(() {
      coursDecharge = CoursDeRoute(
        id: 'test-cdr-id',
        fournisseurId: 'fournisseur-1',
        produitId: 'produit-1',
        depotDestinationId: 'depot-1',
        transporteur: 'Transport Express SARL',
        plaqueCamion: 'ABC123',
        chauffeur: 'Jean Dupont',
        volume: 50000.0,
        statut: StatutCours.decharge, // â Statut dÃ©chargÃ©
        note: 'Cours de test dÃ©chargÃ©',
      );
    });

    testWidgets('should render without exceptions for dÃ©chargÃ© status', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(ProviderScope(child: SimpleCdrDetailWidget(cours: coursDecharge)));

      // VÃ©rifier qu'il n'y a pas d'exception de rendu
      expect(tester.takeException(), isNull);

      // Attendre que le widget soit construit
      await tester.pumpAndSettle();

      // VÃ©rifier qu'il n'y a toujours pas d'exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display dÃ©chargÃ© status chip', (WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(child: SimpleCdrDetailWidget(cours: coursDecharge)));

      await tester.pumpAndSettle();

      // Chercher le chip de statut "DÃ©chargÃ©"
      final statutChip = find.text('DÃ©chargÃ©');
      expect(statutChip, findsOneWidget);

      // VÃ©rifier que le texte "Statut:" est prÃ©sent
      expect(find.textContaining('Statut'), findsOneWidget);
    });

    testWidgets('should show informative message for dÃ©chargÃ© status', (WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(child: SimpleCdrDetailWidget(cours: coursDecharge)));

      await tester.pumpAndSettle();

      // VÃ©rifier que le message informatif est affichÃ©
      final infoMessage = find.textContaining('Ce cours a Ã©tÃ© dÃ©chargÃ©');
      expect(infoMessage, findsOneWidget);

      // VÃ©rifier que l'icÃ´ne d'information est prÃ©sente
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('should display course information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(ProviderScope(child: SimpleCdrDetailWidget(cours: coursDecharge)));

      await tester.pumpAndSettle();

      // VÃ©rifier les informations principales
      expect(find.textContaining('Transport Express'), findsOneWidget);
      expect(find.textContaining('ABC123'), findsOneWidget);
      expect(find.textContaining('Jean Dupont'), findsOneWidget);
      expect(find.textContaining('50000'), findsOneWidget);
    });

    testWidgets('should not show informative message for non-dÃ©chargÃ© status', (
      WidgetTester tester,
    ) async {
      final coursTransit = coursDecharge.copyWith(statut: StatutCours.transit);

      await tester.pumpWidget(ProviderScope(child: SimpleCdrDetailWidget(cours: coursTransit)));

      await tester.pumpAndSettle();

      // VÃ©rifier que le message informatif n'est PAS affichÃ©
      final infoMessage = find.textContaining('Ce cours a Ã©tÃ© dÃ©chargÃ©');
      expect(infoMessage, findsNothing);

      // VÃ©rifier que le statut "Transit" est affichÃ©
      expect(find.text('Transit'), findsOneWidget);
    });

    testWidgets('should handle different statuses correctly', (WidgetTester tester) async {
      final statuts = [
        StatutCours.chargement,
        StatutCours.transit,
        StatutCours.frontiere,
        StatutCours.arrive,
        StatutCours.decharge,
      ];

      for (final statut in statuts) {
        final cours = coursDecharge.copyWith(statut: statut);

        await tester.pumpWidget(ProviderScope(child: SimpleCdrDetailWidget(cours: cours)));

        await tester.pumpAndSettle();

        // VÃ©rifier que le statut est affichÃ©
        expect(find.text(statut.label), findsOneWidget);

        // VÃ©rifier que le message informatif n'est affichÃ© que pour dÃ©chargÃ©
        final infoMessage = find.textContaining('Ce cours a Ã©tÃ© dÃ©chargÃ©');
        if (statut == StatutCours.decharge) {
          expect(infoMessage, findsOneWidget);
        } else {
          expect(infoMessage, findsNothing);
        }
      }
    });
  });
}

