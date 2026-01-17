// 📌 Module : Réceptions - Tests Providers KPI (DÉPRÉCIÉ)
// 🧭 Description : Ce fichier est déprécié et remplacé par la nouvelle architecture KPI
//
// ⚠️ DÉPRÉCIÉ : Cette suite de tests est remplacée par :
//   - test/features/kpi/receptions_kpi_provider_test.dart
//     (Provider moderne utilisant receptionsRawTodayProvider + computeKpiReceptions)
//   - test/features/kpi/kpi_receptions_compute_test.dart
//     (Tests unitaires de la fonction pure computeKpiReceptions)
//
// Raison de la dépréciation :
// - L'ancien test utilisait receptionsKpiRepositoryProvider qui dépend de Supabase.instance
// - La nouvelle architecture sépare l'accès DB (receptionsRawTodayProvider) du calcul (computeKpiReceptions)
// - Les nouveaux tests sont 100% isolés (pas de Supabase, pas de RLS, pas d'HTTP)
//
// Ce fichier est conservé pour référence historique mais n'est plus exécuté.

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceptionsKpiProvider (deprecated)', () {
    test(
      'Deprecated – replaced by test/features/kpi/receptions_kpi_provider_test.dart',
      () {},
      skip: 'Deprecated: remplacé par test/features/kpi/receptions_kpi_provider_test.dart (provider moderne) et test/features/kpi/kpi_receptions_compute_test.dart (fonction pure). Ancienne suite dépendait de Supabase.instance.',
    );
  });
}
