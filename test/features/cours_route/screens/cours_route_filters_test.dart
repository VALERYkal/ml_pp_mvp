import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_list_screen.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';

import 'cours_route_filters_test.mocks.dart';

@GenerateMocks([CoursDeRouteService])
void main() {
  late MockCoursDeRouteService mockService;

  setUp(() {
    mockService = MockCoursDeRouteService();
  });

  testWidgets('applique le filtre statut TRANSIT', (tester) async {
    final transitItem = CoursDeRoute(
      id: 'id-1',
      fournisseurId: 'f1',
      produitId: 'p1',
      depotDestinationId: 'd1',
      transporteur: 'T',
      statut: StatutCours.transit,
    );

    when(mockService.getByStatut(StatutCours.transit))
        .thenAnswer((_) async => [transitItem]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coursDeRouteServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: CoursRouteListScreen()),
      ),
    );

    // Ouvre le dialogue de filtre
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    // Sélectionne TRANSIT
    await tester.tap(find.byType(DropdownButtonFormField<StatutCours?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TRANSIT').last);
    await tester.pumpAndSettle();

    // Appliquer
    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();

    // Vérifie affichage d'un item (carte) et appel service
    expect(find.textContaining('Cours #'), findsOneWidget);
    verify(mockService.getByStatut(StatutCours.transit)).called(1);
  });

  testWidgets('active le filtre "actifs uniquement"', (tester) async {
    when(mockService.getActifs()).thenAnswer((_) async => []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coursDeRouteServiceProvider.overrideWithValue(mockService),
        ],
        child: const MaterialApp(home: CoursRouteListScreen()),
      ),
    );

    // Ouvre filtre
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    // Switch toggle deux fois
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();

    verify(mockService.getActifs()).called(greaterThanOrEqualTo(1));
  });
}


