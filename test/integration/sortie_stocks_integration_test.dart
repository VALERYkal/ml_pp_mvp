import 'package:flutter_test/flutter_test.dart';

/// Test d'intégration Sorties -> Stocks journaliers.
///
/// 🔎 Objectif (documenté dans le PRD et les tests SQL manuels) :
/// - insérer une sortie via l'API Supabase / SortieService
/// - vérifier que :
///   - la table `stocks_journaliers` est débitée correctement
///   - la séparation MONALUXE / PARTENAIRE est respectée
///   - une entrée est créée dans `log_actions` avec action = 'SORTIE_CREEE'
///
/// ⚠ Pour l'instant, ce test est un **placeholder** :
/// - il ne s'exécute pas encore contre une instance Supabase de test
/// - il est marqué `skip` pour ne pas casser la suite tant que l'environnement
///   d'intégration (URL, anon key, jeu de données) n'est pas figé.
///
/// 👉 Référence : docs/db/sorties_trigger_tests.md
///   - contient déjà 12 scénarios SQL manuels (OK/ERREUR)
///   - ce test devra, à terme, automatiser au moins 1 scénario OK + 1 scénario ERREUR.
void main() {
  group('Sorties -> Stocks journaliers (intégration SQL)', () {
    test(
      'placeholder – sera implémenté quand l\'environnement Supabase de test sera figé',
      () async {
        // TODO(ml_pp_mvp): implémenter ce test quand :
        // - une instance Supabase de test dédiée est disponible
        // - les migrations des triggers sont figées
        // - un jeu de données stable (citernes, produits, clients) est en place.
        //
        // Exemple de plan d'implémentation :
        // 1. Insérer une sortie MONALUXE sur une citerne donnée
        // 2. Lire la ligne correspondante dans stocks_journaliers
        // 3. Vérifier le débit du stock (volume_ambiant et 15°C)
        // 4. Vérifier l'entrée correspondante dans log_actions.
      },
      skip:
          'Test d\'intégration non encore branché sur une instance Supabase de test dédiée.',
    );
  });
}
