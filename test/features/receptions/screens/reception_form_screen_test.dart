// 📌 Module : Réceptions - Tests Widget Formulaire
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-11-30
// 🧭 Description : Tests widget pour le formulaire de réception (happy path)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase/supabase.dart';

import 'package:ml_pp_mvp/features/receptions/screens/reception_form_screen.dart';
import 'package:ml_pp_mvp/features/receptions/providers/reception_providers.dart'
    as RP;
import 'package:ml_pp_mvp/features/receptions/data/reception_service.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/core/models/profil.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/shared/providers/session_provider.dart';
import 'package:ml_pp_mvp/features/receptions/data/citerne_info_provider.dart';
import 'package:ml_pp_mvp/features/receptions/data/partenaires_provider.dart';

void main() {
  // Nécessaire pour les tests widget
  TestWidgetsFlutterBinding.ensureInitialized();

  // PAS de Supabase.initialize ici - on utilise uniquement des fake services

  testWidgets('happy path: enregistrement reception affiche snackbar success', (
    tester,
  ) async {
    // Arrange - Créer les fakes nécessaires
    final fakeRefRepo = refs.ReferentielsRepo(
      SupabaseClient('http://localhost', 'anon'),
    );
    final fakeService = _FakeReceptionService(fakeRefRepo);

    // Overrides similaires au test E2E pour un setup cohérent
    final overrides = <Override>[
      // Service de réception (il y a deux providers : un dans reception_providers.dart et un dans reception_service.dart)
      // On override les deux car reception_form_screen.dart utilise celui de reception_service.dart
      RP.receptionServiceProvider.overrideWith((ref) => fakeService),
      receptionServiceProvider.overrideWith((ref) => fakeService),

      // Référentiels
      refs.referentielsRepoProvider.overrideWith((ref) => fakeRefRepo),
      refs.produitsRefProvider.overrideWith(
        (ref) => Future.value([
          refs.ProduitRef(id: 'prod-1', code: 'ESS', nom: 'Essence'),
        ]),
      ),
      refs.citernesActivesProvider.overrideWith(
        (ref) => Future.value([
          refs.CiterneRef(
            id: 'cit-1',
            nom: 'Citerne A',
            produitId: 'prod-1',
            statut: 'active',
            capaciteTotale: 50000.0,
            capaciteSecurite: 5000.0,
          ),
        ]),
      ),

      // Partenaires
      RP.partenairesListProvider.overrideWith((ref) async => const []),
      partenairesProvider.overrideWith(
        (ref) => Future.value([
          const PartenaireItem(id: 'partenaire-1', nom: 'Partenaire Test'),
        ]),
      ),

      // Profil utilisateur (gerant pour avoir les permissions)
      currentProfilProvider.overrideWith(
        () => _FakeProfilNotifier(
          Profil(
            id: 'user-test',
            email: 'test@example.com',
            role: UserRole.gerant,
            depotId: 'test-depot',
          ),
        ),
      ),

      // Auth state
      appAuthStateProvider.overrideWith(
        (ref) => Stream.value(
          AppAuthState(session: null, authStream: const Stream.empty()),
        ),
      ),

      // Citerne info provider (pour éviter les appels Supabase)
      citerneQuickInfoProvider.overrideWith(
        (ref, args) => Future.value(
          CiterneQuickInfo(
            id: args.citerneId,
            nom: 'Citerne A',
            capaciteTotale: 50000.0,
            capaciteSecurite: 5000.0,
            stockEstime: 10000.0,
          ),
        ),
      ),
    ];

    // Act 1 : Pomper le widget (sans coursDeRouteId pour éviter le chargement depuis Supabase)
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(home: ReceptionFormScreen()),
      ),
    );

    // Attendre le chargement initial
    await tester.pumpAndSettle();

    // Vérifier que le formulaire s'affiche
    expect(find.text('Nouvelle Réception'), findsOneWidget);

    // Act 2 : Attendre que les providers soient chargés
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Act 3 : Changer en mode PARTENAIRE pour éviter d'avoir besoin d'un CDR
    final partenaireChip = find.text('PARTENAIRE');
    expect(partenaireChip, findsOneWidget);
    await tester.tap(partenaireChip);
    await tester.pumpAndSettle();

    // En mode PARTENAIRE, un champ PartenaireAutocomplete apparaît
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Sélectionner un partenaire
    final partenaireField = find.text('Partenaire');
    expect(partenaireField, findsOneWidget);

    final partenaireTextField = find.ancestor(
      of: partenaireField.first,
      matching: find.byType(TextField),
    );
    expect(partenaireTextField, findsOneWidget);

    await tester.enterText(partenaireTextField.first, 'Partenaire Test');
    await tester.pumpAndSettle();

    // Sélectionner le premier résultat de l'autocomplete
    // (Stratégie identique au test E2E qui fonctionne)
    // L'autocomplete affiche les résultats dans une ListView avec des ListTile
    // Chaque ListTile a un onTap qui appelle onSelect(o) qui appelle onSelected(p)
    // On cherche d'abord les ListTile qui sont les résultats de l'autocomplete
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Chercher les ListTile qui contiennent "Partenaire Test"
    // L'autocomplete affiche les résultats dans une Material avec une ListView
    final listTiles = find.byType(ListTile);
    if (listTiles.evaluate().isNotEmpty) {
      // Taper sur le premier ListTile qui devrait être le résultat de l'autocomplete
      // Le ListTile a un onTap qui appelle onSelect(o) qui appelle onSelected(p)
      await tester.tap(listTiles.first);
      await tester.pumpAndSettle();
    } else {
      // Fallback : chercher le texte "Partenaire Test" dans un ListTile
      final listTile = find.descendant(
        of: find.byType(ListTile),
        matching: find.text('Partenaire Test'),
      );
      if (listTile.evaluate().isNotEmpty) {
        await tester.tap(listTile.first);
        await tester.pumpAndSettle();
      } else {
        // Dernier fallback : chercher directement le texte "Partenaire Test"
        // et trouver son ancêtre ListTile
        final text = find.text('Partenaire Test');
        if (text.evaluate().isNotEmpty) {
          final listTileAncestor = find.ancestor(
            of: text.first,
            matching: find.byType(ListTile),
          );
          if (listTileAncestor.evaluate().isNotEmpty) {
            await tester.tap(listTileAncestor.first);
            await tester.pumpAndSettle();
          } else {
            // Si on ne trouve pas de ListTile, taper directement sur le texte
            await tester.tap(text.first);
            await tester.pumpAndSettle();
          }
        }
      }
    }

    // Attendre que le callback onSelected soit appelé et que setState mette à jour partenaireId
    // Le callback fait : setState(() => partenaireId = p.id)
    // Il faut attendre que le setState soit appliqué et que le widget soit reconstruit
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Act 4 : Sélectionner le produit
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final produitChip = find.textContaining('ESS');
    expect(produitChip, findsOneWidget);

    final chip = find.ancestor(
      of: produitChip.first,
      matching: find.byType(ChoiceChip),
    );
    expect(chip, findsOneWidget);
    await tester.tap(chip.first);
    await tester.pumpAndSettle();

    // Act 5 : Sélectionner la citerne
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final citerneRadio = find.byType(RadioListTile<String>);
    expect(citerneRadio, findsOneWidget);
    await tester.tap(citerneRadio.first);
    await tester.pumpAndSettle();

    // Act 6 : Scroller si nécessaire pour voir les champs de mesures
    // (Stratégie identique au test E2E)
    var textFields = find.byType(TextField);
    var textFieldCount = textFields.evaluate().length;

    if (textFieldCount < 4) {
      // Scroller vers le bas pour voir la Card "Mesures & Calculs"
      final listView = find.byType(ListView);
      if (listView.evaluate().isNotEmpty) {
        await tester.drag(listView.first, const Offset(0, -400));
        await tester.pumpAndSettle();
        // Re-vérifier après le scroll
        textFields = find.byType(TextField);
        textFieldCount = textFields.evaluate().length;
      }
    }

    // Act 7 : Remplir les champs de mesures
    // On utilise la même stratégie que le test E2E : trouver les TextField et les remplir par index
    // Ordre attendu : Index avant (0), Index après (1), Température (2), Densité (3)
    if (textFieldCount >= 4) {
      // Index avant
      await tester.enterText(textFields.at(0), '0');
      await tester.pump();

      // Index après
      await tester.enterText(textFields.at(1), '1000');
      await tester.pump();

      // Température
      await tester.enterText(textFields.at(2), '25');
      await tester.pump();

      // Densité
      await tester.enterText(textFields.at(3), '0.85');
      await tester.pumpAndSettle();
    } else {
      // Si on n'a pas trouvé assez de TextField, essayer de trouver les champs par leur label
      final indexAvant = find.text('Index avant *');
      if (indexAvant.evaluate().isNotEmpty) {
        final field = find.ancestor(
          of: indexAvant.first,
          matching: find.byType(TextField),
        );
        if (field.evaluate().isNotEmpty) {
          await tester.enterText(field.first, '0');
          await tester.pump();
        }
      }

      final indexApres = find.text('Index après *');
      if (indexApres.evaluate().isNotEmpty) {
        final field = find.ancestor(
          of: indexApres.first,
          matching: find.byType(TextField),
        );
        if (field.evaluate().isNotEmpty) {
          await tester.enterText(field.first, '1000');
          await tester.pump();
        }
      }

      final temperature = find.text('Température (°C) *');
      if (temperature.evaluate().isNotEmpty) {
        final field = find.ancestor(
          of: temperature.first,
          matching: find.byType(TextField),
        );
        if (field.evaluate().isNotEmpty) {
          await tester.enterText(field.first, '25');
          await tester.pump();
        }
      }

      final densite = find.text('Densité @15°C *');
      if (densite.evaluate().isNotEmpty) {
        final field = find.ancestor(
          of: densite.first,
          matching: find.byType(TextField),
        );
        if (field.evaluate().isNotEmpty) {
          await tester.enterText(field.first, '0.85');
          await tester.pumpAndSettle();
        }
      }
    }

    // Act 8 : Scroller vers le bas pour voir le bouton de soumission
    final listView = find.byType(ListView);
    if (listView.evaluate().isNotEmpty) {
      await tester.drag(listView.first, const Offset(0, -500));
      await tester.pumpAndSettle();
    }

    // Act 9 : Vérifier que le bouton de soumission est présent et actif
    final submitButton = find.text('Enregistrer la réception');
    expect(submitButton, findsOneWidget);

    // Attendre un peu pour s'assurer que tous les champs sont bien remplis et que l'état est à jour
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Vérifier que le bouton est actif (pas désactivé)
    // On cherche un bouton Material générique (ButtonStyleButton) autour du texte
    final submitButtonWidget = find.ancestor(
      of: submitButton.first,
      matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
    );
    expect(
      submitButtonWidget,
      findsOneWidget,
      reason:
          'Un bouton Material (ButtonStyleButton) doit entourer le texte "Enregistrer la réception"',
    );

    final button = tester.widget<ButtonStyleButton>(submitButtonWidget.first);

    // Le bouton est actif si onPressed n'est pas null
    if (button.onPressed == null) {
      // Le bouton est désactivé, ce qui signifie que _canSubmit retourne false
      // Vérifier quels champs manquent en cherchant des messages d'erreur
      final errorMessages = [
        'Sélectionnez un produit',
        'Sélectionnez une citerne',
        'Choisissez un cours',
        'Choisissez un partenaire',
        'Indices incohérents',
        'température',
        'densité',
      ];

      for (final errorMsg in errorMessages) {
        final error = find.textContaining(errorMsg, findRichText: true);
        if (error.evaluate().isNotEmpty) {
          fail(
            'Le bouton est désactivé. Validation UI échouée: "$errorMsg" trouvé. Le formulaire n\'est pas dans un état valide pour la soumission.',
          );
        }
      }

      // Debug : vérifier l'état des champs
      debugPrint('⚠️  DEBUG: Le bouton est désactivé. État des champs:');
      debugPrint(
        '   - Produit sélectionné: ${find.textContaining("ESS").evaluate().isNotEmpty}',
      );
      debugPrint(
        '   - Citerne sélectionnée: ${find.byType(RadioListTile<String>).evaluate().isNotEmpty}',
      );
      debugPrint(
        '   - Partenaire sélectionné: ${find.text("Partenaire Test").evaluate().isNotEmpty}',
      );
      debugPrint('   - TextField remplis: ${textFieldCount}');

      fail(
        'Le bouton de soumission est désactivé (_canSubmit retourne false). '
        'Vérifiez que tous les champs requis sont remplis: produit, citerne, partenaire (en mode PARTENAIRE), indices, température, densité.',
      );
    }

    // Le bouton est actif, on peut continuer
    debugPrint('✅ DEBUG: Le bouton est actif, prêt à soumettre');

    // Act 10 : Soumettre le formulaire
    debugPrint('✅ DEBUG: Tapping sur le bouton de soumission');
    await tester.tap(submitButton);

    // Attendre que la soumission soit traitée (createValidated est async)
    // On utilise pumpAndSettle pour attendre que toutes les animations et futures se terminent
    await tester.pumpAndSettle();

    // Vérifier immédiatement s'il y a un SnackBar d'erreur affiché
    // (les validations dans _submitReception affichent un SnackBar avant de return)
    final errorMessages = [
      'Sélectionnez un produit',
      'Sélectionnez une citerne',
      'Choisissez un cours',
      'Choisissez un partenaire',
      'Indices incohérents',
      'température',
      'densité',
    ];

    for (final errorMsg in errorMessages) {
      // Chercher dans les SnackBar (les validations dans _submitReception utilisent SnackBar)
      final snackBarError = find.textContaining(errorMsg, findRichText: true);
      if (snackBarError.evaluate().isNotEmpty) {
        fail(
          'Validation UI échouée dans _submitReception: "$errorMsg" trouvé dans un SnackBar. '
          'Le formulaire n\'est pas dans un état valide pour la soumission. '
          'Si c\'est "Choisissez un partenaire", le callback onSelected du PartenaireAutocomplete n\'a probablement pas été appelé correctement.',
        );
      }
    }

    // Assert 1 : Vérifier que le service a été appelé
    // Si le service n'est pas appelé, c'est qu'une validation UI a échoué dans _submitReception
    if (!fakeService.wasCalled) {
      // Si aucune erreur n'est affichée, le problème vient probablement d'une validation silencieuse
      // Le plus probable est que partenaireId est null en mode PARTENAIRE
      debugPrint(
        '⚠️  DEBUG: Le service n\'a pas été appelé, mais aucune erreur visible. ',
      );
      debugPrint('   - Le bouton était actif (_canSubmit = true)');
      debugPrint(
        '   - Mais _submitReception a probablement échoué sur une validation',
      );
      debugPrint(
        '   - Vérifiez que partenaireId est bien défini en mode PARTENAIRE',
      );

      fail(
        'Le service createValidated n\'a pas été appelé. Une validation UI dans _submitReception a probablement échoué silencieusement. '
        'Le bouton était actif, donc _canSubmit retournait true, mais _submitReception a probablement échoué sur la validation du partenaire en mode PARTENAIRE. '
        'Vérifiez que le callback onSelected du PartenaireAutocomplete est bien appelé et que partenaireId est défini.',
      );
    }

    debugPrint('✅ DEBUG: Le service createValidated a été appelé avec succès');

    // Assert : Vérifier que le Snackbar de succès est affiché
    // Le Snackbar est affiché via ScaffoldMessenger après que createValidated se termine
    // On cherche d'abord par type de widget, puis par texte
    final snackbarByType = find.byType(SnackBar);
    final snackbarByText = find.textContaining('Réception enregistrée');

    // Debug : vérifier ce qui est trouvé
    debugPrint(
      '🔍 DEBUG: SnackBar trouvés par type: ${snackbarByType.evaluate().length}',
    );
    debugPrint(
      '🔍 DEBUG: Widgets avec texte "Réception enregistrée": ${snackbarByText.evaluate().length}',
    );

    // Si on trouve un SnackBar, vérifier son contenu
    if (snackbarByType.evaluate().isNotEmpty) {
      final snackBarWidget = tester.widget<SnackBar>(snackbarByType.first);
      debugPrint('🔍 DEBUG: Contenu du SnackBar: ${snackBarWidget.content}');
    }

    // On accepte soit le texte direct, soit le SnackBar avec ce texte
    final hasSnackbarByText = snackbarByText.evaluate().isNotEmpty;
    final hasSnackbarByType = snackbarByType.evaluate().isNotEmpty;

    expect(
      hasSnackbarByText || hasSnackbarByType,
      isTrue,
      reason:
          'Le Snackbar de succès "Réception enregistrée" doit être affiché après la soumission. '
          'SnackBar trouvés par type: ${snackbarByType.evaluate().length}, '
          'Widgets avec texte: ${snackbarByText.evaluate().length}',
    );
  });
}

/// Fake service pour les tests
class _FakeReceptionService extends ReceptionService {
  bool _wasCalled = false;
  bool get wasCalled => _wasCalled;

  _FakeReceptionService(refs.ReferentielsRepo refRepo)
    : super.withClient(
        SupabaseClient('http://localhost', 'anon'),
        refRepo: refRepo,
      );

  @override
  Future<String> createValidated({
    String? coursDeRouteId,
    required String citerneId,
    required String produitId,
    required double indexAvant,
    required double indexApres,
    double? temperatureCAmb,
    double? densiteA15,
    double? volumeCorrige15C,
    String proprietaireType = 'MONALUXE',
    String? partenaireId,
    DateTime? dateReception,
    String? note,
  }) async {
    _wasCalled = true;
    debugPrint(
      '✅ _FakeReceptionService.createValidated appelé avec: citerneId=$citerneId, produitId=$produitId, indexAvant=$indexAvant, indexApres=$indexApres',
    );
    // Retourner un ID factice
    return 'rec-1';
  }
}

/// Fake profil notifier pour les tests
class _FakeProfilNotifier extends CurrentProfilNotifier {
  final Profil? _profil;

  _FakeProfilNotifier(this._profil);

  @override
  Future<Profil?> build() async => _profil;
}
