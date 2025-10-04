import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';

/// Header moderne pour le dashboard avec salutation personnalisée
class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilAsync = ref.watch(profilProvider);
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Salutation personnalisée avec design moderne
          profilAsync.when(
            data: (profil) => _buildWelcomeSection(theme, profil?.nomComplet),
            loading: () => _buildWelcomeSection(theme, null),
            error: (_, __) => _buildWelcomeSection(theme, null),
          ),
          const SizedBox(height: 16),
          // Informations contextuelles avec design moderne
          _buildContextInfo(theme),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(ThemeData theme, String? nomComplet) {
    return Row(
      children: [
        // Icône de bienvenue avec animation
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.15),
                theme.colorScheme.primary.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 1),
          ),
          child: Icon(Icons.waving_hand_outlined, color: theme.colorScheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bienvenue ${_getFirstName(nomComplet)}',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContextInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            _getCurrentDate(),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
          const Spacer(),
          Icon(Icons.access_time_outlined, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            _getCurrentTime(),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final weekdays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    return '${weekdays[now.weekday - 1]} ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getFirstName(String? nomComplet) {
    if (nomComplet == null || nomComplet.isEmpty) {
      return 'Directeur';
    }
    final parts = nomComplet.split(' ');
    return parts.isNotEmpty ? parts.first : 'Directeur';
  }
}
