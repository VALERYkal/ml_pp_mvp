// ð Module : Auth Tests - Test Runner
// ð§ Auteur : Valery Kalonga
// ð Date : 2025-01-27
// ð§­ Description : Script pour exÃ©cuter tous les tests d'authentification

import 'dart:io';

/// Script pour exÃ©cuter tous les tests d'authentification
///
/// Usage:
/// dart run test/features/auth/run_auth_tests.dart
///
/// Options:
/// --unit: ExÃ©cuter seulement les tests unitaires
/// --widget: ExÃ©cuter seulement les tests widget
/// --integration: ExÃ©cuter seulement les tests d'intÃ©gration
/// --e2e: ExÃ©cuter seulement les tests E2E
/// --security: ExÃ©cuter seulement les tests sÃ©curitÃ©
/// --coverage: GÃ©nÃ©rer un rapport de couverture
/// --verbose: Affichage dÃ©taillÃ©
void main(List<String> args) async {
  print('ð ML_PP MVP - Auth Testing Suite');
  print('================================');

  final bool unitOnly = args.contains('--unit');
  final bool widgetOnly = args.contains('--widget');
  final bool integrationOnly = args.contains('--integration');
  final bool e2eOnly = args.contains('--e2e');
  final bool securityOnly = args.contains('--security');
  final bool coverage = args.contains('--coverage');
  final bool verbose = args.contains('--verbose');

  if (args.contains('--help') || args.isEmpty) {
    _printHelp();
    return;
  }

  final List<String> testCommands = [];

  if (unitOnly || args.isEmpty) {
    testCommands.addAll([
      'flutter test test/features/auth/auth_service_test.dart',
      'flutter test test/features/auth/profil_service_test.dart',
    ]);
  }

  if (widgetOnly || args.isEmpty) {
    testCommands.add('flutter test test/features/auth/screens/login_screen_test.dart');
  }

  if (integrationOnly || args.isEmpty) {
    testCommands.add('flutter test test/features/auth/integration/auth_integration_test.dart');
  }

  if (e2eOnly || args.isEmpty) {
    testCommands.add('flutter test integration_test/features/auth/e2e/auth_e2e_test.dart');
  }

  if (securityOnly || args.isEmpty) {
    testCommands.add('flutter test test/features/auth/security/auth_security_test.dart');
  }

  if (coverage) {
    testCommands.clear();
    testCommands.add('flutter test --coverage test/features/auth/');
  }

  if (testCommands.isEmpty) {
    print('â Aucun test Ã  exÃ©cuter');
    return;
  }

  print('ð Tests Ã  exÃ©cuter:');
  for (final command in testCommands) {
    print('  â¢ $command');
  }
  print('');

  int successCount = 0;
  int totalCount = testCommands.length;

  for (final command in testCommands) {
    print('ð ExÃ©cution: $command');
    print('â' * 50);

    try {
      final result = await Process.run(
        'flutter',
        command.split(' ').skip(1).toList(),
        workingDirectory: Directory.current.path,
      );

      if (result.exitCode == 0) {
        print('â SuccÃ¨s');
        successCount++;
      } else {
        print('â Ãchec');
        print('Sortie d\'erreur:');
        print(result.stderr);
      }

      if (verbose && result.stdout.isNotEmpty) {
        print('Sortie:');
        print(result.stdout);
      }
    } catch (e) {
      print('â Erreur d\'exÃ©cution: $e');
    }

    print('');
  }

  print('ð RÃ©sumÃ©');
  print('=========');
  print('Tests rÃ©ussis: $successCount/$totalCount');

  if (successCount == totalCount) {
    print('ð Tous les tests sont passÃ©s!');
  } else {
    print('â ï¸  Certains tests ont Ã©chouÃ©');
    exit(1);
  }

  if (coverage) {
    print('');
    print('ð Rapport de couverture gÃ©nÃ©rÃ© dans coverage/lcov.info');
    print('Pour visualiser: genhtml coverage/lcov.info -o coverage/html');
  }
}

void _printHelp() {
  print('''
ð ML_PP MVP - Auth Testing Suite
================================

Usage: dart run test/features/auth/run_auth_tests.dart [options]

Options:
  --unit         ExÃ©cuter seulement les tests unitaires
  --widget       ExÃ©cuter seulement les tests widget
  --integration  ExÃ©cuter seulement les tests d'intÃ©gration
  --e2e          ExÃ©cuter seulement les tests E2E
  --security     ExÃ©cuter seulement les tests sÃ©curitÃ©
  --coverage     GÃ©nÃ©rer un rapport de couverture
  --verbose      Affichage dÃ©taillÃ©
  --help         Afficher cette aide

Exemples:
  dart run test/features/auth/run_auth_tests.dart
  dart run test/features/auth/run_auth_tests.dart --unit --coverage
  dart run test/features/auth/run_auth_tests.dart --e2e --verbose

Tests inclus:
  â¢ AuthService unit tests (â¥95% coverage)
  â¢ ProfilService unit tests (â¥95% coverage)
  â¢ LoginScreen widget tests (â¥90% coverage)
  â¢ Auth integration tests (â¥85% coverage)
  â¢ Auth E2E tests (100% coverage)
  â¢ Auth security tests (100% coverage)
''');
}

