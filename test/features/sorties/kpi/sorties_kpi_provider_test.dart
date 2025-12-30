// 📌 Module : Sorties - Tests Providers KPI (DÉPRÉCIÉ)
// 🧭 Description : Ce fichier est déprécié et remplacé par la nouvelle architecture KPI
//
// ⚠️ DÉPRÉCIÉ : Cette suite de tests est remplacée par :
//   - test/features/kpi/sorties_kpi_provider_test.dart
//     (Provider moderne utilisant sortiesRawTodayProvider + computeKpiSorties)
//   - test/features/kpi/kpi_sorties_compute_test.dart
//     (Tests unitaires de la fonction pure computeKpiSorties)
//
// Raison de la dépréciation :
// - L'ancien test utilisait sortiesKpiRepositoryProvider qui dépend de Supabase.instance
// - La nouvelle architecture sépare l'accès DB (sortiesRawTodayProvider) du calcul (computeKpiSorties)
// - Les nouveaux tests sont 100% isolés (pas de Supabase, pas de RLS, pas d'HTTP)
//
// Ce fichier est conservé pour référence historique mais n'est plus exécuté.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SortiesKpiProvider (deprecated)', () {
    test(
      'Deprecated – replaced by test/features/kpi/sorties_kpi_provider_test.dart',
      () {},
      skip:
          'Deprecated: cette suite est remplacée par test/features/kpi/sorties_kpi_provider_test.dart, '
          'qui utilise sortiesRawTodayProvider + computeKpiSorties sans Supabase.instance. '
          'Voir aussi test/features/kpi/kpi_sorties_compute_test.dart pour les tests unitaires de la fonction pure.',
    );
  });
}
