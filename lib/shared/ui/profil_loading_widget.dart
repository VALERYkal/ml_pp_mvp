import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profil/providers/profil_provider.dart';
import '../../core/models/profil.dart';

/// Widget helper pour gérer les états de chargement du profil
///
/// Affiche automatiquement :
/// - Un indicateur de chargement pendant la récupération/création du profil
/// - Le contenu une fois le profil disponible
/// - Un message d'erreur en cas de problème
class ProfilLoadingWidget extends ConsumerWidget {
  /// Le widget à afficher une fois le profil chargé
  final Widget Function(Profil profil) builder;

  /// Le widget à afficher pendant le chargement (optionnel)
  final Widget? loadingWidget;

  /// Le widget à afficher en cas d'erreur (optionnel)
  final Widget Function(Object error, StackTrace? stackTrace)? errorWidget;

  /// Le widget à afficher si aucun profil n'est trouvé (optionnel)
  final Widget? noProfilWidget;

  const ProfilLoadingWidget({
    super.key,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
    this.noProfilWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilAsync = ref.watch(currentProfilProvider);

    return profilAsync.when(
      data: (profil) {
        if (profil == null) {
          return noProfilWidget ?? const _DefaultNoProfilWidget();
        }
        return builder(profil);
      },
      loading: () => loadingWidget ?? const _DefaultLoadingWidget(),
      error: (error, stackTrace) {
        if (errorWidget != null) {
          return errorWidget!(error, stackTrace);
        }
        return _DefaultErrorWidget(error: error);
      },
    );
  }
}

/// Widget de chargement par défaut
class _DefaultLoadingWidget extends StatelessWidget {
  const _DefaultLoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Chargement du profil...'),
        ],
      ),
    );
  }
}

/// Widget d'erreur par défaut
class _DefaultErrorWidget extends StatelessWidget {
  final Object error;

  const _DefaultErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Erreur lors du chargement du profil'),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Widget par défaut quand aucun profil n'est trouvé
class _DefaultNoProfilWidget extends StatelessWidget {
  const _DefaultNoProfilWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('Aucun profil trouvé'),
        ],
      ),
    );
  }
}

