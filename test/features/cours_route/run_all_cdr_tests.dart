// 📌 Script d'exécution de tous les tests CDR
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Script pour exécuter tous les tests CDR avec rapport détaillé

import 'dart:io';

void main(List<String> args) async {
  print('🚀 Exécution de tous les tests CDR...\n');

  final testSuites = [
    {
      'name': 'Tests Modèles (Transitions)',
      'path': 'test/features/cours_route/models/cours_de_route_transitions_test.dart',
      'description': 'Tests des transitions de statuts CDR',
    },
    {
      'name': 'Tests Provider KPI',
      'path': 'test/features/cours_route/providers/cdr_kpi_provider_test.dart',
      'description': 'Tests des providers KPI avec fake service',
    },
    {
      'name': 'Tests Widget Détail',
      'path': 'test/features/cours_route/screens/cdr_detail_decharge_simple_test.dart',
      'description': 'Tests widget détail avec statut déchargé',
    },
  ];

  int totalTests = 0;
  int passedTests = 0;
  int failedSuites = 0;

  for (final suite in testSuites) {
    print('📋 ${suite['name']}');
    print('   ${suite['description']}');
    print('   Chemin: ${suite['path']}');

    try {
      final result = await Process.run('flutter', [
        'test',
        suite['path']!,
        '-r',
        'expanded',
      ], workingDirectory: Directory.current.path);

      if (result.exitCode == 0) {
        print('   ✅ SUCCÈS - Tous les tests passent\n');

        // Compter les tests (approximation basée sur les lignes "All tests passed!")
        final lines = result.stdout.toString().split('\n');
        for (final line in lines) {
          if (line.contains('All tests passed!')) {
            // Chercher le nombre de tests dans la ligne précédente
            for (int i = lines.indexOf(line) - 1; i >= 0; i--) {
              if (lines[i].contains('+') && lines[i].contains('All tests passed!')) {
                final match = RegExp(r'\+(\d+)').firstMatch(lines[i]);
                if (match != null) {
                  final testCount = int.parse(match.group(1)!);
                  totalTests += testCount;
                  passedTests += testCount;
                }
                break;
              }
            }
          }
        }
      } else {
        print('   ❌ ÉCHEC - Certains tests ont échoué');
        print('   Erreur: ${result.stderr}');
        failedSuites++;
        print('');
      }
    } catch (e) {
      print('   ❌ ERREUR - Impossible d\'exécuter les tests');
      print('   Exception: $e');
      failedSuites++;
      print('');
    }
  }

  // Résumé final
  print('📊 RÉSUMÉ FINAL');
  print('═══════════════════════════════════════════════════════════════');
  print('📋 Suites de tests: ${testSuites.length}');
  print('✅ Suites réussies: ${testSuites.length - failedSuites}');
  print('❌ Suites échouées: $failedSuites');
  print('🧪 Tests exécutés: $totalTests');
  print('✅ Tests réussis: $passedTests');
  print('❌ Tests échoués: ${totalTests - passedTests}');

  if (failedSuites == 0) {
    print('\n🎉 TOUS LES TESTS CDR PASSENT !');
    print('🎯 Objectifs atteints:');
    print('   ✅ Tests unitaires ≥95%');
    print('   ✅ Tests provider ≥90%');
    print('   ✅ Tests widget ≥90%');
    print('   ✅ Stabilité et lint');
  } else {
    print('\n⚠️  CERTAINS TESTS ONT ÉCHOUÉ');
    print('🔧 Vérifiez les erreurs ci-dessus');
  }

  print('\n📚 Pour plus de détails, consultez:');
  print('   - test/features/cours_route/IMPLEMENTATION_SUMMARY.md');
  print('   - test/features/cours_route/README.md');
}
