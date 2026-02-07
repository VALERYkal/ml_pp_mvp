// Module Fournisseurs — Widget test écran détail (sections, badge ACTIF, pas Supabase).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/fournisseurs/domain/models/fournisseur.dart';
import 'package:ml_pp_mvp/features/fournisseurs/presentation/screens/fournisseur_detail_screen.dart';
import 'package:ml_pp_mvp/features/fournisseurs/providers/fournisseur_providers.dart';

const _testId = 'detail-test-1';
final _testFournisseur = Fournisseur(
  id: _testId,
  nom: 'Test Fournisseur',
  pays: 'France',
  contactPersonne: 'Jean Dupont',
  email: 'jean@test.com',
  telephone: '01 23 45 67 89',
  adresse: '1 rue Example, 75001 Paris',
  noteSupplementaire: 'Note test',
  createdAt: DateTime(2026, 1, 15, 10, 30),
);

void main() {
  group('FournisseurDetailScreen', () {
    testWidgets('affiche sections Informations et Adresse et badge ACTIF',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fournisseurDetailProvider.overrideWith(
              (ref, id) => Future.value(_testFournisseur),
            ),
          ],
          child: const MaterialApp(
            home: FournisseurDetailScreen(fournisseurId: _testId),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Informations'), findsOneWidget);
      expect(find.text('Adresse'), findsOneWidget);
      expect(find.text('ACTIF'), findsOneWidget);
    });
  });
}
