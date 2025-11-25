/* ===========================================================
   ML_PP MVP  Modern Reception Integration Example
   Rôle: Exemple d'intégration du module réception moderne
   avec navigation, validation et gestion d'état
   =========================================================== */
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/modern_reception_form_screen.dart';
import '../screens/modern_reception_list_screen.dart';
import '../providers/modern_reception_form_provider.dart';
import '../services/modern_reception_validation_service.dart';
import '../widgets/modern_reception_components.dart';

/// Exemple d'intégration complète du module réception moderne
class ModernReceptionIntegrationExample extends ConsumerWidget {
  const ModernReceptionIntegrationExample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formState = ref.watch(modernReceptionFormProvider);
    final validation = ref.watch(modernReceptionFormValidationProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Module Réception Moderne',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 24),
            _buildNavigationButtons(theme, context),
            const SizedBox(height: 24),
            _buildFormState(theme, formState),
            const SizedBox(height: 24),
            _buildValidationState(theme, validation),
            const SizedBox(height: 24),
            _buildComponentExamples(theme),
            const SizedBox(height: 24),
            _buildIntegrationGuide(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.rocket_launch_rounded,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Module Réception Moderne',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Interface Material 3 avec animations fluides et validation avancée',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              'Version 1.0 - Prêt pour la production',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(ThemeData theme, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Navigation',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildNavigationCard(
                theme,
                'Formulaire Moderne',
                'Interface Material 3 avec animations',
                Icons.edit_rounded,
                Colors.blue,
                () => context.go('/receptions/new'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildNavigationCard(
                theme,
                'Liste Moderne',
                'Recherche et filtres avancés',
                Icons.list_rounded,
                Colors.green,
                () => context.go('/receptions'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationCard(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormState(ThemeData theme, ModernReceptionFormState formState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'État du Formulaire',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              _buildStateItem(
                theme,
                'Étape actuelle',
                '${formState.currentStep + 1}/3',
              ),
              _buildStateItem(
                theme,
                'Type propriétaire',
                formState.ownerType ?? 'Non défini',
              ),
              _buildStateItem(
                theme,
                'Produit sélectionné',
                formState.produitId ?? 'Non sélectionné',
              ),
              _buildStateItem(
                theme,
                'Citerne sélectionnée',
                formState.citerneId ?? 'Non sélectionnée',
              ),
              _buildStateItem(
                theme,
                'Volume brut',
                '${formState.volumeBrut.toStringAsFixed(0)} L',
              ),
              _buildStateItem(
                theme,
                'Volume 15°C',
                '${formState.volume15c.toStringAsFixed(0)} L',
              ),
              _buildStateItem(
                theme,
                'Formulaire valide',
                formState.isFormValid ? 'Oui' : 'Non',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStateItem(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValidationState(ThemeData theme, ValidationResult validation) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'État de Validation',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: validation.isValid
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: validation.isValid
                  ? Colors.green.withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    validation.isValid
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    color: validation.isValid ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    validation.isValid
                        ? 'Formulaire valide'
                        : 'Erreurs détectées',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: validation.isValid ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              if (validation.errors.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Erreurs:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ...validation.errors.map(
                  (error) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Text(
                      ' ${error.message}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
              if (validation.warnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Avertissements:',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                ...validation.warnings.map(
                  (warning) => Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Text(
                      ' ${warning.message}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComponentExamples(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Composants Modernes',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildComponentCard(
                theme,
                'Sélecteur de Produit',
                ModernProductSelector(
                  selectedProductId: null,
                  onProductSelected: (id) {},
                  products: [
                    {'id': '1', 'libelle': 'ESS', 'code': 'ESS'},
                    {'id': '2', 'libelle': 'AGO', 'code': 'AGO'},
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildComponentCard(
                theme,
                'Sélecteur de Citerne',
                ModernTankSelector(
                  selectedTankId: null,
                  onTankSelected: (id) {},
                  tanks: [
                    {
                      'id': '1',
                      'libelle': 'Citerne A',
                      'stock_15c': 5000,
                      'capacity': 10000,
                    },
                    {
                      'id': '2',
                      'libelle': 'Citerne B',
                      'stock_15c': 8000,
                      'capacity': 10000,
                    },
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildComponentCard(
          theme,
          'Calculatrice de Volume',
          ModernVolumeCalculator(
            indexAvant: 1000,
            indexApres: 2000,
            temperature: 15.0,
            densite: 0.83,
            isVisible: true,
          ),
        ),
      ],
    );
  }

  Widget _buildComponentCard(ThemeData theme, String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildIntegrationGuide(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Guide d\'Intégration',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIntegrationStep(
                theme,
                '1',
                'Importer les composants',
                'import \'package:ml_pp_mvp/features/receptions/screens/modern_reception_form_screen.dart\';',
              ),
              _buildIntegrationStep(
                theme,
                '2',
                'Configurer le provider',
                'final formProvider = ref.watch(modernReceptionFormProvider);',
              ),
              _buildIntegrationStep(
                theme,
                '3',
                'Utiliser les composants',
                'ModernReceptionFormScreen(coursDeRouteId: routeId)',
              ),
              _buildIntegrationStep(
                theme,
                '4',
                'Gérer la validation',
                'final validation = ref.watch(modernReceptionFormValidationProvider);',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntegrationStep(
    ThemeData theme,
    String step,
    String title,
    String code,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                step,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    code,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

