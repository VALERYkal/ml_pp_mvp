// ð Module : KPI Unified Test Suite
// ð§ Auteur : Valery Kalonga
// ð Date : 2025-09-17
// ð§­ Description : Suite de tests complÃ¨te pour le systÃ¨me KPI unifiÃ©

import 'package:flutter_test/flutter_test.dart';

// Import de tous les tests
import 'features/kpi/models/kpi_models_test.dart' as kpi_models_test;
import 'features/kpi/providers/kpi_provider_test.dart' as kpi_provider_test;
import 'features/dashboard/widgets/role_dashboard_test.dart' as role_dashboard_test;
import 'features/dashboard/screens/dashboard_screens_smoke_test.dart' as dashboard_screens_test;

void main() {
  group('ð KPI Unified System Test Suite', () {
    group('ð KPI Models Tests', () {
      kpi_models_test.main();
    });

    group('ð§ KPI Provider Tests', () {
      kpi_provider_test.main();
    });

    group('ð¨ Role Dashboard Tests', () {
      role_dashboard_test.main();
    });

    group('ð± Dashboard Screens Smoke Tests', () {
      dashboard_screens_test.main();
    });
  });
}

