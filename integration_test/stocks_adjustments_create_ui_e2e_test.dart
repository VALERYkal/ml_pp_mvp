// integration_test/stocks_adjustments_create_ui_e2e_test.dart

import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/stocks_adjustments/screens/stocks_adjustments_list_screen.dart';
import '../test/integration/_harness/staging_supabase_client.dart';
import '../test/integration/_env/staging_env.dart';

/// Helper pour tracer les étapes avec logs
Future<T> step<T>(
  String name,
  Future<T> Function() action, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  // ignore: avoid_print
  print('[B2.6][STEP] START: $name');
  try {
    final result = await action().timeout(timeout);
    // ignore: avoid_print
    print('[B2.6][STEP] OK: $name');
    return result;
  } catch (e, st) {
    // ignore: avoid_print
    print('[B2.6][STEP] FAIL: $name -> $e');
    // ignore: avoid_print
    print(st);
    rethrow;
  }
}

/// Helper pour pumpAndSettle avec timeout et logs
Future<void> pumpAndSettleSafe(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 10),
  String step = '',
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    // stop condition: no scheduled frames
    if (!tester.binding.hasScheduledFrame) return;
  }
  throw TestFailure('Timeout pumpAndSettleSafe at step: $step');
}

/// Extrait le mouvementId tronqué du premier item (top de la liste)
/// Retourne null si la liste est vide ou si l'extraction échoue
String? extractTopMovementIdPrefix(WidgetTester tester) {
  final linkIcons = find.byIcon(Icons.link);
  if (linkIcons.evaluate().isEmpty) return null;

  // 1) Premier item = premier Icons.link (liste triée desc)
  final firstLink = linkIcons.first;

  // 2) Remonter au Row qui contient (Icon + SizedBox + Text(mouvementId))
  final rowFinder = find.ancestor(
    of: firstLink,
    matching: find.byType(Row),
  );
  if (rowFinder.evaluate().isEmpty) return null;

  // On prend le premier Row trouvé (le plus proche ancestor)
  final rowElement = rowFinder.evaluate().first;
  final rowWidget = rowElement.widget as Row;

  // 3) Dans ce Row, récupérer les Text enfants => le dernier est le mouvementId (après l'icône link)
  final children = rowWidget.children;
  final texts = children.whereType<Text>().toList();
  if (texts.isEmpty) return null;

  final movementText = texts.last.data ?? '';
  if (movementText.isEmpty) return null;

  // mouvementId déjà tronqué à 8 chars dans le widget
  return movementText;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    '[E2E-TEST] B2.6 — Admin crée ajustement via UI → DB → UI refresh (STAGING)',
    (WidgetTester tester) async {
      // 1) Bootstrap STAGING + guard anti-PROD
      final env = await step(
        'StagingEnv.load',
        () => StagingEnv.load(path: 'env/.env.staging'),
      );
      
      // Guard anti-PROD supplémentaire
      final urlLower = env.supabaseUrl.toLowerCase();
      if (urlLower.contains('prod') || 
          urlLower.contains('production') || 
          urlLower.contains('live') ||
          urlLower.contains('monaluxe') && !urlLower.contains('staging')) {
        fail('[DB-TEST] Refusing to run: SUPABASE_URL looks like PROD (${env.supabaseUrl})');
      }

      // 2) Initialiser Supabase Flutter (obligatoire pour _fetchRecentMovements)
      await step(
        'Supabase.initialize',
        () async {
          await Supabase.initialize(
            url: env.supabaseUrl,
            anonKey: env.anonKey,
          ).timeout(const Duration(seconds: 20));
        },
        timeout: const Duration(seconds: 25),
      );

      // 3) Login admin
      // Utiliser testUserEmail/testUserPassword (doit être admin)
      if (env.testUserEmail == null || env.testUserPassword == null) {
        fail('[DB-TEST] TEST_USER_EMAIL and TEST_USER_PASSWORD required for admin test');
      }

      await step(
        'Admin login',
        () async {
          final res = await Supabase.instance.client.auth.signInWithPassword(
            email: env.testUserEmail!,
            password: env.testUserPassword!,
          );

          if (res.session == null) {
            throw Exception('Admin login failed: session is null');
          }
        },
        timeout: const Duration(seconds: 30),
      );

      // 4) Générer tag unique pour la raison
      final tag = DateTime.now().millisecondsSinceEpoch;
      final reason = 'E2E-B2.6-$tag-raison';

      // 5) Lancer l'écran list
      await step(
        'pumpWidget',
        () async {
          await tester.pumpWidget(
            const ProviderScope(
              child: MaterialApp(
                home: StocksAdjustmentsListScreen(),
              ),
            ),
          );
          await pumpAndSettleSafe(tester, step: 'after pumpWidget');
        },
      );

      // 5.5) Capturer le nombre d'items ET le premier mouvementId AVANT création (pagination-safe)
      await pumpAndSettleSafe(
        tester,
        timeout: const Duration(seconds: 5),
        step: 'after initial list load',
      );

      final linkIconsBefore = find.byIcon(Icons.link);
      final countBefore = linkIconsBefore.evaluate().length;
      final topMovementPrefixBefore = extractTopMovementIdPrefix(tester);

      // ignore: avoid_print
      print('[B2.6][BEFORE] count=$countBefore topMovement=$topMovementPrefixBefore');

      // 6) Ouvrir le flow B2.4.4
      // Tap sur le FAB "Créer"
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget, reason: 'FAB should be visible for admin');
      await tester.tap(fabFinder);
      await pumpAndSettleSafe(tester, step: 'after tap FAB');

      // Vérifier que le dialog "Type d'ajustement" est ouvert
      expect(find.text('Type d\'ajustement'), findsOneWidget);
      
      // Tap sur "Ajustement sur Réception"
      final receptionOption = find.text('Ajustement sur Réception');
      expect(receptionOption, findsOneWidget);
      await tester.tap(receptionOption);
      await pumpAndSettleSafe(tester, step: 'after sélection "Ajustement sur Réception"');

      // Attendre le dialog de sélection des mouvements
      // Le dialog peut prendre du temps à charger (FutureBuilder)
      // Il peut afficher "Chargement des réceptions..." puis le dialog de sélection
      await pumpAndSettleSafe(
        tester,
        timeout: const Duration(seconds: 5),
        step: 'after chargement dialog mouvements',
      );

      // Vérifier que le dialog de sélection est ouvert
      // Le dialog peut avoir un titre "Sélectionner une réception" ou être en chargement
      // On attend que le CircularProgressIndicator disparaisse et que les ListTile apparaissent
      final loadingIndicator = find.byType(CircularProgressIndicator);
      if (loadingIndicator.evaluate().isNotEmpty) {
        // Attendre la fin du chargement
        await pumpAndSettleSafe(
          tester,
          timeout: const Duration(seconds: 3),
          step: 'after chargement mouvements',
        );
      }

      // Tap sur le premier ListTile (premier mouvement)
      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isEmpty) {
        // Si aucun mouvement disponible, le test échoue
        fail('[DB-TEST] No recent movements available in STAGING. Seed some receptions first.');
      }
      
      await tester.tap(listTiles.first);
      await pumpAndSettleSafe(tester, step: 'after sélection du mouvement');

      // 7) Vérifier que le sheet est ouvert
      expect(find.text('Créer un ajustement de stock'), findsOneWidget);

      // 8) Remplir le sheet
      // Sélectionner SegmentedButton "Volume"
      // Le SegmentedButton contient des ButtonSegment avec le label "Volume"
      final volumeSegment = find.text('Volume');
      expect(volumeSegment, findsOneWidget);
      await tester.tap(volumeSegment);
      await pumpAndSettleSafe(tester, step: 'after sélection "Volume"');

      // Remplir "Raison"
      // Trouver le TextFormField qui a le label "Raison" dans son InputDecoration
      // On cherche d'abord par type, puis on vérifie le label via l'ancestor
      final allTextFormFields = find.byType(TextFormField);
      expect(allTextFormFields, findsWidgets);
      
      // Le champ "Raison" devrait être le dernier TextFormField (après les champs read-only)
      // On peut aussi chercher par le helperText qui contient "Minimum 10 caractères"
      final reasonHelper = find.textContaining('Minimum 10 caractères');
      expect(reasonHelper, findsOneWidget);
      final reasonField = find.ancestor(
        of: reasonHelper,
        matching: find.byType(TextFormField),
      );
      expect(reasonField, findsOneWidget);
      await tester.enterText(reasonField, reason);
      await pumpAndSettleSafe(tester, step: 'after remplir "Raison"');

      // Remplir "Correction ambiante (L)"
      // Chercher le TextFormField avec le label "Correction ambiante (L)"
      // On peut chercher par le helperText qui contient "Valeur positive ou négative"
      final correctionHelper = find.textContaining('Valeur positive ou négative');
      expect(correctionHelper, findsOneWidget);
      final correctionField = find.ancestor(
        of: correctionHelper,
        matching: find.byType(TextFormField),
      );
      expect(correctionField, findsOneWidget);
      await tester.enterText(correctionField, '1');
      await pumpAndSettleSafe(tester, step: 'after remplir "Correction ambiante"');

      // 9) Enregistrer (robuste: fallback multi-boutons)
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await pumpAndSettleSafe(tester, step: 'after keyboard done');

      final saveText = find.text('Enregistrer');
      expect(saveText, findsOneWidget);

      // Fallback multi-boutons pour robustesse
      final filledButton = find.widgetWithText(FilledButton, 'Enregistrer');
      final elevatedButton = find.widgetWithText(ElevatedButton, 'Enregistrer');
      final textButton = find.widgetWithText(TextButton, 'Enregistrer');

      Finder tappable;
      if (filledButton.evaluate().isNotEmpty) {
        tappable = filledButton;
      } else if (elevatedButton.evaluate().isNotEmpty) {
        tappable = elevatedButton;
      } else if (textButton.evaluate().isNotEmpty) {
        tappable = textButton;
      } else {
        // Fallback ultime : tap sur le texte (pas idéal mais possible)
        tappable = saveText;
      }

      await tester.ensureVisible(tappable);
      await pumpAndSettleSafe(tester, step: 'after ensureVisible save');
      await tester.tap(tappable);
      await pumpAndSettleSafe(
        tester,
        timeout: const Duration(seconds: 8),
        step: 'after tap save',
      );

      // 9.5) Vérifier le snackbar de succès (confirmation que la création a réussi)
      await pumpAndSettleSafe(
        tester,
        timeout: const Duration(seconds: 2),
        step: 'wait for snackbar',
      );
      final snackbarText = find.text('Ajustement créé avec succès');
      expect(
        snackbarText,
        findsOneWidget,
        reason: 'Success snackbar should appear after creating adjustment',
      );

      // 10) Vérifier DB d'abord (pour savoir si l'échec est DB ou UI refresh)
      final dbRows = await step(
        'DB query stocks_adjustments (after create)',
        () async {
          final client = Supabase.instance.client;
          return client
              .from('stocks_adjustments')
              .select('id, reason, created_at')
              .ilike('reason', '%E2E-B2.6-$tag%')
              .order('created_at', ascending: false)
              .limit(1);
        },
      );

      expect(
        dbRows,
        isA<List>(),
        reason: 'DB query should return a list',
      );
      final rows = dbRows as List;
      expect(
        rows.isNotEmpty,
        isTrue,
        reason: 'DB must contain created adjustment',
      );

      // 11) Forcer un refresh manuel de la liste (comme un vrai utilisateur)
      final refreshButton = find.byIcon(Icons.refresh);
      if (refreshButton.evaluate().isNotEmpty) {
        await tester.tap(refreshButton);
        await pumpAndSettleSafe(tester, step: 'after manual refresh');
      } else {
        // Fallback: pull-to-refresh si pas de bouton refresh
        final scrollable = find.byType(Scrollable);
        if (scrollable.evaluate().isNotEmpty) {
          await tester.fling(scrollable.first, const Offset(0, 400), 1000);
          await pumpAndSettleSafe(tester, step: 'after pull-to-refresh');
        }
      }

      // 12) Vérifier refresh UI (liste) avec assertion structurale robuste (pagination-safe)
      await pumpAndSettleSafe(
        tester,
        timeout: const Duration(seconds: 10),
        step: 'after refresh UI',
      );

      final linkIconsAfter = find.byIcon(Icons.link);
      final countAfter = linkIconsAfter.evaluate().length;
      final topMovementPrefixAfter = extractTopMovementIdPrefix(tester);

      // ignore: avoid_print
      print('[B2.6][AFTER] count=$countAfter topMovement=$topMovementPrefixAfter');

      // Assertion pagination-safe : au moins 1 item doit être présent
      expect(
        countAfter,
        greaterThanOrEqualTo(1),
        reason: 'List should contain at least one adjustment after refresh (after=$countAfter, before=$countBefore)',
      );

      // Vérifier que le top item a changé (nouvel item en premier) OU correspond au mouvementId créé
      if (topMovementPrefixBefore != null && topMovementPrefixAfter != null) {
        expect(
          topMovementPrefixAfter,
          isNot(equals(topMovementPrefixBefore)),
          reason: 'Top item should change after creating a new adjustment (pagination-safe)',
        );
      } else {
        // Si liste vide avant => on accepte juste qu'elle soit non vide après
        expect(
          topMovementPrefixAfter,
          isNotNull,
          reason: 'Top movementId should be present after refresh',
        );
      }

      // 13) Vérification finale DB (service role pour audit complet)
      final staging = await step(
        'StagingSupabase.create (final verification)',
        () => StagingSupabase.create(envPath: 'env/.env.staging'),
      );
      final serviceClient = staging.serviceClient;
      expect(serviceClient, isNotNull, reason: 'Service role key required for DB verification');

      final finalDbRows = await step(
        'DB query stocks_adjustments (service role)',
        () => serviceClient!
            .from('stocks_adjustments')
            .select('*')
            .ilike('reason', '%E2E-B2.6-$tag%')
            .order('created_at', ascending: false)
            .limit(1),
      );

      expect(finalDbRows, isA<List>());
      final finalRows = finalDbRows as List;
      expect(
        finalRows.length,
        greaterThanOrEqualTo(1),
        reason: 'At least one adjustment should exist in DB with tag',
      );

      final adjustment = finalRows.first as Map<String, dynamic>;
      expect(adjustment['mouvement_type'], equals('RECEPTION'));
      expect(adjustment['mouvement_id'], isNotNull);
      expect(adjustment['reason'], contains('E2E-B2.6-$tag'));
      expect(adjustment['delta_ambiant'], isNotNull);
      expect(adjustment['delta_15c'], isNotNull);

      // ignore: avoid_print
      print('[E2E-TEST] B2.6 OK — Adjustment created via UI, verified in DB (id=${adjustment['id']})');
    },
  );
}
